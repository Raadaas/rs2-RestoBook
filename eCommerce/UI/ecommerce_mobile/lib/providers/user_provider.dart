import 'dart:convert';

import 'package:ecommerce_mobile/model/user.dart';
import 'package:ecommerce_mobile/providers/auth_provider.dart';
import 'package:ecommerce_mobile/providers/base_provider.dart';
import 'package:http/http.dart' as http;

class UserProvider extends BaseProvider<User> {
  UserProvider() : super('users');

  @override
  User fromJson(dynamic json) {
    return User.fromJson(json as Map<String, dynamic>);
  }

  Future<User?> getById(int id) async {
    try {
      final baseUrl = const String.fromEnvironment(
        'baseUrl',
        defaultValue: 'http://10.0.2.2:5121/api/',
      );
      final url = Uri.parse('${baseUrl}users/$id');
      final headers = createHeaders();
      final response = await http.get(url, headers: headers);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return User.fromJson(data);
      }
      if (response.statusCode == 404) return null;
      throw Exception('Failed to get user: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error getting user: $e');
    }
  }
}
