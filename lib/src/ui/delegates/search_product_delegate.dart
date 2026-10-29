// lib/src/ui/delegates/search_product_delegate.dart
import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../services/product_service.dart';
import '../widgets/product_card.dart';
import '../screens/product_detail_screen.dart';

class SearchProductDelegate extends SearchDelegate<Product?> {
  SearchProductDelegate() {
    _suggestionsFuture = _productService.getProducts();
  }

  final ProductService _productService = ProductService();
  late final Future<List<Product>> _suggestionsFuture;

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
    if (query.trim().isEmpty) {
      return const Center(child: Text('Ingresa un término de búsqueda'));
    }
    return _results(context, query);
  }

  Widget _results(BuildContext context, String value) {
    return FutureBuilder<List<Product>>(
      future: _productService.searchProducts(value),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(
              child: Text('No se pudieron cargar los resultados.'));
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
    final normalized = query.trim().toLowerCase();
    return FutureBuilder<List<Product>>(
      future: _suggestionsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final suggestions = (snapshot.data ?? ProductService.demoProducts)
            .where((product) =>
                normalized.isEmpty ||
                product.name.toLowerCase().contains(normalized) ||
                product.category.toLowerCase().contains(normalized) ||
                product.description.toLowerCase().contains(normalized))
            .take(6)
            .toList();
        if (suggestions.isEmpty) {
          return const Center(child: Text('No encontramos sugerencias.'));
        }
        return ListView(
          children: suggestions
              .map((product) => ListTile(
                    leading: Icon(
                        normalized.isEmpty ? Icons.trending_up : Icons.search),
                    title: Text(product.name),
                    subtitle: Text(product.category),
                    onTap: () {
                      query = product.name;
                      showResults(context);
                    },
                  ))
              .toList(),
        );
      },
    );
  }
}
