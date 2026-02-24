import 'dart:convert';
import 'package:ecommerce_desktop/models/dashboard_models.dart';
import 'package:ecommerce_desktop/models/reservation_model.dart';
import 'package:ecommerce_desktop/providers/auth_provider.dart';
import 'package:http/http.dart' as http;

class DashboardService {
  static String get baseUrl {
    return const String.fromEnvironment(
      "baseUrl",
      defaultValue: "http://localhost:5121/api/",
    );
  }

  static Map<String, String> _createHeaders() {
    final t = AuthProvider.token;
    final auth = t != null && t.isNotEmpty
        ? "Bearer $t"
        : "Basic ${base64Encode(utf8.encode('${AuthProvider.username ?? ""}:${AuthProvider.password ?? ""}'))}";
    return {"Content-Type": "application/json", "Authorization": auth};
  }

  static String _jwtLog() {
    final t = AuthProvider.token;
    if (t == null || t.isEmpty) return '(none)';
    final preview = t.length > 40 ? '${t.substring(0, 40)}...' : t;
    return 'Bearer $preview (length: ${t.length})';
  }

  static Future<TodayReservations> getTodayReservations(int restaurantId) async {
    final url = Uri.parse("${baseUrl}reservations/today?restaurantId=$restaurantId");
    print("Requesting: $url");
    print("JWT: ${_jwtLog()}");
    final response = await http.get(url, headers: _createHeaders());

    print("Response status: ${response.statusCode}");
    print("Response body: ${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return TodayReservations.fromJson(data);
    } else {
      throw Exception("Failed to load today's reservations: ${response.statusCode} - ${response.body}");
    }
  }

  static Future<TodayReservations> getAllReservations(int restaurantId) async {
    final url = Uri.parse("${baseUrl}reservations/all?restaurantId=$restaurantId");
    print("Requesting: $url");
    print("JWT: ${_jwtLog()}");
    final response = await http.get(url, headers: _createHeaders());

    print("Response status: ${response.statusCode}");
    print("Response body: ${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return TodayReservations.fromJson(data);
    } else {
      throw Exception("Failed to load all reservations: ${response.statusCode} - ${response.body}");
    }
  }

  static Future<OccupancyData> getCurrentOccupancy(int restaurantId) async {
    final url = Uri.parse("${baseUrl}tables/occupancy?restaurantId=$restaurantId");
    print("Requesting: $url");
    print("JWT: ${_jwtLog()}");
    final response = await http.get(url, headers: _createHeaders());

    print("Response status: ${response.statusCode}");
    print("Response body: ${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return OccupancyData.fromJson(data);
    } else {
      throw Exception("Failed to load occupancy: ${response.statusCode} - ${response.body}");
    }
  }

