const { randomUUID } = require('node:crypto');
const { initializeApp } = require('firebase-admin/app');
const { FieldValue, Timestamp, getFirestore } = require('firebase-admin/firestore');
const { defineSecret } = require('firebase-functions/params');
const { HttpsError, onCall, onRequest } = require('firebase-functions/v2/https');
const { onSchedule } = require('firebase-functions/v2/scheduler');
const Stripe = require('stripe');

initializeApp();
const db = getFirestore();
const stripeSecret = defineSecret('STRIPE_SECRET_KEY');
const webhookSecret = defineSecret('STRIPE_WEBHOOK_SECRET');
const currency = 'usd';

function stripeClient() {
  return new Stripe(stripeSecret.value());
}

function requireUser(request) {
  if (!request.auth) throw new HttpsError('unauthenticated', 'Inicia sesión para continuar.');
  return request.auth.uid;
}

function cleanShipping(value) {
  const fullName = String(value?.fullName || '').trim();
  const address = String(value?.address || '').trim();
  if (fullName.length < 3 || fullName.length > 100 || address.length < 8 || address.length > 300) {
    throw new HttpsError('invalid-argument', 'Completa un nombre y una dirección válidos.');
  }
  return { fullName, address };
}

function cleanItems(value) {
  if (!Array.isArray(value) || value.length === 0 || value.length > 40) {
    throw new HttpsError('invalid-argument', 'El carrito no es válido.');
  }
  const items = value.map((item) => ({
    productId: String(item?.productId || ''),
    quantity: Number(item?.quantity),
    variants: item?.variants && typeof item.variants === 'object' && !Array.isArray(item.variants)
      ? Object.fromEntries(Object.entries(item.variants).map(([key, variant]) => [String(key), String(variant)]))
      : {},
  }));
  if (items.some((item) => !/^[A-Za-z0-9_-]{1,128}$/.test(item.productId) || !Number.isInteger(item.quantity) || item.quantity < 1 || item.quantity > 20 ||
    Object.entries(item.variants).some(([key, variant]) => !key || !variant || key.length > 40 || variant.length > 60))) {
    throw new HttpsError('invalid-argument', 'Revisa las cantidades del carrito.');
  }
  const lineIds = items.map((item) => `${item.productId}:${JSON.stringify(Object.entries(item.variants).sort())}`);
  if (new Set(lineIds).size !== items.length) {
    throw new HttpsError('invalid-argument', 'El carrito contiene productos duplicados.');
  }
  return items;
}

function validateVariantSelection(item, product) {
  const options = product.variantOptions || {};
  const names = Object.keys(options);
  if (names.length !== Object.keys(item.variants).length ||
      names.some((name) => !Array.isArray(options[name]) || !options[name].includes(item.variants[name]))) {
    throw new HttpsError('failed-precondition', `Selecciona opciones válidas para ${product.name || 'el producto'}.`);
  }
}

function couponDiscount(coupon, subtotalMinor) {
  if (!coupon || coupon.active !== true) {
    throw new HttpsError('not-found', 'El cupón no existe o está desactivado.');
  }
  const now = Date.now();
  if ((coupon.startsAt && coupon.startsAt.toMillis() > now) ||
      (coupon.expiresAt && coupon.expiresAt.toMillis() <= now)) {
    throw new HttpsError('failed-precondition', 'El cupón todavía no está vigente o ya venció.');
  }
  const minimum = Math.round(Number(coupon.minSubtotal || 0) * 100);
  if (subtotalMinor < minimum) {
    throw new HttpsError('failed-precondition', `El mínimo de compra para este cupón es $${(minimum / 100).toFixed(2)}.`);
  }
  const maxUses = Number(coupon.maxUses || 0);
  if (maxUses > 0 && Number(coupon.usedCount || 0) + Number(coupon.reservedUses || 0) >= maxUses) {
    throw new HttpsError('resource-exhausted', 'El cupón alcanzó su límite de usos.');
  }
  const value = Number(coupon.value);
  if (!Number.isFinite(value) || value <= 0 ||
      (coupon.discountType === 'percent' && value > 100) ||
      !['percent', 'fixed'].includes(coupon.discountType)) {
    throw new HttpsError('failed-precondition', 'La configuración del cupón no es válida.');
  }
  const raw = coupon.discountType === 'percent'
      ? Math.round(subtotalMinor * value / 100)
      : Math.round(value * 100);
  return Math.min(subtotalMinor, raw);
}

