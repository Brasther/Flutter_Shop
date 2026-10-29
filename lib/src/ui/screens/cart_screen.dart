import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../theme/app_theme.dart';
import 'checkout_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tu carrito'), actions: [
        Consumer<CartProvider>(
            builder: (context, cart, _) => cart.items.isEmpty
                ? const SizedBox.shrink()
                : TextButton(
                    onPressed: cart.clear, child: const Text('Vaciar'))),
      ]),
      body: Consumer<CartProvider>(builder: (context, cart, _) {
        if (cart.items.isEmpty) {
          return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(
              Icons.shopping_bag_outlined,
              size: 72,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text('Tu carrito está vacío',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text('Explora la tienda y agrega tus favoritos.'),
          ]));
        }
        final items = cart.items.values.toList();
        return Column(children: [
          Expanded(
              child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                  child: Padding(
                padding: const EdgeInsets.all(10),
                child: Row(children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                        width: 72,
                        height: 72,
                        child: CachedNetworkImage(
                          imageUrl: item.imageUrl,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) =>
                              const Icon(Icons.image_not_supported),
                        )),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text('\$${item.price.toStringAsFixed(2)}',
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.primary)),
                        if (item.variantLabel.isNotEmpty)
                          Text(item.variantLabel,
                              style: Theme.of(context).textTheme.bodySmall),
                        Row(children: [
                          IconButton(
                              onPressed: () =>
                                  cart.setQuantity(item.id, item.quantity - 1),
                              icon: const Icon(Icons.remove_circle_outline),
                              visualDensity: VisualDensity.compact),
                          AnimatedSwitcher(
                            duration: MediaQuery.of(context).disableAnimations
                                ? Duration.zero
                                : const Duration(milliseconds: 180),
                            transitionBuilder: (child, animation) =>
                                ScaleTransition(
                              scale: animation,
                              child: child,
                            ),
                            child: Text(
                              '${item.quantity}',
                              key: ValueKey(item.quantity),
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          IconButton(
                              onPressed: cart.canIncrement(item.id)
                                  ? () => cart.setQuantity(
                                      item.id, item.quantity + 1)
                                  : null,
                              icon: const Icon(Icons.add_circle_outline),
                              visualDensity: VisualDensity.compact),
                        ]),
                      ])),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    IconButton(
                        tooltip: 'Quitar',
                        onPressed: () => cart.removeItem(item.id),
                        icon: const Icon(Icons.delete_outline)),
                    Text('\$${(item.price * item.quantity).toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ]),
                ]),
              ));
            },
          )),
          SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .06),
                      blurRadius: 12,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Subtotal'),
                        Text('\$${cart.totalAmount.toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor)),
                      ]),
                  const SizedBox(height: 14),
                  SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const CheckoutScreen())),
                        child: const Text('Continuar al pago'),
                      )),
                ]),
              )),
        ]);
      }),
    );
  }
}
