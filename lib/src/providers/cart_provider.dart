// lib/src/providers/cart_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/cart_item.dart';

class CartProvider extends ChangeNotifier {
  Map<String, CartItem> _items = {};
  static const String _storageKey = 'cart_items'; // Clave para guardar en disco

  // Constructor: Intenta cargar datos apenas se inicia la app
  CartProvider() {
    _loadFromStorage();
  }

  Map<String, CartItem> get items => {..._items};

  int get itemCount => _items.length;

  double get totalAmount {
    var total = 0.0;
    _items.forEach((key, cartItem) {
      total += cartItem.price * cartItem.quantity;
    });
    return total;
  }

  // --- ACCIONES ---

  void addItem(String productId, double price, String title, String imageUrl) {
    print('🛒 PROVIDER: Intentando agregar $title'); // LOG DE DEBUG

    if (_items.containsKey(productId)) {
      // Actualizar cantidad
      _items.update(
        productId,
        (existingItem) => CartItem(
          id: existingItem.id,
          title: existingItem.title,
          price: existingItem.price,
          imageUrl: existingItem.imageUrl,
          quantity: existingItem.quantity + 1,
        ),
      );
      print('🛒 PROVIDER: Cantidad actualizada. Total items únicos: ${_items.length}');
    } else {
      // Nuevo Item
      _items.putIfAbsent(
        productId,
        () => CartItem(
          id: DateTime.now().toString(),
          title: title,
          price: price,
          quantity: 1,
          imageUrl: imageUrl,
        ),
      );
      print('🛒 PROVIDER: Nuevo producto creado. Total items únicos: ${_items.length}');
    }
    
    notifyListeners(); // Actualiza la UI
    _saveToStorage();  // Guarda en disco
  }

  void removeItem(String productId) {
    _items.remove(productId);
    notifyListeners();
    _saveToStorage();
  }

  void clear() {
    _items = {};
    notifyListeners();
    _saveToStorage();
  }

  // --- PERSISTENCIA (GUARDAR Y CARGAR) ---

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Convertimos el mapa de objetos a texto JSON
      final String encodedData = json.encode(
        _items.map((key, item) => MapEntry(key, item.toMap())),
      );
      await prefs.setString(_storageKey, encodedData);
      print('💾 PROVIDER: Datos guardados en disco correctamente.');
    } catch (error) {
      print('❌ ERROR AL GUARDAR: $error');
    }
  }

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!prefs.containsKey(_storageKey)) return;

      final String? extractedData = prefs.getString(_storageKey);
      if (extractedData == null) return;

      final Map<String, dynamic> decodedData = json.decode(extractedData);
      
      _items = decodedData.map((key, itemData) {
        return MapEntry(key, CartItem.fromMap(itemData));
      });
      
      print('📂 PROVIDER: Datos cargados del disco. Items recuperados: ${_items.length}');
      notifyListeners();
    } catch (error) {
      print('❌ ERROR AL CARGAR: $error');
    }
  }
}