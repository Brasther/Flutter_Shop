import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product.dart';
import '../../providers/orders_provider.dart';
import '../../services/product_service.dart';
import 'admin_orders_screen.dart';
import 'admin_products_screen.dart';
import 'admin_coupons_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _products = ProductService();
  late Future<List<Product>> _productsFuture;
  late Future<void> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _productsFuture = _products.getManagedProducts();
    _ordersFuture = context.read<OrdersProvider>().fetchAllAdminOrders();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Panel de administración')),
        body: FutureBuilder<List<Product>>(
          future: _productsFuture,
          builder: (context, productsSnapshot) => FutureBuilder<void>(
            future: _ordersFuture,
            builder: (context, _) => Consumer<OrdersProvider>(
              builder: (context, orders, __) {
                final visibleOrders = orders.orders
                    .where((order) => order.status != 'cancelled')
                    .toList();
                final revenue = visibleOrders.fold<double>(
                    0, (sum, order) => sum + order.amount);
                final lowStock = (productsSnapshot.data ?? const <Product>[])
                    .where((product) => product.stock <= 5)
                    .length;
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text('Resumen de la tienda',
                        style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 16),
                    Wrap(spacing: 12, runSpacing: 12, children: [
                      _MetricCard(
                          icon: Icons.receipt_long_outlined,
                          label: 'Pedidos',
                          value: '${visibleOrders.length}'),
                      _MetricCard(
                          icon: Icons.attach_money,
                          label: 'Ventas registradas',
                          value: '\$${revenue.toStringAsFixed(2)}'),
                      _MetricCard(
                          icon: Icons.inventory_2_outlined,
                          label: 'Productos con stock bajo',
                          value: '$lowStock'),
                    ]),
                    if (orders.error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text('Pedidos: ${orders.error}'),
                      ),
                    const SizedBox(height: 16),
                    Card(
                      child: Column(children: [
                        ListTile(
                          leading: const Icon(Icons.receipt_long_outlined),
                          title: const Text('Administrar pedidos'),
                          subtitle: const Text('Preparación, envío y entrega'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const AdminOrdersScreen()),
                          ),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.local_offer_outlined),
                          title: const Text('Cupones y promociones'),
                          subtitle: const Text('Descuentos y vigencia'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const AdminCouponsScreen()),
                          ),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.inventory_2_outlined),
                          title: const Text('Administrar catálogo'),
                          subtitle:
                              const Text('Productos, precios e inventario'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const AdminProductsScreen()),
                          ),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Las ventas se calculan sobre pedidos pagados. El inventario bajo indica cinco unidades o menos.',
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );
}

class _MetricCard extends StatelessWidget {
  const _MetricCard(
      {required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 190,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 12),
              Text(value, style: Theme.of(context).textTheme.headlineSmall),
              Text(label),
            ]),
          ),
        ),
      );
}
