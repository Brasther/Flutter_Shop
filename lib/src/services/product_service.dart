// lib/src/services/product_service.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';

class ProductService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _collection = 'products';

  // 1. OBTENER PRODUCTOS
  Future<List<Product>> getProducts() async {
    try {
      final snapshot = await _db.collection(_collection).get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Product.fromJson(data);
      }).toList();
    } catch (e) {
      print('Error al traer productos: $e');
      return [];
    }
  }

  // 2. BUSCADOR
  Future<List<Product>> searchProducts(String query) async {
    final allProducts = await getProducts();
    return allProducts.where((p) => 
      p.name.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }

  // --- HERRAMIENTA DE CARGA DE DATOS (CON IMÁGENES NUEVAS) ---
  Future<void> uploadMockData() async {
    final List<Product> mockProducts = [
      const Product(
        id: 'p_nike',
        name: 'Nike Air Jordan',
        description: 'Zapatillas icónicas de baloncesto con estilo urbano.',
        price: 120.00,
        // Imagen estable de Zapatillas
        imageUrl: 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?auto=format&fit=crop&w=500&q=60',
        category: 'Calzado',
      ),
      const Product(
        id: 'p_macbook',
        name: 'MacBook Pro M3',
        description: 'Potencia extrema para profesionales creativos.',
        price: 2500.00,
        // Imagen estable de Laptop (Esta era la que fallaba antes)
        imageUrl: 'https://images.unsplash.com/photo-1496181133206-80ce9b88a853?auto=format&fit=crop&w=500&q=60',
        category: 'Tecnología',
      ),
      const Product(
        id: 'p_cafetera',
        name: 'Cafetera Italiana',
        description: 'El auténtico sabor del café espresso en tu casa.',
        price: 35.50,
        // Imagen estable de Cafetera
        imageUrl: 'https://images.unsplash.com/photo-1520978294860-c2358820e5ca?auto=format&fit=crop&w=500&q=60',
        category: 'Hogar',
      ),
       const Product(
        id: 'p_sony',
        name: 'Auriculares Sony',
        description: 'Cancelación de ruido líder en la industria.',
        price: 299.99,
        // Imagen estable de Audífonos
        imageUrl: 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?auto=format&fit=crop&w=500&q=60',
        category: 'Audio',
      ),
    ];

    for (var product in mockProducts) {
      // Usamos .set para sobrescribir y corregir los datos viejos
      await _db.collection(_collection).doc(product.id).set(product.toMap());
    }
    print(' IMÁGENES CORREGIDAS Y SUBIDAS A FIREBASE');
  }
}