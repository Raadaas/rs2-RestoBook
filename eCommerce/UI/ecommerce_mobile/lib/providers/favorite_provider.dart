import 'dart:convert';
import 'package:ecommerce_mobile/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoriteProvider with ChangeNotifier {
  List<int> _ids = [];
  bool _loaded = false;

  List<int> get ids => List.unmodifiable(_ids);
  int get count => _ids.length;
  bool get isLoaded => _loaded;

  String get _key =>
      'fav_restaurant_ids_${AuthProvider.userId ?? 0}';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      try {
        final list = jsonDecode(raw) as List<dynamic>?;
        _ids = list?.map((e) => (e as num).toInt()).toList() ?? [];
      } catch (_) {
        _ids = [];
      }
    } else {
      _ids = [];
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(_ids));
    notifyListeners();
  }

  Future<void> add(int restaurantId) async {
    if (!_loaded) await load();
    if (_ids.contains(restaurantId)) return;
    _ids.add(restaurantId);
    await _save();
  }

  Future<void> remove(int restaurantId) async {
    if (!_loaded) await load();
    _ids.remove(restaurantId);
    await _save();
  }

  Future<void> toggle(int restaurantId) async {
    if (!_loaded) await load();
    if (_ids.contains(restaurantId)) {
      _ids.remove(restaurantId);
    } else {
      _ids.add(restaurantId);
    }
    await _save();
  }

  Future<bool> contains(int restaurantId) async {
    if (!_loaded) await load();
    return _ids.contains(restaurantId);
  }
}
