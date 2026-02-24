import 'dart:convert';
import 'package:ecommerce_desktop/models/restaurant_gallery_model.dart';
import 'package:ecommerce_desktop/providers/auth_provider.dart';
import 'package:http/http.dart' as http;

class RestaurantGalleryProvider {
  static String get _baseUrl =>
      const String.fromEnvironment("baseUrl", defaultValue: "http://localhost:5121/api/");

  Map<String, String> _headers() {
    final t = AuthProvider.token;
    final auth = t != null && t.isNotEmpty
        ? "Bearer $t"
        : "Basic ${base64Encode(utf8.encode('${AuthProvider.username ?? ""}:${AuthProvider.password ?? ""}'))}";
    return {"Content-Type": "application/json", "Authorization": auth};
  }

  Future<List<RestaurantGalleryItem>> getByRestaurant(int restaurantId) async {
    try {
      final url = Uri.parse("${_baseUrl}RestaurantGalleries?restaurantId=$restaurantId");
      final res = await http.get(url, headers: _headers());
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final data = jsonDecode(res.body);
        if (data is List) {
          return data.map((e) => RestaurantGalleryItem.fromJson(e as Map<String, dynamic>)).toList();
        }
      }
    } catch (e) {
      rethrow;
    }
    return [];
  }

  Future<RestaurantGalleryItem> insert({
    required int restaurantId,
    required String imageUrl,
    String? imageType,
    int displayOrder = 0,
  }) async {
    final url = Uri.parse("${_baseUrl}RestaurantGalleries");
    final body = jsonEncode({
      'restaurantId': restaurantId,
      'imageUrl': imageUrl,
      'imageType': imageType,
      'displayOrder': displayOrder,
    });
    final res = await http.post(url, headers: _headers(), body: body);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data = jsonDecode(res.body);
      return RestaurantGalleryItem.fromJson(data as Map<String, dynamic>);
    }
    throw Exception('Failed to add gallery image: ${res.statusCode}');
  }

  Future<void> delete(int id) async {
    final url = Uri.parse("${_baseUrl}RestaurantGalleries/$id");
    final res = await http.delete(url, headers: _headers());
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Failed to delete gallery image: ${res.statusCode}');
    }
  }
}
