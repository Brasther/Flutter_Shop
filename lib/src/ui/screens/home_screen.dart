// lib/src/ui/screens/home_screen.dart
import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../services/product_service.dart';
import '../widgets/product_card.dart';

import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import 'cart_screen.dart';
import 'product_detail_screen.dart'; 
import '../delegates/search_product_delegate.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ProductService _productService = ProductService();
  late Future<List<Product>> _productsFuture;

  @override
  void initState() {
    super.initState();
    _productsFuture = _productService.getProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FlutterShop'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Esta función nativa lanza la pantalla de búsqueda
              showSearch(
                context: context,
                delegate: SearchProductDelegate(),
              );
            },
          ),
        ],
      ),

      // --- AGREGADO: BOTÓN PARA SUBIR DATOS A FIREBASE ---
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Theme.of(context).primaryColor,
        // 1. Icono a la izquierda
        icon: const Icon(Icons.cloud_upload, color: Colors.white),
        // 2. Texto descriptivo
        label: const Text(
          'Cargar ADMIN', 
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
        ),
        onPressed: () async {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Subiendo productos a la nube...'))
          );
          
          await _productService.uploadMockData();
          
          setState(() {
            _productsFuture = _productService.getProducts();
          });
        },
      ),
      // ---------------------------------------------------

      body: FutureBuilder<List<Product>>(
        future: _productsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.storefront, size: 60, color: Colors.grey),
                  SizedBox(height: 10),
                  Text('La tienda está vacía.'),
                  Text('Usa el botón azul para cargar productos.'),
                ],
              ),
            );
          }

          final products = snapshot.data!;
          
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];

              return Hero(
                tag: product.id,
                child: Material(
                  color: Colors.transparent,
                  child: ProductCard(
                    product: product,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProductDetailScreen(product: product),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}