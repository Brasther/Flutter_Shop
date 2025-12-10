// lib/src/ui/screens/checkout_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/orders_provider.dart';
import '../../services/stripe_service.dart'; // <--- IMPORTANTE

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  
  // Eliminamos _cardController porque Stripe maneja la tarjeta

  @override
  void initState() {
    super.initState();
    // Inicializamos Stripe al entrar (por si acaso no se hizo en main)
    StripeService.init(); 
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  // Lógica de Pago + Pedido
  void _submitOrder() async {
    if (_formKey.currentState!.validate()) {
      
      final cart = context.read<CartProvider>();
      
      // 1. Calcular total en centavos (Stripe lo pide así: $20.00 -> "2000")
      final amountInCents = (cart.totalAmount * 100).toInt().toString();

      // Feedback visual
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Abriendo pasarela de pago...')),
      );

      // 2. LLAMAR A STRIPE
      final success = await StripeService.makePayment(amountInCents, 'usd');

      if (success) {
        // 3. Si pagó correctamente, guardamos el pedido en Firebase
        if (!mounted) return;
        
        try {
          await context.read<OrdersProvider>().addOrder(
            cart.items.values.toList(), 
            cart.totalAmount,
          );

          // Limpiamos carrito
          cart.clear();

          // Éxito
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('¡Pago exitoso! Pedido enviado 🚀'),
              backgroundColor: Colors.green,
            ),
          );

          // Volver al inicio
          Navigator.of(context).popUntil((route) => route.isFirst);
          
        } catch (e) {
          // Si falló al guardar en Firebase pero pagó en Stripe (caso raro)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Pago realizado, pero error al guardar: $e')),
          );
        }
      } else {
        // 4. Si canceló o falló el pago
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('El pago fue cancelado o falló ❌'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Finalizar Compra')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Datos de Envío',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // CAMPO 1: NOMBRE
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre Completo',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Requerido';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // CAMPO 2: DIRECCIÓN
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Dirección de Entrega',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.home),
                ),
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Requerido';
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // NOTA INFORMATIVA
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.lock, color: Colors.blue),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'El pago se procesará de forma segura a través de Stripe.',
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // BOTÓN DE CONFIRMAR Y PAGAR
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _submitOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'PAGAR Y CONFIRMAR',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}