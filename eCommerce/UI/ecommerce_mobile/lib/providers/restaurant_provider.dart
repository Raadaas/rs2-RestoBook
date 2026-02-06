import 'dart:convert';
import 'package:ecommerce_mobile/model/restaurant.dart';
import 'package:ecommerce_mobile/providers/base_provider.dart';
import 'package:ecommerce_mobile/model/search_result.dart';
import 'package:http/http.dart' as http;

class RestaurantProvider extends BaseProvider<Restaurant> {
  RestaurantProvider() : super("restaurants");

  @override
  Restaurant fromJson(dynamic json) {
    return Restaurant.fromJson(json);
  }

  Future<Restaurant?> getById(int id) async {
    try {
      final baseUrl = const String.fromEnvironment(
        "baseUrl",
        defaultValue: "http://10.0.2.2:5121/api/",
      );
      final url = Uri.parse("${baseUrl}restaurants/$id");
      final headers = createHeaders();

      final response = await http.get(url, headers: headers);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        return Restaurant.fromJson(data);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception("Failed to get restaurant: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error getting restaurant: $e");
    }
  }

  /// Recommended restaurants for the current user (content-based). Requires auth. Returns [] if 401 or error.
  Future<List<Restaurant>> getRecommended({int count = 10}) async {
    try {
      final baseUrl = const String.fromEnvironment(
        "baseUrl",
        defaultValue: "http://10.0.2.2:5121/api/",
      );
      final url = Uri.parse("${baseUrl}restaurants/recommended").replace(queryParameters: {'count': count.toString()});
      final headers = createHeaders();
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 401) return [];
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as List;
        return data.map((e) => Restaurant.fromJson(e as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }
}
