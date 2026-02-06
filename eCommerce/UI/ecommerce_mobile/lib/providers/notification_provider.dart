import 'dart:convert';

import 'package:ecommerce_mobile/model/notification.dart';
import 'package:ecommerce_mobile/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class NotificationProvider with ChangeNotifier {
  static String get _baseUrl {
    return const String.fromEnvironment(
      'baseUrl',
      defaultValue: 'http://10.0.2.2:5121/api/',
    );
  }

  Map<String, String> _createHeaders() {
    final username = AuthProvider.username ?? '';
    final password = AuthProvider.password ?? '';
    final basicAuth = 'Basic ${base64Encode(utf8.encode('$username:$password'))}';
    return {
      'Content-Type': 'application/json',
      'Authorization': basicAuth,
    };
  }

  List<NotificationModel> _items = [];
  bool _loading = false;
  String? _error;

  List<NotificationModel> get items => List.unmodifiable(_items);
  bool get loading => _loading;
  String? get error => _error;
  int get unreadCount => _items.where((n) => !n.isRead).length;

  Future<void> load() async {
    if (AuthProvider.userId == null) {
      _items = [];
      return;
    }
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final uri = Uri.parse('${_baseUrl}notifications');
      final response = await http.get(uri, headers: _createHeaders());

      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List;
        _items = list.map((e) => NotificationModel.fromJson(e as Map<String, dynamic>)).toList();
      } else {
        _error = 'Failed to load notifications';
        _items = [];
      }
    } catch (e) {
      _error = e.toString();
      _items = [];
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(int id) async {
    try {
      final uri = Uri.parse('${_baseUrl}notifications/$id/read');
      final response = await http.patch(uri, headers: _createHeaders());

      if (response.statusCode == 204) {
        final index = _items.indexWhere((n) => n.id == id);
        if (index >= 0) {
          _items[index] = NotificationModel(
            id: _items[index].id,
            userId: _items[index].userId,
            type: _items[index].type,
            title: _items[index].title,
            message: _items[index].message,
            relatedReservationId: _items[index].relatedReservationId,
            isRead: true,
            sentAt: _items[index].sentAt,
            readAt: DateTime.now(),
          );
          notifyListeners();
        }
      }
    } catch (_) {}
  }
}
