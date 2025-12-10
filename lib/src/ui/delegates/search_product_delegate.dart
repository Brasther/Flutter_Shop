// lib/src/ui/delegates/search_product_delegate.dart
import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../services/product_service.dart';
import '../widgets/product_card.dart';
import '../screens/product_detail_screen.dart';

class SearchProductDelegate extends SearchDelegate<Product?> {
  final ProductService _productService = ProductService();

  @override
  String get searchFieldLabel => 'Buscar producto...';

  @override
  List<Widget>? buildActions(BuildContext context) {
    // Botón "X" para limpiar la búsqueda
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    // Flecha para volver atrás
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    // Cuando el usuario da "Enter" o busca
    if (query.trim().isEmpty) {
      return const Center(child: Text('Ingresa un término de búsqueda'));
    }

    return FutureBuilder<List<Product>>(
      future: _productService.searchProducts(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 80, color: Colors.grey),
                Text('No se encontraron productos'),
              ],
            ),
          );
        }

        // Reutilizamos el ProductCard en una lista
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final product = snapshot.data![index];
            return ProductCard(
              product: product,
              onTap: () {
                // Navegamos al detalle y cerramos la búsqueda
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductDetailScreen(product: product),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    // Sugerencias mientras escribe (podemos dejarlo vacío o mostrar historial)
    return Container();
  }
}