async function releaseReservation(sessionRef) {
  await db.runTransaction(async (transaction) => {
    const session = await transaction.get(sessionRef);
    if (!session.exists || !['creating', 'pending'].includes(session.data().status)) return;
    const sessionData = session.data();
    const quantities = new Map();
    for (const item of sessionData.items) {
      quantities.set(item.productId, (quantities.get(item.productId) || 0) + item.quantity);
    }
    for (const [productId, quantity] of quantities) {
      const productRef = db.collection('products').doc(productId);
      transaction.update(productRef, { reservedStock: FieldValue.increment(-quantity) });
    }
    if (sessionData.couponId) {
      transaction.update(db.collection('coupons').doc(sessionData.couponId), {
        reservedUses: FieldValue.increment(-1),
      });
    }
    transaction.update(sessionRef, { status: 'expired', updatedAt: FieldValue.serverTimestamp() });
  });
}

async function finalizePaidIntent(intent) {
  const sessionId = intent.metadata?.sessionId;
  if (!sessionId) throw new Error('PaymentIntent is missing its checkout session id.');
  const sessionRef = db.collection('checkoutSessions').doc(sessionId);
  const orderRef = db.collection('orders').doc(intent.id);
  await db.runTransaction(async (transaction) => {
    const sessionSnap = await transaction.get(sessionRef);
    const existingOrder = await transaction.get(orderRef);
    if (existingOrder.exists) return;
    if (!sessionSnap.exists) throw new Error('Checkout session not found.');
    const session = sessionSnap.data();
    if (session.userId !== intent.metadata.userId || session.paymentIntentId !== intent.id) {
      throw new Error('PaymentIntent does not match the checkout session.');
    }
    if (intent.amount !== session.amountMinor || intent.currency !== session.currency) {
      throw new Error('PaymentIntent total does not match the server-side checkout.');
    }
    const couponRef = session.couponId ? db.collection('coupons').doc(session.couponId) : null;
    const couponSnap = couponRef ? await transaction.get(couponRef) : null;
    if (couponSnap && (!couponSnap.exists || Number(couponSnap.data().reservedUses || 0) < 1)) {
      throw new Error('Coupon reservation is inconsistent.');
    }
    const quantities = new Map();
    for (const item of session.items) {
      quantities.set(item.productId, (quantities.get(item.productId) || 0) + item.quantity);
    }
    const productRefs = [...quantities.keys()].map((productId) => db.collection('products').doc(productId));
    const productSnaps = [];
    for (const ref of productRefs) productSnaps.push(await transaction.get(ref));
    for (let index = 0; index < productRefs.length; index++) {
      const product = productSnaps[index];
      const data = product.data();
      const quantity = quantities.get(productRefs[index].id);
      if (!product.exists || (data.reservedStock || 0) < quantity) {
        throw new Error('Reserved inventory is inconsistent.');
      }
      transaction.update(productRefs[index], {
        stock: FieldValue.increment(-quantity),
        reservedStock: FieldValue.increment(-quantity),
      });
    }
    transaction.create(orderRef, {
      userId: session.userId,
      amount: session.amount,
      subtotal: session.subtotal,
      discount: session.discount,
      couponCode: session.couponCode,
      currency: session.currency,
      status: 'paid',
      paymentIntentId: intent.id,
      email: session.email || null,
      dateTime: Timestamp.now(),
      shipping: session.shipping,
      products: session.products,
    });
    if (session.email) {
      transaction.create(db.collection('mail').doc(intent.id), {
        to: session.email,
        message: {
          subject: `Pedido confirmado #${intent.id.slice(0, 8)}`,
          text: `Tu pago fue confirmado. El pedido #${intent.id.slice(0, 8)} está registrado y puedes seguir su estado desde Mis pedidos. Total: $${session.amount.toFixed(2)} ${session.currency.toUpperCase()}.`,
        },
      });
    }
    if (couponRef) {
      transaction.update(couponRef, {
        reservedUses: FieldValue.increment(-1),
        usedCount: FieldValue.increment(1),
      });
    }
    transaction.update(sessionRef, { status: 'paid', updatedAt: FieldValue.serverTimestamp() });
  });
  return intent.id;
}

