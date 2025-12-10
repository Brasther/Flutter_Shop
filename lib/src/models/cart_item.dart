// lib/src/models/cart_item.dart
import 'dart:convert';

class CartItem {
  final String id;
  final String title;
  final int quantity;
  final double price;
  final String imageUrl;

  CartItem({
    required this.id,
    required this.title,
    required this.quantity,
    required this.price,
    required this.imageUrl,
  });

  // Convertir a Mapa (Para guardar)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'quantity': quantity,
      'price': price,
      'imageUrl': imageUrl,
    };
  }

  // Crear desde Mapa (Para cargar)
  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      id: map['id'],
      title: map['title'],
      quantity: map['quantity'],
      // Esto previene errores si el precio viene como int o double
      price: (map['price'] as num).toDouble(), 
      imageUrl: map['imageUrl'],
    );
  }

  String toJson() => json.encode(toMap());
  
  factory CartItem.fromJson(String source) => CartItem.fromMap(json.decode(source));
}