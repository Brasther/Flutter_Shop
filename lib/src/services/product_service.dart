import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';

class ProductService {
  ProductService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;
  static const String _collection = 'products';

  static const demoProducts = <Product>[
    Product(
        id: 'demo-shoes',
        name: 'Urban Runner',
        description: 'Zapatilla urbana liviana para todos los días.',
        price: 64.90,
        imageUrl:
            'https://images.unsplash.com/photo-1542291026-7eec264c27ff?auto=format&fit=crop&w=900&q=85',
        category: 'Calzado',
        stock: 12,
        variantOptions: {
          'Talla': ['38', '39', '40', '41', '42'],
          'Color': ['Rojo', 'Negro']
        }),
    Product(
        id: 'demo-headphones',
        name: 'Studio Headphones',
        description: 'Audífonos inalámbricos con sonido envolvente.',
        price: 89.00,
        imageUrl:
            'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?auto=format&fit=crop&w=900&q=85',
        category: 'Audio',
        stock: 8,
        variantOptions: {
          'Color': ['Negro', 'Blanco']
        }),
    Product(
        id: 'demo-watch',
        name: 'Minimal Watch',
        description: 'Reloj minimalista con correa intercambiable.',
        price: 119.00,
        imageUrl:
            'https://images.unsplash.com/photo-1523275335684-37898b6baf30?auto=format&fit=crop&w=900&q=85',
        category: 'Accesorios',
        stock: 5),
    Product(
        id: 'demo-camera',
        name: 'Instant Camera',
        description: 'Cámara compacta para capturar momentos especiales.',
        price: 149.50,
        imageUrl:
            'https://images.unsplash.com/photo-1516035069371-29a1b244cc32?auto=format&fit=crop&w=900&q=85',
        category: 'Tecnología',
        stock: 4),
    Product(
        id: 'demo-backpack',
        name: 'Everyday Backpack',
        description: 'Mochila resistente con espacio para portátil.',
        price: 54.00,
        imageUrl:
            'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?auto=format&fit=crop&w=900&q=85',
        category: 'Accesorios',
        stock: 20),
    Product(
        id: 'demo-coffee',
        name: 'Coffee Press',
        description: 'Prensa francesa de vidrio para café de especialidad.',
        price: 32.00,
        imageUrl:
            'https://images.unsplash.com/photo-1517668808822-9ebb02f2a0e6?auto=format&fit=crop&w=900&q=85',
        category: 'Hogar',
        stock: 15),
  ];

  Future<List<Product>> getProducts() async {
    try {
      final snapshot = await _db.collection(_collection).get();
      if (snapshot.docs.isEmpty) return demoProducts;
      return snapshot.docs
          .map((doc) {
            return Product.fromJson({...doc.data(), 'id': doc.id});
          })
          .where((product) => product.active && product.stock > 0)
          .toList();
    } on FirebaseException {
      return demoProducts;
    }
  }

  Future<List<Product>> getManagedProducts() async {
    final snapshot = await _db.collection(_collection).get();
    return snapshot.docs
        .map((doc) => Product.fromJson({...doc.data(), 'id': doc.id}))
        .toList();
  }

  Future<List<Product>> searchProducts(String query) async {
    final normalized = query.trim().toLowerCase();
    final products = await getProducts();
    if (normalized.isEmpty) return products;
    return products
        .where((product) =>
            product.name.toLowerCase().contains(normalized) ||
            product.description.toLowerCase().contains(normalized) ||
            product.category.toLowerCase().contains(normalized))
        .toList();
  }

  Future<String> saveProduct(Product product) async {
    final collection = _db.collection(_collection);
    final ref =
        product.id.isEmpty ? collection.doc() : collection.doc(product.id);
    await ref
        .set({...product.toMap(), 'active': true}, SetOptions(merge: true));
    return ref.id;
  }

  Future<void> deleteProduct(String productId) async {
    await _db.collection(_collection).doc(productId).delete();
  }
}
