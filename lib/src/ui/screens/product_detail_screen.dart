// lib/src/ui/screens/product_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart'; // <--- IMPORTANTE: Para acceder al carrito
import '../../models/product.dart';
import '../../providers/cart_provider.dart'; // <--- IMPORTANTE: Tu lógica de carrito
import '../../services/product_service.dart';
import '../widgets/product_card.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final Map<String, String> _selectedVariants = {};

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final variantsComplete = product.variantOptions.keys
        .every((name) => _selectedVariants.containsKey(name));
    return Scaffold(
      // AppBar transparente que flota sobre el contenido
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. IMAGEN GRANDE (Con Hero Animation)
            Hero(
              tag: product.id,
              child: SizedBox(
                height: 300,
                width: double.infinity,
                child: CachedNetworkImage(
                  imageUrl: product.imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) =>
                      Container(color: Colors.grey[200]),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                ),
              ),
            ),

            // 2. CONTENIDO (Blanco con bordes redondeados hacia arriba)
            Transform.translate(
              offset: const Offset(0, -20), // Efecto de solapamiento
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Barra decorativa pequeña
                    Center(
                      child: Container(
                        width: 50,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Nombre y Precio
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            product.name,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                        Text(
                          '\$${product.price}',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                    Text(
                      'Descripción',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      product.description,
                      style: TextStyle(color: Colors.grey[600], height: 1.5),
                    ),
                    if (product.variantOptions.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      for (final entry in product.variantOptions.entries) ...[
                        Text(entry.key,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: entry.value
                              .map((option) => ChoiceChip(
                                    label: Text(option),
                                    selected:
                                        _selectedVariants[entry.key] == option,
                                    onSelected: (_) => setState(() =>
                                        _selectedVariants[entry.key] = option),
                                  ))
                              .toList(),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ],
                    const SizedBox(height: 28),
                    Text('También te puede gustar',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 230,
                      child: FutureBuilder<List<Product>>(
                        future: ProductService().getProducts(),
                        builder: (context, snapshot) {
                          final related = (snapshot.data ?? const <Product>[])
                              .where((item) =>
                                  item.id != product.id &&
                                  item.category == product.category)
                              .take(5)
                              .toList();
                          if (related.isEmpty) {
                            return const Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                    'Pronto añadiremos más productos de esta categoría.'));
                          }
                          return ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: related.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 12),
                            itemBuilder: (context, index) => SizedBox(
                              width: 160,
                              child: ProductCard(
                                product: related[index],
                                onTap: () => Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => ProductDetailScreen(
                                          product: related[index])),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(children: [
                      const Icon(Icons.inventory_2_outlined, size: 18),
                      const SizedBox(width: 8),
                      Text(product.stock > 0
                          ? '${product.stock} disponibles'
                          : 'Agotado'),
                    ]),
                    const SizedBox(
                        height:
                            80), // Espacio extra para que el botón no tape texto
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // 3. BOTÓN "AGREGAR AL CARRITO" (Fijo abajo)
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: product.stock <= 0 || !variantsComplete
                ? null
                : () {
                    // --- AQUÍ ESTÁ LA MAGIA ---
                    // 1. Guardamos en el Provider (Memoria + Disco)
                    final added = context.read<CartProvider>().addItem(
                          product.id,
                          product.price,
                          product.name,
                          product.imageUrl,
                          stock: product.stock,
                          variants: Map.of(_selectedVariants),
                        );

                    if (!context.mounted) return;

                    // 2. Mostramos confirmación visual
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(added
                            ? '¡${product.name} agregado al carrito!'
                            : 'No hay más unidades disponibles.'),
                        backgroundColor: Theme.of(context).primaryColor,
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Agregar al Carrito',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}
