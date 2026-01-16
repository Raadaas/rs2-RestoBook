import 'dart:convert';
import 'package:ecommerce_desktop/models/city_model.dart';
import 'package:ecommerce_desktop/providers/base_provider.dart';
import 'package:ecommerce_desktop/model/search_result.dart';
import 'package:http/http.dart' as http;

class CityProvider extends BaseProvider<City> {
  CityProvider() : super("cities");

  @override
  City fromJson(dynamic json) {
    return City.fromJson(json);
  }

  Future<City?> getById(int id) async {
    try {
      final baseUrl = const String.fromEnvironment(
        "baseUrl",
        defaultValue: "http://localhost:5121/api/",
      );
      final url = Uri.parse("${baseUrl}cities/$id");
      final headers = createHeaders();

      final response = await http.get(url, headers: headers);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        return City.fromJson(data);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception("Failed to get city: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error getting city: $e");
    }
  }
}
