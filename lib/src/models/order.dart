// lib/src/models/order.dart
import 'package:cloud_firestore/cloud_firestore.dart'; // Para Timestamp
import 'cart_item.dart';

class Order {
  final String id;
  final double amount;
  final List<CartItem> products;
  final DateTime dateTime;

  Order({
    required this.id,
    required this.amount,
    required this.products,
    required this.dateTime,
  });

  // ENVIAR A FIREBASE (Serialización)
  Map<String, dynamic> toMap(String userId) {
    return {
      'userId': userId, // ¡Importante! Para saber de quién es el pedido
      'amount': amount,
      'dateTime': Timestamp.fromDate(dateTime), // DateTime -> Timestamp
      // Convertimos la lista de objetos CartItem a lista de Mapas
      'products': products.map((item) => item.toMap()).toList(),
    };
  }

  // TRAER DE FIREBASE (Deserialización)
  factory Order.fromMap(Map<String, dynamic> map, String docId) {
    return Order(
      id: docId,
      amount: (map['amount'] as num).toDouble(),
      // Timestamp -> DateTime
      dateTime: (map['dateTime'] as Timestamp).toDate(),
      // Lista de Mapas -> Lista de CartItems
      products: (map['products'] as List<dynamic>)
          .map((item) => CartItem.fromMap(item))
          .toList(),
    );
  }
}