exports.createPaymentIntent = onCall({ secrets: [stripeSecret], cors: true }, async (request) => {
  const userId = requireUser(request);
  const items = cleanItems(request.data?.items);
  const shipping = cleanShipping(request.data?.shipping);
  const couponCode = String(request.data?.couponCode || '').trim().toUpperCase();
  if (couponCode && !/^[A-Z0-9_-]{3,32}$/.test(couponCode)) {
    throw new HttpsError('invalid-argument', 'El código del cupón no es válido.');
  }
  const sessionId = randomUUID();
  const sessionRef = db.collection('checkoutSessions').doc(sessionId);
  const couponRef = couponCode ? db.collection('coupons').doc(couponCode) : null;
  const productRefs = items.map((item) => db.collection('products').doc(item.productId));
  let products = [];
  let amount = 0;
  let discount = 0;

  await db.runTransaction(async (transaction) => {
    const productSnaps = [];
    for (const ref of productRefs) productSnaps.push(await transaction.get(ref));
    const couponSnap = couponRef ? await transaction.get(couponRef) : null;
    products = [];
    amount = 0;
    discount = 0;
    const requestedById = new Map();
    for (let index = 0; index < items.length; index++) {
      const item = items[index];
      const snap = productSnaps[index];
      if (!snap.exists) throw new HttpsError('not-found', 'Uno de los productos ya no está disponible.');
      const product = snap.data();
      const stock = Number(product.stock ?? 0);
      const reservedStock = Number(product.reservedStock ?? 0);
      const price = Number(product.price);
      if (product.active === false || !Number.isFinite(price) || price <= 0) {
        throw new HttpsError('failed-precondition', 'Uno de los productos no está disponible.');
      }
      validateVariantSelection(item, product);
      requestedById.set(item.productId, (requestedById.get(item.productId) || 0) + item.quantity);
      const unitAmount = Math.round(price * 100);
      amount += unitAmount * item.quantity;
      products.push({
        id: item.productId,
        title: String(product.name || 'Producto'),
        price: unitAmount / 100,
        quantity: item.quantity,
        imageUrl: String(product.imageUrl || ''),
        variants: item.variants,
        variantLabel: Object.entries(item.variants).map(([key, variant]) => `${key}: ${variant}`).join(' · '),
      });
    }
    for (const [productId, requested] of requestedById) {
      const index = items.findIndex((item) => item.productId === productId);
      const product = productSnaps[index].data();
      if (Number(product.stock ?? 0) - Number(product.reservedStock ?? 0) < requested) {
        throw new HttpsError('failed-precondition', `No hay existencias suficientes de ${product.name || 'un producto'}.`);
      }
    }
    if (couponCode) {
      if (!couponSnap?.exists) throw new HttpsError('not-found', 'El cupón no existe.');
      discount = Math.min(Math.max(0, amount - 50), couponDiscount(couponSnap.data(), amount));
    }
    amount -= discount;
    if (amount < 50) throw new HttpsError('failed-precondition', 'El total mínimo del pago es $0.50.');
    for (const [productId, quantity] of requestedById) {
      transaction.set(db.collection('products').doc(productId), {
        reservedStock: FieldValue.increment(quantity),
      }, { merge: true });
    }
    if (couponRef) {
      transaction.update(couponRef, { reservedUses: FieldValue.increment(1) });
    }
    transaction.create(sessionRef, {
      userId,
      email: request.auth.token.email || null,
      items,
      products,
      amount: amount / 100,
      amountMinor: amount,
      subtotal: (amount + discount) / 100,
      discount: discount / 100,
      couponId: couponRef?.id || null,
      couponCode: couponCode || null,
      currency,
      shipping,
      status: 'creating',
      expiresAt: Timestamp.fromMillis(Date.now() + 30 * 60 * 1000),
      createdAt: FieldValue.serverTimestamp(),
    });
  });

  let intent;
  try {
    intent = await stripeClient().paymentIntents.create({
      amount,
      currency,
      automatic_payment_methods: { enabled: true },
      metadata: { userId, sessionId },
      receipt_email: request.auth.token.email || undefined,
      description: `Flutter Shop order ${sessionId.slice(0, 8)}`,
    }, { idempotencyKey: sessionId });
    await sessionRef.update({ paymentIntentId: intent.id, status: 'pending' });
  } catch (error) {
    await releaseReservation(sessionRef);
    await sessionRef.delete().catch(() => {});
    throw new HttpsError('internal', 'No se pudo iniciar el pago. Inténtalo de nuevo.');
  }
  return { paymentIntentId: intent.id, clientSecret: intent.client_secret };
});

