import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import '../models/order.dart';

class OrdersProvider extends ChangeNotifier {
  final List<Order> _orders = [];
  String? _loadedUid;
  List<Order> get orders => List.unmodifiable(_orders);
  String? _error;
  String? get error => _error;

  Future<void> fetchOrders() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _orders.clear();
      _error = null;
      _loadedUid = null;
      notifyListeners();
      return;
    }
    if (_loadedUid != user.uid) {
      // Never show a previously signed-in user's cached orders to a new user.
      _orders.clear();
      _error = null;
      _loadedUid = user.uid;
    }
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('userId', isEqualTo: user.uid)
          .get();
      _orders
        ..clear()
        ..addAll(snapshot.docs.map((doc) => Order.fromMap(doc.data(), doc.id)))
        ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
      _error = null;
    } on FirebaseException catch (e) {
      _error = e.message ?? 'No se pudieron cargar tus pedidos.';
    }
    notifyListeners();
  }

  Future<void> fetchAllAdminOrders() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('orders').get();
      _orders
        ..clear()
        ..addAll(snapshot.docs.map((doc) => Order.fromMap(doc.data(), doc.id)))
        ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
      _error = null;
      _loadedUid = '__admin__';
    } on FirebaseException catch (e) {
      _error = e.message ?? 'No se pudieron cargar los pedidos.';
    }
    notifyListeners();
  }

  Future<void> advanceOrder(String orderId, String status) async {
    await FirebaseFunctions.instance.httpsCallable('updateOrderStatus').call({
      'orderId': orderId,
      'status': status,
    });
    await fetchAllAdminOrders();
  }
}
