// lib/src/providers/orders_provider.dart
import 'package:flutter/material.dart';
// CORRECCIÓN AQUÍ: Agregamos "hide Order" para evitar el conflicto con la clase de Google
import 'package:cloud_firestore/cloud_firestore.dart' hide Order; 
import 'package:firebase_auth/firebase_auth.dart';
import '../models/cart_item.dart';
import '../models/order.dart';

class OrdersProvider extends ChangeNotifier {
  List<Order> _orders = [];
  
  // Instancias de Firebase
  final _db = FirebaseFirestore.instance;
  
  List<Order> get orders => [..._orders];

  // 1. CARGAR PEDIDOS (Solo los míos)
  Future<void> fetchOrders() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return; // Seguridad

    try {
      final snapshot = await _db
          .collection('orders')
          .where('userId', isEqualTo: user.uid) // FILTRO CLAVE
          // .orderBy('dateTime', descending: true) // <--- COMENTADO TEMPORALMENTE
          .get();

      _orders = snapshot.docs.map((doc) {
        return Order.fromMap(doc.data(), doc.id);
      }).toList();
      
      notifyListeners();
    } catch (e) {
      print('Error cargando pedidos: $e');
    }
  }

  // 2. CREAR NUEVO PEDIDO
  Future<void> addOrder(List<CartItem> cartProducts, double total) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final timestamp = DateTime.now();
    
    // Creamos el objeto Order temporalmente
    final newOrder = Order(
      id: '', 
      amount: total,
      products: cartProducts,
      dateTime: timestamp,
    );

    try {
      // Guardamos en la Nube
      final docRef = await _db.collection('orders').add(
        newOrder.toMap(user.uid)
      );

      // Agregamos a la lista local para que se vea instantáneo en la UI
      _orders.insert(0, Order(
        id: docRef.id,
        amount: total,
        products: cartProducts,
        dateTime: timestamp,
      ));
      
      notifyListeners();
    } catch (e) {
      print('Error creando pedido: $e');
      rethrow; 
    }
  }
}