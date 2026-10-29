import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/orders_provider.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  late Future<void> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _ordersFuture = context.read<OrdersProvider>().fetchOrders();
  }

  Future<void> _refresh() async {
    _ordersFuture = context.read<OrdersProvider>().fetchOrders();
    await _ordersFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis pedidos')),
      body: FutureBuilder<void>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          return Consumer<OrdersProvider>(builder: (context, provider, _) {
            if (provider.error != null && provider.orders.isEmpty) {
              return Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.cloud_off, size: 50),
                const SizedBox(height: 8),
                const Text('No se pudieron cargar tus pedidos.'),
                TextButton(
                  onPressed: () => setState(() => _ordersFuture =
                      context.read<OrdersProvider>().fetchOrders()),
                  child: const Text('Reintentar'),
                ),
              ]));
            }
            if (provider.orders.isEmpty) {
              return const Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.receipt_long_outlined, size: 60, color: Colors.grey),
                SizedBox(height: 10),
                Text('Aún no tienes pedidos.'),
              ]));
            }
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: provider.orders.length,
                itemBuilder: (context, index) {
                  final order = provider.orders[index];
                  return Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: ExpansionTile(
                      leading: const CircleAvatar(
                          child: Icon(Icons.check_circle_outline)),
                      title: Text('\$${order.amount.toStringAsFixed(2)}'),
                      subtitle: Text(
                          '${DateFormat('dd/MM/yyyy HH:mm').format(order.dateTime)} · ${_status(order.status)}'),
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Seguimiento del pedido'),
                              const SizedBox(height: 8),
                              LinearProgressIndicator(
                                  value: _progress(order.status)),
                              const SizedBox(height: 4),
                              Text(_status(order.status)),
                            ],
                          ),
                        ),
                        if (order.discount > 0)
                          ListTile(
                            title: Text('Descuento ${order.couponCode ?? ''}'),
                            trailing:
                                Text('-\$${order.discount.toStringAsFixed(2)}'),
                          ),
                        ...order.products.map((product) => ListTile(
                              title: Text(product.title),
                              subtitle: Text(
                                  '${product.quantity} × \$${product.price.toStringAsFixed(2)}${product.variantLabel.isEmpty ? '' : ' · ${product.variantLabel}'}'),
                              trailing: Text(
                                  '\$${(product.quantity * product.price).toStringAsFixed(2)}'),
                            )),
                      ],
                    ),
                  );
                },
              ),
            );
          });
        },
      ),
    );
  }

  String _status(String status) => switch (status) {
        'paid' => 'Pagado',
        'processing' => 'En preparación',
        'shipped' => 'En camino',
        'delivered' => 'Entregado',
        _ => 'Pendiente',
      };

  double _progress(String status) => switch (status) {
        'paid' => .25,
        'processing' => .5,
        'shipped' => .75,
        'delivered' => 1,
        _ => 0,
      };
}
