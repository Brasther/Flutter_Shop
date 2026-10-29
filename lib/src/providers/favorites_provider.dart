import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesProvider extends ChangeNotifier {
  FavoritesProvider() {
    ready = _load();
  }

  static const _storageKey = 'favorite_products';
  late final Future<void> ready;
  final Set<String> _ids = {};
  Set<String> get ids => Set.unmodifiable(_ids);
  bool contains(String id) => _ids.contains(id);

  void toggle(String id) {
    if (!_ids.add(id)) _ids.remove(id);
    notifyListeners();
    _save();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _ids.addAll(prefs.getStringList(_storageKey) ?? const []);
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_storageKey, _ids.toList());
  }
}
