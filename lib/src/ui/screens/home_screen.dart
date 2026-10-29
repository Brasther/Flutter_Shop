import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product.dart';
import '../../providers/favorites_provider.dart';
import '../../services/product_service.dart';
import '../delegates/search_product_delegate.dart';
import '../widgets/product_card.dart';
import 'product_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _service = ProductService();
  final _minPriceController = TextEditingController();
  final _maxPriceController = TextEditingController();
  late Future<List<Product>> _productsFuture;
  String _category = 'Todos';
  String _sort = 'Recomendados';
  bool _favoritesOnly = false;

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _productsFuture = _service.getProducts();
  }

  Future<void> _refresh() async {
    setState(() => _productsFuture = _service.getProducts());
    await _productsFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Shop'),
        actions: [
          IconButton(
            tooltip: 'Buscar productos',
            icon: const Icon(Icons.search),
            onPressed: () =>
                showSearch(context: context, delegate: SearchProductDelegate()),
          ),
          IconButton(
            tooltip: _favoritesOnly ? 'Ver todo' : 'Ver favoritos',
            icon: Icon(_favoritesOnly ? Icons.favorite : Icons.favorite_border),
            onPressed: () => setState(() => _favoritesOnly = !_favoritesOnly),
          ),
        ],
      ),
      body: FutureBuilder<List<Product>>(
        future: _productsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _MessageState(
              icon: Icons.cloud_off,
              title: 'No se pudo cargar la tienda',
              action: TextButton(
                  onPressed: _refresh, child: const Text('Reintentar')),
            );
          }
          final products = snapshot.data ?? ProductService.demoProducts;
          final categories = [
            'Todos',
            ...{for (final p in products) p.category}
          ];
          final favorites = context.watch<FavoritesProvider>();
          final minPrice = double.tryParse(_minPriceController.text) ?? 0;
          final maxPrice =
              double.tryParse(_maxPriceController.text) ?? double.infinity;
          final visible = products.where((p) {
            return (_category == 'Todos' || p.category == _category) &&
                (!_favoritesOnly || favorites.contains(p.id)) &&
                p.price >= minPrice &&
                p.price <= maxPrice;
          }).toList();
          if (_sort == 'Precio: menor a mayor') {
            visible.sort((a, b) => a.price.compareTo(b.price));
          }
          if (_sort == 'Precio: mayor a menor') {
            visible.sort((a, b) => b.price.compareTo(a.price));
          }
          if (_sort == 'Nombre') {
            visible.sort((a, b) => a.name.compareTo(b.name));
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Encuentra algo que te encante',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        const Text('Productos seleccionados para ti'),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 42,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: categories.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              final category = categories[index];
                              return ChoiceChip(
                                label: Text(category),
                                selected: _category == category,
                                onSelected: (_) =>
                                    setState(() => _category = category),
                              );
                            },
                          ),
                        ),
                        ExpansionTile(
                          tilePadding: EdgeInsets.zero,
                          title: const Text('Filtrar por precio'),
                          leading: const Icon(Icons.tune),
                          children: [
                            Row(children: [
                              Expanded(
                                child: TextField(
                                  controller: _minPriceController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  decoration: const InputDecoration(
                                      labelText: 'Mínimo', prefixText: '\$'),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextField(
                                  controller: _maxPriceController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  decoration: const InputDecoration(
                                      labelText: 'Máximo', prefixText: '\$'),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                              IconButton(
                                tooltip: 'Limpiar precios',
                                onPressed: () {
                                  _minPriceController.clear();
                                  _maxPriceController.clear();
                                  setState(() {});
                                },
                                icon: const Icon(Icons.clear),
                              ),
                            ]),
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(
                                child: Text('${visible.length} productos',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall)),
                            DropdownButton<String>(
                              value: _sort,
                              underline: const SizedBox.shrink(),
                              items: const [
                                'Recomendados',
                                'Precio: menor a mayor',
                                'Precio: mayor a menor',
                                'Nombre'
                              ]
                                  .map((sort) => DropdownMenuItem(
                                      value: sort, child: Text(sort)))
                                  .toList(),
                              onChanged: (value) =>
                                  setState(() => _sort = value ?? _sort),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (visible.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _MessageState(
                        icon: _favoritesOnly
                            ? Icons.favorite_border
                            : Icons.search_off,
                        title: _favoritesOnly
                            ? 'Aún no tienes favoritos'
                            : 'No hay productos con estos filtros'),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    sliver: SliverGrid.builder(
                      itemCount: visible.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.68,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemBuilder: (context, index) {
                        final product = visible[index];
                        return ProductCard(
                          product: product,
                          animationDelay: MediaQuery.of(context)
                                  .disableAnimations
                              ? Duration.zero
                              : Duration(
                                  milliseconds:
                                      (index * 45).clamp(0, 450).toInt(),
                                ),
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      ProductDetailScreen(product: product))),
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({required this.icon, required this.title, this.action});
  final IconData icon;
  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(
            icon,
            size: 56,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(title),
          if (action != null) action!,
        ]),
      );
}
