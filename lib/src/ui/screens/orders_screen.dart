// lib/src/ui/screens/orders_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/orders_provider.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  // Variable para controlar la carga inicial
  late Future _ordersFuture;

  @override
  void initState() {
    super.initState();
    // Pedimos los datos solo una vez al entrar
    _ordersFuture = Provider.of<OrdersProvider>(context, listen: false).fetchOrders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis Pedidos')),
      body: FutureBuilder(
        future: _ordersFuture,
        builder: (context, snapshot) {
          // 1. Cargando
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 2. Consumimos los datos del Provider
          return Consumer<OrdersProvider>(
            builder: (context, orderData, child) {
              if (orderData.orders.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 70, color: Colors.grey),
                      SizedBox(height: 10),
                      Text('Aún no tienes pedidos registrados.'),
                    ],
                  ),
                );
              }

              return ListView.builder(
                itemCount: orderData.orders.length,
                itemBuilder: (context, index) {
                  final order = orderData.orders[index];
                  return Card(
                    margin: const EdgeInsets.all(10),
                    child: ExpansionTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.green[100],
                        child: const Icon(Icons.check, color: Colors.green),
                      ),
                      title: Text('\$${order.amount.toStringAsFixed(2)}'),
                      subtitle: Text(
                        DateFormat('dd/MM/yyyy HH:mm').format(order.dateTime),
                      ),
                      children: order.products.map((prod) {
                        return ListTile(
                          title: Text(prod.title),
                          trailing: Text('${prod.quantity} x \$${prod.price}'),
                        );
                      }).toList(),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}