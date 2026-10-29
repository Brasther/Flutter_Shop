import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth;
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/orders_provider.dart';
import '../../services/stripe_service.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _address = TextEditingController();
  final _couponController = TextEditingController();
  Map<String, dynamic>? _coupon;
  String? _couponError;
  bool _checkingCoupon = false;
  bool _saveAddress = false;
  String? _savedAddressId;
  bool _submitting = false;

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _couponController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadSavedAddress();
  }

  Future<void> _loadSavedAddress() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final saved = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('addresses')
          .orderBy('updatedAt', descending: true)
          .limit(1)
          .get();
      if (saved.docs.isEmpty || !mounted) return;
      final doc = saved.docs.first;
      setState(() {
        _savedAddressId = doc.id;
        _name.text = (doc.data()['fullName'] ?? '').toString();
        _address.text = (doc.data()['address'] ?? '').toString();
        _saveAddress = true;
      });
    } on FirebaseException {
      // Checkout remains available when the user has no saved address yet.
    }
  }

  double _discountFor(double subtotal) {
    final coupon = _coupon;
    if (coupon == null ||
        subtotal < ((coupon['minSubtotal'] as num?)?.toDouble() ?? 0)) {
      return 0;
    }
    final value = (coupon['value'] as num).toDouble();
    final discount =
        coupon['discountType'] == 'percent' ? subtotal * value / 100 : value;
    return discount.clamp(0, (subtotal - 0.50).clamp(0, subtotal)).toDouble();
  }

  Future<void> _applyCoupon() async {
    final user = context.read<AuthProvider>();
    final cart = context.read<CartProvider>();
    if (!user.isAuthenticated) {
      setState(() => _couponError = 'Inicia sesión para aplicar un cupón.');
      return;
    }
    final code = _couponController.text.trim().toUpperCase();
    if (!RegExp(r'^[A-Z0-9_-]{3,32}$').hasMatch(code)) {
      setState(() => _couponError = 'Escribe un código de cupón válido.');
      return;
    }
    setState(() {
      _checkingCoupon = true;
      _couponError = null;
      _coupon = null;
    });
    try {
      final doc = await FirebaseFirestore.instance
          .collection('coupons')
          .doc(code)
          .get();
      if (!doc.exists) {
        throw StateError('El cupón no existe.');
      }
      final data = doc.data()!;
      if (data['active'] != true) {
        throw StateError('El cupón está desactivado.');
      }
      final now = DateTime.now();
      final starts = data['startsAt'];
      final expires = data['expiresAt'];
      if (starts is Timestamp && starts.toDate().isAfter(now)) {
        throw StateError('El cupón todavía no está vigente.');
      }
      if (expires is Timestamp && !expires.toDate().isAfter(now)) {
        throw StateError('El cupón ya venció.');
      }
      final maximum = (data['maxUses'] as num?)?.toInt() ?? 0;
      final uses = ((data['usedCount'] as num?)?.toInt() ?? 0) +
          ((data['reservedUses'] as num?)?.toInt() ?? 0);
      if (maximum > 0 && uses >= maximum) {
        throw StateError('El cupón agotó sus usos.');
      }
      final minSubtotal = (data['minSubtotal'] as num?)?.toDouble() ?? 0;
      if (cart.totalAmount < minSubtotal) {
        throw StateError(
            'La compra mínima para este cupón es \$${minSubtotal.toStringAsFixed(2)}.');
      }
      if (!['percent', 'fixed'].contains(data['discountType']) ||
          (data['value'] as num?) == null) {
        throw StateError('La configuración del cupón no es válida.');
      }
      if (mounted) {
        setState(() => _coupon = {...data, 'code': code});
      }
    } catch (error) {
      if (mounted) {
        setState(() => _couponError = error is StateError
            ? error.message
            : 'No se pudo comprobar el cupón.');
      }
    } finally {
      if (mounted) setState(() => _checkingCoupon = false);
    }
  }

  Future<void> _pay() async {
    if (!_formKey.currentState!.validate()) return;
    final cart = context.read<CartProvider>();
    final ordersProvider = context.read<OrdersProvider>();
    if (cart.items.isEmpty) return;
    setState(() => _submitting = true);
    try {
      final orderId = await StripeService.checkout(
        items: cart.items.values
            .map((item) => {
                  'productId': item.productId,
                  'quantity': item.quantity,
                  'variants': item.variants,
                })
            .toList(),
        fullName: _name.text.trim(),
        address: _address.text.trim(),
        couponCode: _coupon?['code'] as String? ?? '',
      );
      if (!mounted) return;
      if (orderId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Pago cancelado. Tu carrito sigue guardado.')),
        );
        return;
      }
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (_saveAddress && userId != null) {
        final addressRef = FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('addresses')
            .doc(_savedAddressId);
        try {
          await addressRef.set({
            'fullName': _name.text.trim(),
            'address': _address.text.trim(),
            'updatedAt': FieldValue.serverTimestamp(),
            if (_savedAddressId == null)
              'createdAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        } on FirebaseException {
          debugPrint(
              'The paid order succeeded, but its address was not saved.');
        }
      }
      await cart.clear();
      await ordersProvider.fetchOrders();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Pago confirmado. Pedido #${orderId.substring(0, 8)}')),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (error) {
      if (!mounted) return;
      final message = error is StateError
          ? error.message
          : 'No pudimos completar la compra. Revisa tu conexión e inténtalo otra vez.';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final isAuthenticated = context.watch<AuthProvider>().isAuthenticated;
    return Scaffold(
      appBar: AppBar(title: const Text('Finalizar compra')),
      body: Form(
        key: _formKey,
        child: ListView(padding: const EdgeInsets.all(20), children: [
          Text('Datos de entrega',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          TextFormField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
                labelText: 'Nombre completo',
                prefixIcon: Icon(Icons.person_outline)),
            validator: (value) => value == null || value.trim().length < 3
                ? 'Escribe tu nombre completo.'
                : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _address,
            minLines: 2,
            maxLines: 3,
            decoration: const InputDecoration(
                labelText: 'Dirección de entrega',
                prefixIcon: Icon(Icons.location_on_outlined)),
            validator: (value) => value == null || value.trim().length < 8
                ? 'Escribe una dirección válida.'
                : null,
          ),
          if (isAuthenticated)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _saveAddress,
              onChanged: (value) =>
                  setState(() => _saveAddress = value ?? false),
              title: const Text('Guardar dirección para futuras compras'),
              controlAffinity: ListTileControlAffinity.leading,
            ),
          const SizedBox(height: 24),
          Text('Resumen', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          ...cart.items.values.map((item) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(item.title),
                subtitle: Text(
                    '${item.quantity} × \$${item.price.toStringAsFixed(2)}${item.variantLabel.isEmpty ? '' : ' · ${item.variantLabel}'}'),
                trailing: Text(
                    '\$${(item.quantity * item.price).toStringAsFixed(2)}'),
              )),
          const Divider(),
          TextField(
            controller: _couponController,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              labelText: 'Código promocional',
              prefixIcon: const Icon(Icons.local_offer_outlined),
              suffixIcon: TextButton(
                onPressed: _checkingCoupon ? null : _applyCoupon,
                child: Text(_checkingCoupon ? 'Validando…' : 'Aplicar'),
              ),
            ),
            onChanged: (_) => setState(() {
              _coupon = null;
              _couponError = null;
            }),
          ),
          if (_couponError != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(_couponError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          if (_coupon != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('Cupón ${_coupon!['code']} aplicado',
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.primary)),
            ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Subtotal'),
            trailing: Text('\$${cart.totalAmount.toStringAsFixed(2)}'),
          ),
          if (_discountFor(cart.totalAmount) > 0)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Descuento'),
              trailing: Text(
                  '-\$${_discountFor(cart.totalAmount).toStringAsFixed(2)}'),
            ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Total'),
            trailing: Text(
                '\$${(cart.totalAmount - _discountFor(cart.totalAmount)).toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.titleLarge),
          ),
          const SizedBox(height: 16),
          if (!isAuthenticated)
            const Card(
                child: Padding(
              padding: EdgeInsets.all(14),
              child: Text(
                  'Inicia sesión o crea una cuenta para finalizar la compra.'),
            )),
          if (!StripeService.isConfigured)
            const Card(
                child: Padding(
              padding: EdgeInsets.all(14),
              child: Text(
                  'Pagos pendientes de configuración. Se necesita desplegar el backend y definir STRIPE_PUBLISHABLE_KEY. No se realizará ningún cobro en este estado.'),
            )),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _submitting ||
                    !isAuthenticated ||
                    !StripeService.isConfigured ||
                    cart.items.isEmpty
                ? null
                : _pay,
            icon: _submitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.lock_outline),
            label: Text(_submitting ? 'Procesando…' : 'Pagar de forma segura'),
          ),
          const SizedBox(height: 8),
          const Text(
              'El servidor vuelve a validar el precio y las existencias antes de cobrar.',
              textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}
