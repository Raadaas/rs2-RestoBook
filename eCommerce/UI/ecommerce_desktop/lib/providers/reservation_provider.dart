import 'dart:convert';
import 'package:ecommerce_desktop/providers/base_provider.dart';
import 'package:http/http.dart' as http;
import 'package:ecommerce_desktop/providers/auth_provider.dart';

class ReservationProvider extends BaseProvider {
  ReservationProvider() : super("reservations");

  @override
  fromJson(data) {
    return data; // Return raw data for now
  }

  Future<Map<String, dynamic>> createReservation(Map<String, dynamic> request) async {
    final baseUrl = const String.fromEnvironment(
      "baseUrl",
      defaultValue: "http://localhost:5121/api/"
    );
    var url = "${baseUrl}reservations";
    var uri = Uri.parse(url);
    var headers = createHeaders();
    var body = jsonEncode(request);

    var response = await http.post(uri, headers: headers, body: body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      var data = jsonDecode(response.body);
      return data;
    } else {
      var errorBody = response.body;
      throw Exception("Failed to create reservation: ${response.statusCode} - $errorBody");
    }
  }
}

