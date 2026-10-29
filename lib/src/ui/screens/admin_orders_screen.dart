import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/order.dart';
import '../../providers/orders_provider.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  late Future<void> _load;
  bool _updating = false;

  @override
  void initState() {
    super.initState();
    _load = context.read<OrdersProvider>().fetchAllAdminOrders();
  }

  String? _nextStatus(String current) => switch (current) {
        'paid' => 'processing',
        'processing' => 'shipped',
        'shipped' => 'delivered',
        _ => null,
      };

  String _label(String status) => switch (status) {
        'paid' => 'Pagado',
        'processing' => 'En preparación',
        'shipped' => 'En camino',
        'delivered' => 'Entregado',
        _ => status,
      };

  Future<void> _advance(Order order) async {
    final next = _nextStatus(order.status);
    if (next == null) return;
    setState(() => _updating = true);
    try {
      await context.read<OrdersProvider>().advanceOrder(order.id, next);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo actualizar el pedido.')),
        );
      }
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Administrar pedidos')),
        body: FutureBuilder<void>(
          future: _load,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            return Consumer<OrdersProvider>(builder: (context, provider, _) {
              if (provider.error != null && provider.orders.isEmpty) {
                return Center(child: Text(provider.error!));
              }
              if (provider.orders.isEmpty) {
                return const Center(child: Text('Todavía no hay pedidos.'));
              }
              return RefreshIndicator(
                onRefresh: () => provider.fetchAllAdminOrders(),
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: provider.orders.length,
                  itemBuilder: (context, index) =>
                      _orderCard(provider.orders[index]),
                ),
              );
            });
          },
        ),
      );

  Widget _orderCard(Order order) {
    final next = _nextStatus(order.status);
    final shipping = order.shipping;
    return Card(
      child: ExpansionTile(
        leading: const CircleAvatar(child: Icon(Icons.receipt_long_outlined)),
        title: Text(
            'Pedido #${order.id.substring(0, order.id.length < 8 ? order.id.length : 8)}'),
        subtitle: Text(
          '\$${order.amount.toStringAsFixed(2)} · ${_label(order.status)} · ${DateFormat('dd/MM/yyyy').format(order.dateTime)}',
        ),
        children: [
          ListTile(
            title: Text((shipping['fullName'] ?? 'Cliente').toString()),
            subtitle: Text(
                '${order.email.isEmpty ? 'Sin correo' : order.email}\n${(shipping['address'] ?? 'Sin dirección').toString()}'),
            trailing: const Icon(Icons.local_shipping_outlined),
          ),
          ...order.products.map((item) => ListTile(
                dense: true,
                title: Text(item.title),
                subtitle: Text(
                    '${item.quantity} × \$${item.price.toStringAsFixed(2)}'),
              )),
          if (next != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _updating ? null : () => _advance(order),
                  icon: const Icon(Icons.arrow_forward),
                  label: Text('Marcar como ${_label(next).toLowerCase()}'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
