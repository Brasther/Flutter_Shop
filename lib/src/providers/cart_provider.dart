import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cart_item.dart';

class CartProvider extends ChangeNotifier {
  CartProvider() {
    ready = _loadInto();
  }

  static const _storageKey = 'cart_items';
  final Map<String, CartItem> _items = {};
  late final Future<void> ready;
  Map<String, CartItem> get items => Map.unmodifiable(_items);
  int get itemCount =>
      _items.values.fold(0, (sum, item) => sum + item.quantity);
  double get totalAmount =>
      _items.values.fold(0, (sum, item) => sum + item.price * item.quantity);

  bool addItem(String productId, double price, String title, String imageUrl,
      {int stock = 99, Map<String, String> variants = const {}}) {
    final variantKey = variants.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final encodedVariant = base64Url.encode(utf8.encode(json
        .encode(variantKey.map((entry) => [entry.key, entry.value]).toList())));
    final lineId =
        variantKey.isEmpty ? productId : '$productId::$encodedVariant';
    final current = _items[lineId];
    final productQuantity = _items.values
        .where((item) => item.productId == productId)
        .fold<int>(0, (sum, item) => sum + item.quantity);
    if (productQuantity >= stock) return false;
    _items[lineId] = CartItem(
      id: lineId,
      productId: productId,
      variants: Map.unmodifiable(variants),
      title: title,
      price: price,
      imageUrl: imageUrl,
      quantity: (current?.quantity ?? 0) + 1,
      availableStock: stock,
    );
    notifyListeners();
    _save();
    return true;
  }

  void setQuantity(String productId, int quantity) {
    final item = _items[productId];
    if (item == null) return;
    if (quantity <= 0) {
      _items.remove(productId);
    } else {
      final otherQuantity = _items.values
          .where((candidate) =>
              candidate.productId == item.productId && candidate.id != item.id)
          .fold<int>(0, (sum, candidate) => sum + candidate.quantity);
      final maxQuantity = (item.availableStock - otherQuantity).clamp(1, 99);
      _items[productId] = CartItem(
        id: item.id,
        productId: item.productId,
        variants: item.variants,
        title: item.title,
        price: item.price,
        imageUrl: item.imageUrl,
        quantity: quantity.clamp(1, maxQuantity).toInt(),
        availableStock: item.availableStock,
      );
    }
    notifyListeners();
    _save();
  }

  bool canIncrement(String lineId) {
    final item = _items[lineId];
    if (item == null) return false;
    final total = _items.values
        .where((candidate) => candidate.productId == item.productId)
        .fold<int>(0, (sum, candidate) => sum + candidate.quantity);
    return total < item.availableStock;
  }

  void removeItem(String productId) {
    _items.remove(productId);
    notifyListeners();
    _save();
  }

  Future<void> clear() async {
    _items.clear();
    notifyListeners();
    await _save();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final value =
        json.encode(_items.map((id, item) => MapEntry(id, item.toMap())));
    await prefs.setString(_storageKey, value);
  }

  Future<void> _loadInto() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null) return;
    try {
      final decoded = json.decode(raw) as Map<String, dynamic>;
      _items
        ..clear()
        ..addAll(decoded.map((id, data) => MapEntry(
            id, CartItem.fromMap(Map<String, dynamic>.from(data as Map)))));
      notifyListeners();
    } on FormatException {
      await prefs.remove(_storageKey);
    } on TypeError {
      await prefs.remove(_storageKey);
    }
  }
}
