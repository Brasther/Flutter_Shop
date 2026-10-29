// lib/src/models/product.dart

class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String category;
  final int stock;
  final bool active;
  final Map<String, List<String>> variantOptions;

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.category,
    this.stock = 99,
    this.active = true,
    this.variantOptions = const {},
  });

  // --- AGREGAR ESTE MÉTODO ---
  // Convierte el objeto a un mapa compatible con Firebase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'category': category,
      'stock': stock,
      'active': active,
      'variantOptions': variantOptions,
    };
  }

  // (El factory fromJson ya lo tenías, déjalo igual)
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? 'Producto').toString(),
      description: (json['description'] ?? '').toString(),
      price: (json['price'] as num? ?? 0).toDouble(),
      imageUrl: (json['imageUrl'] ?? '').toString(),
      category: (json['category'] ?? 'General').toString(),
      // Older Firestore records without inventory must not appear purchasable.
      stock: (json['stock'] as num? ?? 0).toInt(),
      active: json['active'] is bool ? json['active'] as bool : true,
      variantOptions: _parseVariants(json['variantOptions']),
    );
  }

  static Map<String, List<String>> _parseVariants(Object? raw) {
    if (raw is! Map) return const {};
    return raw.map((key, value) => MapEntry(
          key.toString(),
          value is Iterable
              ? value.map((option) => option.toString()).toList()
              : <String>[],
        ));
  }
}
