import 'dart:convert';
import 'package:ecommerce_desktop/models/dashboard_models.dart';
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
    String username = AuthProvider.username ?? "";
    String password = AuthProvider.password ?? "";
    String basicAuth = "Basic ${base64Encode(utf8.encode('$username:$password'))}";

    return {
      "Content-Type": "application/json",
      "Authorization": basicAuth,
    };
  }

  static Future<TodayReservations> getTodayReservations(int restaurantId) async {
    final url = Uri.parse("${baseUrl}reservations/today?restaurantId=$restaurantId");
    print("Requesting: $url");
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

  static Future<OccupancyData> getCurrentOccupancy(int restaurantId) async {
    final url = Uri.parse("${baseUrl}tables/occupancy?restaurantId=$restaurantId");
    print("Requesting: $url");
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
    final response = await http.get(url, headers: _createHeaders());

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
    final response = await http.get(url, headers: _createHeaders());

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return ReservationsSummary.fromJson(data);
    } else {
      throw Exception("Failed to load reservations summary: ${response.statusCode} - ${response.body}");
    }
  }

  static Future<AverageRating> getAverageRating(int restaurantId) async {
    final url = Uri.parse("${baseUrl}analytics/average-rating?restaurantId=$restaurantId");
    final response = await http.get(url, headers: _createHeaders());

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return AverageRating.fromJson(data);
    } else {
      throw Exception("Failed to load average rating: ${response.statusCode} - ${response.body}");
    }
  }

  static Future<List<WeeklyOccupancyData>> getWeeklyOccupancy(int restaurantId) async {
    final url = Uri.parse("${baseUrl}analytics/weekly-occupancy?restaurantId=$restaurantId");
    final response = await http.get(url, headers: _createHeaders());

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
}

