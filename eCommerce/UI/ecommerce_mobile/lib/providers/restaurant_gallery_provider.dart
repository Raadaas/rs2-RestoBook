import 'dart:convert';
import 'package:ecommerce_mobile/model/restaurant_gallery_item.dart';
import 'package:ecommerce_mobile/providers/auth_provider.dart';
import 'package:http/http.dart' as http;

class RestaurantGalleryProvider {
  static String get _baseUrl =>
      const String.fromEnvironment("baseUrl", defaultValue: "http://10.0.2.2:5121/api/");

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
          return data
              .map((e) => RestaurantGalleryItem.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (_) {}
    return [];
  }
}
