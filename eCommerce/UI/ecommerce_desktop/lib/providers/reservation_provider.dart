import 'dart:convert';
import 'package:ecommerce_desktop/providers/auth_provider.dart';
import 'package:ecommerce_desktop/providers/base_provider.dart';
import 'package:ecommerce_desktop/providers/validation_exception.dart';
import 'package:http/http.dart' as http;

class ReservationProvider extends BaseProvider {
  ReservationProvider() : super("reservations");

  @override
  fromJson(data) {
    return data;
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
      var decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['data'] != null) {
        return decoded['data'] as Map<String, dynamic>;
      }
      return decoded is Map ? Map<String, dynamic>.from(decoded) : {'id': null};
    }
    if (response.statusCode == 400) {
      try {
        final err = jsonDecode(response.body);
        if (err is Map && err['errors'] != null && err['errors'] is Map) {
          final errors = <String, List<String>>{};
          (err['errors'] as Map).forEach((key, value) {
            if (value is List) {
              errors[key.toString()] = value.map((e) => e.toString()).toList();
            } else if (value is String) {
              errors[key.toString()] = [value];
            }
          });
          throw ValidationException(errors);
        }
        final msg = err is Map && err['message'] != null ? err['message'] as String : response.body;
        throw Exception(msg);
      } catch (e) {
        if (e is ValidationException) rethrow;
        throw Exception(e.toString());
      }
    }
    throw Exception('Failed to create reservation. Please try again.');
  }
}