  static Future<List<HourlyData>> getHourlyOccupancy(int restaurantId) async {
    final url = Uri.parse("${baseUrl}analytics/hourly?restaurantId=$restaurantId");
    print("Requesting: $url");
    print("JWT: ${_jwtLog()}");
    final response = await http.get(url, headers: _createHeaders());

    print("Response status: ${response.statusCode}");
    print("Response body: ${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data.map((e) => HourlyData.fromJson(e)).toList();
      }
      return [];
    } else {
      throw Exception("Failed to load hourly occupancy: ${response.statusCode} - ${response.body}");
    }
  }

  static Future<List<TableUsageData>> getTopTables(int restaurantId, {int count = 3, bool leastUsed = false}) async {
    final url = Uri.parse("${baseUrl}analytics/top-tables?restaurantId=$restaurantId&topCount=$count&leastUsed=$leastUsed");
    print("Requesting: $url");
    print("JWT: ${_jwtLog()}");
    final response = await http.get(url, headers: _createHeaders());
    print("Response status: ${response.statusCode}");
    print("Response body: ${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data.map((e) => TableUsageData.fromJson(e)).toList();
      }
      return [];
    } else {
      throw Exception("Failed to load top tables: ${response.statusCode} - ${response.body}");
    }
  }

  static Future<ReservationsSummary> getReservationsSummary(int restaurantId) async {
    final url = Uri.parse("${baseUrl}analytics/reservations-summary?restaurantId=$restaurantId");
    print("Requesting: $url");
    print("JWT: ${_jwtLog()}");
    final response = await http.get(url, headers: _createHeaders());
    print("Response status: ${response.statusCode}");
    print("Response body: ${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return ReservationsSummary.fromJson(data);
    } else {
      throw Exception("Failed to load reservations summary: ${response.statusCode} - ${response.body}");
    }
  }

  static Future<AverageRating> getAverageRating(int restaurantId) async {
    final url = Uri.parse("${baseUrl}analytics/average-rating?restaurantId=$restaurantId");
    print("Requesting: $url");
    print("JWT: ${_jwtLog()}");
    final response = await http.get(url, headers: _createHeaders());
    print("Response status: ${response.statusCode}");
    print("Response body: ${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return AverageRating.fromJson(data);
    } else {
      throw Exception("Failed to load average rating: ${response.statusCode} - ${response.body}");
    }
  }

  static Future<List<WeeklyOccupancyData>> getWeeklyOccupancy(int restaurantId) async {
    final url = Uri.parse("${baseUrl}analytics/weekly-occupancy?restaurantId=$restaurantId");
    print("Requesting: $url");
    print("JWT: ${_jwtLog()}");
    final response = await http.get(url, headers: _createHeaders());
    print("Response status: ${response.statusCode}");
    print("Response body: ${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data.map((e) => WeeklyOccupancyData.fromJson(e)).toList();
      }
      return [];
    } else {
      throw Exception("Failed to load weekly occupancy: ${response.statusCode} - ${response.body}");
    }
  }

  static Future<List<Reservation>> getTodayReservationsByState(int restaurantId, String state) async {
    // Map string state to API state parameter
    String apiState = 'Requested'; // Default
    if (state == 'Pending') {
      apiState = 'Requested';
    } else if (state == 'Confirmed') {
      apiState = 'Confirmed';
    } else if (state == 'Completed') {
      apiState = 'Completed';
    }
    
    final url = Uri.parse("${baseUrl}reservations/today/by-state?state=$apiState&restaurantId=$restaurantId");
    print("Requesting: $url");
    print("JWT: ${_jwtLog()}");
    final response = await http.get(url, headers: _createHeaders());
    print("Response status: ${response.statusCode}");
    print("Response body: ${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data.map((e) => Reservation.fromJson(e)).toList();
      }
      return [];
    } else {
      throw Exception("Failed to load reservations: ${response.statusCode} - ${response.body}");
    }
  }

  static Future<List<Reservation>> getAllReservationsByState(int restaurantId, String state) async {
    // Map string state to API state parameter
    String apiState = 'Requested'; // Default
    if (state == 'Pending') {
      apiState = 'Requested';
    } else if (state == 'Confirmed') {
      apiState = 'Confirmed';
    } else if (state == 'Completed') {
      apiState = 'Completed';
    } else if (state == 'Cancelled') {
      apiState = 'Cancelled';
    } else if (state == 'Expired') {
      apiState = 'Expired';
    }
    
    final url = Uri.parse("${baseUrl}reservations/all/by-state?state=$apiState&restaurantId=$restaurantId");
    print("Requesting: $url");
    print("JWT: ${_jwtLog()}");
    final response = await http.get(url, headers: _createHeaders());
    print("Response status: ${response.statusCode}");
    print("Response body: ${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data.map((e) => Reservation.fromJson(e)).toList();
      }
      return [];
    } else {
      throw Exception("Failed to load reservations: ${response.statusCode} - ${response.body}");
    }
  }

  static Future<Reservation> confirmReservation(int id) async {
    final url = Uri.parse("${baseUrl}reservations/$id/confirm");
    print("Requesting: $url");
    print("JWT: ${_jwtLog()}");
    final response = await http.post(url, headers: _createHeaders());
    print("Response status: ${response.statusCode}");
    print("Response body: ${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Reservation.fromJson(data);
    } else {
      throw Exception("Failed to confirm reservation: ${response.statusCode} - ${response.body}");
    }
  }

  static Future<Reservation> cancelReservation(int id, {String? reason}) async {
    final url = Uri.parse("${baseUrl}reservations/$id/cancel");
    print("Requesting: $url");
    print("JWT: ${_jwtLog()}");
    final body = reason != null ? jsonEncode({'reason': reason}) : '{}';
    final response = await http.post(url, headers: _createHeaders(), body: body);
    print("Response status: ${response.statusCode}");
    print("Response body: ${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Reservation.fromJson(data);
    } else {
      throw Exception("Failed to cancel reservation: ${response.statusCode} - ${response.body}");
    }
  }

  static Future<Reservation> completeReservation(int id) async {
    final url = Uri.parse("${baseUrl}reservations/$id/complete");
    print("Requesting: $url");
    print("JWT: ${_jwtLog()}");
    final response = await http.post(url, headers: _createHeaders());
    print("Response status: ${response.statusCode}");
    print("Response body: ${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Reservation.fromJson(data);
    } else {
      throw Exception("Failed to complete reservation: ${response.statusCode} - ${response.body}");
    }
  }
}

