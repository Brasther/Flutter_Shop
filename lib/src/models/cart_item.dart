// lib/src/models/cart_item.dart
import 'dart:convert';

class CartItem {
  final String id;
  final String productId;
  final Map<String, String> variants;
  final String title;
  final int quantity;
  final double price;
  final String imageUrl;
  final int availableStock;

  CartItem({
    required this.id,
    String? productId,
    this.variants = const {},
    required this.title,
    required this.quantity,
    required this.price,
    required this.imageUrl,
    this.availableStock = 99,
  }) : productId = productId ?? id;

  String get variantLabel => variants.entries
      .map((entry) => '${entry.key}: ${entry.value}')
      .join(' · ');

  // Convertir a Mapa (Para guardar)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'variants': variants,
      'title': title,
      'quantity': quantity,
      'price': price,
      'imageUrl': imageUrl,
      'availableStock': availableStock,
    };
  }

  // Crear desde Mapa (Para cargar)
  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      id: map['id'],
      productId: (map['productId'] ?? map['id']).toString(),
      variants: map['variants'] is Map
          ? Map<String, String>.from(map['variants'] as Map)
          : const {},
      title: map['title'],
      quantity: map['quantity'],
      // Esto previene errores si el precio viene como int o double
      price: (map['price'] as num).toDouble(),
      imageUrl: map['imageUrl'],
      availableStock: (map['availableStock'] as num?)?.toInt() ?? 99,
    );
  }

  String toJson() => json.encode(toMap());

  factory CartItem.fromJson(String source) =>
      CartItem.fromMap(json.decode(source));
}
