import 'dart:convert';

import 'package:ecommerce_desktop/models/notification_model.dart';
import 'package:ecommerce_desktop/providers/auth_provider.dart';
import 'package:http/http.dart' as http;

class NotificationService {
  static String get baseUrl {
    return const String.fromEnvironment(
      'baseUrl',
      defaultValue: 'http://localhost:5121/api/',
    );
  }

  static Map<String, String> _createHeaders() {
    final t = AuthProvider.token;
    final auth = t != null && t.isNotEmpty
        ? 'Bearer $t'
        : 'Basic ${base64Encode(utf8.encode('${AuthProvider.username ?? ""}:${AuthProvider.password ?? ""}'))}';
    return {'Content-Type': 'application/json', 'Authorization': auth};
  }

  static Future<List<NotificationModel>> getMyNotifications() async {
    final uri = Uri.parse('${baseUrl}notifications');
    final response = await http.get(uri, headers: _createHeaders());
    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List;
      return list.map((e) => NotificationModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  static Future<void> markAsRead(int id) async {
    final uri = Uri.parse('${baseUrl}notifications/$id/read');
    await http.patch(uri, headers: _createHeaders());
  }
}
