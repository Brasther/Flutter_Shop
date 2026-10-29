import 'package:cloud_firestore/cloud_firestore.dart';
import 'cart_item.dart';

class Order {
  const Order({
    required this.id,
    required this.amount,
    required this.products,
    required this.dateTime,
    required this.status,
    this.userId = '',
    this.shipping = const {},
    this.subtotal = 0,
    this.discount = 0,
    this.couponCode,
    this.email = '',
  });

  final String id;
  final double amount;
  final List<CartItem> products;
  final DateTime dateTime;
  final String status;
  final String userId;
  final Map<String, dynamic> shipping;
  final double subtotal;
  final double discount;
  final String? couponCode;
  final String email;

  factory Order.fromMap(Map<String, dynamic> map, String docId) {
    final rawDate = map['dateTime'];
    return Order(
      id: docId,
      amount: (map['amount'] as num? ?? 0).toDouble(),
      dateTime: rawDate is Timestamp
          ? rawDate.toDate()
          : DateTime.tryParse('$rawDate') ?? DateTime.now(),
      status: (map['status'] ?? 'paid').toString(),
      userId: (map['userId'] ?? '').toString(),
      shipping: map['shipping'] is Map
          ? Map<String, dynamic>.from(map['shipping'] as Map)
          : const {},
      subtotal:
          (map['subtotal'] as num? ?? map['amount'] as num? ?? 0).toDouble(),
      discount: (map['discount'] as num? ?? 0).toDouble(),
      couponCode: map['couponCode']?.toString(),
      email: (map['email'] ?? '').toString(),
      products: ((map['products'] as List<dynamic>?) ?? const [])
          .map((item) =>
              CartItem.fromMap(Map<String, dynamic>.from(item as Map)))
          .toList(),
    );
  }
}
