const { initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');

const projectId = process.env.GCLOUD_PROJECT || process.argv[2];
if (!projectId) {
  console.error('Usage: GCLOUD_PROJECT=<firebase-project> node scripts/seed-demo-catalog.js');
  process.exit(1);
}

initializeApp({ projectId });
const db = getFirestore();
const products = [
  ['demo-shoes', 'Urban Runner', 'Zapatilla urbana liviana para todos los días.', 64.90, 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?auto=format&fit=crop&w=900&q=85', 'Calzado', 12],
  ['demo-headphones', 'Studio Headphones', 'Audífonos inalámbricos con sonido envolvente.', 89, 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?auto=format&fit=crop&w=900&q=85', 'Audio', 8],
  ['demo-watch', 'Minimal Watch', 'Reloj minimalista con correa intercambiable.', 119, 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?auto=format&fit=crop&w=900&q=85', 'Accesorios', 5],
  ['demo-camera', 'Instant Camera', 'Cámara compacta para capturar momentos especiales.', 149.50, 'https://images.unsplash.com/photo-1516035069371-29a1b244cc32?auto=format&fit=crop&w=900&q=85', 'Tecnología', 4],
  ['demo-backpack', 'Everyday Backpack', 'Mochila resistente con espacio para portátil.', 54, 'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?auto=format&fit=crop&w=900&q=85', 'Accesorios', 20],
  ['demo-coffee', 'Coffee Press', 'Prensa francesa de vidrio para café de especialidad.', 32, 'https://images.unsplash.com/photo-1517668808822-9ebb02f2a0e6?auto=format&fit=crop&w=900&q=85', 'Hogar', 15],
];

async function seed() {
  const batch = db.batch();
  for (const [id, name, description, price, imageUrl, category, stock] of products) {
    batch.set(db.collection('products').doc(id), {
      id, name, description, price, imageUrl, category, stock,
      reservedStock: 0,
      active: true,
      ...(id === 'demo-shoes' ? { variantOptions: { Talla: ['38', '39', '40', '41', '42'], Color: ['Rojo', 'Negro'] } } : {}),
      ...(id === 'demo-headphones' ? { variantOptions: { Color: ['Negro', 'Blanco'] } } : {}),
    }, { merge: true });
  }
  const couponRef = db.collection('coupons').doc('BIENVENIDO10');
  if (!(await couponRef.get()).exists) {
    batch.set(couponRef, {
      code: 'BIENVENIDO10',
      discountType: 'percent',
      value: 10,
      active: true,
      minSubtotal: 0,
      maxUses: 0,
      usedCount: 0,
      reservedUses: 0,
      expiresAt: null,
    });
  }
  await batch.commit();
  console.log(`Seeded ${products.length} demo products and BIENVENIDO10 in ${projectId}.`);
}

seed().catch((error) => {
  console.error(error.message);
  process.exitCode = 1;
});