exports.confirmPayment = onCall({ secrets: [stripeSecret], cors: true }, async (request) => {
  const userId = requireUser(request);
  const paymentIntentId = String(request.data?.paymentIntentId || '');
  if (!paymentIntentId.startsWith('pi_')) throw new HttpsError('invalid-argument', 'Pago no válido.');
  const intent = await stripeClient().paymentIntents.retrieve(paymentIntentId);
  if (intent.status !== 'succeeded' || intent.metadata.userId !== userId) {
    throw new HttpsError('failed-precondition', 'Stripe todavía no confirma el pago.');
  }
  const orderId = await finalizePaidIntent(intent);
  return { orderId };
});

exports.updateOrderStatus = onCall(async (request) => {
  if (!request.auth || request.auth.token.admin !== true) {
    throw new HttpsError('permission-denied', 'Se requiere el rol de administrador.');
  }
  const orderId = String(request.data?.orderId || '');
  const nextStatus = String(request.data?.status || '');
  const allowedTransitions = {
    paid: 'processing',
    processing: 'shipped',
    shipped: 'delivered',
  };
  if (!/^pi_[A-Za-z0-9_]+$/.test(orderId) || !Object.hasOwn(allowedTransitions, nextStatus)) {
    throw new HttpsError('invalid-argument', 'Estado de pedido no válido.');
  }
  const orderRef = db.collection('orders').doc(orderId);
  await db.runTransaction(async (transaction) => {
    const order = await transaction.get(orderRef);
    if (!order.exists) throw new HttpsError('not-found', 'No se encontró el pedido.');
    if (allowedTransitions[order.data().status] !== nextStatus) {
      throw new HttpsError('failed-precondition', 'El estado no sigue el flujo permitido.');
    }
    transaction.update(orderRef, {
      status: nextStatus,
      statusUpdatedAt: FieldValue.serverTimestamp(),
    });
  });
  return { orderId, status: nextStatus };
});

exports.stripeWebhook = onRequest({ secrets: [stripeSecret, webhookSecret], cors: false }, async (request, response) => {
  let event;
  try {
    event = stripeClient().webhooks.constructEvent(
      request.rawBody,
      request.headers['stripe-signature'],
      webhookSecret.value(),
    );
  } catch (error) {
    response.status(400).send(`Webhook signature error: ${error.message}`);
    return;
  }
  if (event.type === 'payment_intent.succeeded') {
    try {
      await finalizePaidIntent(event.data.object);
    } catch (error) {
      console.error('Could not finalize paid order', error);
      response.status(500).send('Order finalization failed.');
      return;
    }
  }
  response.json({ received: true });
});

exports.cleanupExpiredCheckouts = onSchedule({ schedule: 'every 10 minutes', secrets: [stripeSecret] }, async () => {
  const expired = await db.collection('checkoutSessions')
      .where('status', '==', 'pending')
      .where('expiresAt', '<=', Timestamp.now())
      .limit(100)
      .get();
  for (const document of expired.docs) {
    const session = document.data();
    try {
      if (session.paymentIntentId) {
        const intent = await stripeClient().paymentIntents.retrieve(session.paymentIntentId);
        if (intent.status === 'succeeded') {
          await finalizePaidIntent(intent);
          continue;
        }
        if (intent.status !== 'canceled') await stripeClient().paymentIntents.cancel(intent.id);
      }
      await releaseReservation(document.ref);
    } catch (error) {
      console.error(`Could not clean checkout ${document.id}`, error);
    }
  }

  const staleCreating = await db.collection('checkoutSessions')
      .where('status', '==', 'creating')
      .where('createdAt', '<=', Timestamp.fromMillis(Date.now() - 15 * 60 * 1000))
      .limit(100)
      .get();
  for (const document of staleCreating.docs) {
    try {
      await releaseReservation(document.ref);
    } catch (error) {
      console.error(`Could not release stale checkout ${document.id}`, error);
    }
  }
});
