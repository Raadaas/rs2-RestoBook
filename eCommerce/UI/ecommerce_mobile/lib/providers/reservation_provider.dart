import 'dart:convert';
import 'package:ecommerce_mobile/model/reservation.dart';
import 'package:ecommerce_mobile/providers/base_provider.dart';
import 'package:ecommerce_mobile/providers/auth_provider.dart';
import 'package:ecommerce_mobile/model/search_result.dart';
import 'package:http/http.dart' as http;

class ReservationProvider extends BaseProvider<Reservation> {
  ReservationProvider() : super("reservations");

  @override
  Reservation fromJson(dynamic json) {
    return Reservation.fromJson(json);
  }

  // Get reservations for current user
  Future<List<Reservation>> getMyReservations() async {
    try {
      print('Getting my reservations...');
      
      // Get user ID from AuthProvider (saved during login)
      int? userId = AuthProvider.userId;
      print('User ID from AuthProvider: $userId');
      
      if (userId == null) {
        print('User ID is null, trying to get from username...');
        // Fallback: try to get from username if not saved
        userId = await _getCurrentUserId();
        if (userId != null) {
          AuthProvider.userId = userId; // Save for next time
        }
      }
      
      if (userId == null) {
        print('Could not get user ID, returning empty list');
        return [];
      }

      // Get reservations filtered by userId
      // Use RetrieveAll to get all reservations, not just first 10
      final filter = {
        'UserId': userId,
        'RetrieveAll': true,
      };
      print('Filter: $filter');
      final result = await get(filter: filter);
      print('Got ${result.items?.length ?? 0} reservations');
      if (result.items != null && result.items!.isNotEmpty) {
        print('First reservation: ${result.items![0].toJson()}');
      }
      return result.items ?? [];
    } catch (e, stackTrace) {
      print('Error getting my reservations: $e');
      print('Stack trace: $stackTrace');
      
      // Fallback: try to get all reservations without filter
      try {
        print('Trying fallback: get all reservations...');
        final result = await get();
        print('Got ${result.items?.length ?? 0} total reservations');
        if (result.items != null) {
          // Filter by userId if we have it
          final userId = AuthProvider.userId;
          if (userId != null) {
            final userReservations = result.items!.where((r) => r.userId == userId).toList();
            print('Filtered to ${userReservations.length} reservations for user $userId');
            return userReservations;
          }
          // If no userId, return all (shouldn't happen but just in case)
          return result.items!;
        }
      } catch (fallbackError) {
        print('Fallback also failed: $fallbackError');
      }
      
      return [];
    }
  }

  // Get current user ID from username (fallback method)
  Future<int?> _getCurrentUserId() async {
    try {
      final baseUrl = const String.fromEnvironment(
        "baseUrl",
        defaultValue: "http://10.0.2.2:5121/api/",
      );
      final username = AuthProvider.username;
      print('Username: $username');
      if (username == null) {
        print('Username is null');
        return null;
      }

      // Search for user by username
      final url = Uri.parse("${baseUrl}users?username=$username");
      print('Fetching user from: $url');
      final headers = createHeaders();

      final response = await http.get(url, headers: headers);
      print('User response status: ${response.statusCode}');
      print('User response body: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        print('User data: $data');
        if (data['items'] != null && data['items'].isNotEmpty) {
          final userId = data['items'][0]['id'] as int?;
          print('Found user ID: $userId');
          return userId;
        } else {
          print('No users found in response');
        }
      } else {
        print('Failed to get user: ${response.statusCode}');
      }
      return null;
    } catch (e, stackTrace) {
      print('Error getting user ID: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  // Cancel reservation
  Future<Reservation?> cancelReservation(int id, {String? reason}) async {
    try {
      final baseUrl = const String.fromEnvironment(
        "baseUrl",
        defaultValue: "http://10.0.2.2:5121/api/",
      );
      final url = Uri.parse("${baseUrl}reservations/$id/cancel");
      final headers = createHeaders();

      final body = reason != null ? jsonEncode({'reason': reason}) : null;
      final response = await http.post(
        url,
        headers: headers,
        body: body,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        return Reservation.fromJson(data);
      } else {
        throw Exception("Failed to cancel reservation: ${response.statusCode}");
      }
    } catch (e) {
      print('Error canceling reservation: $e');
      rethrow;
    }
  }

  // Update reservation (only for Requested state)
  Future<Reservation?> updateReservation(int id, Map<String, dynamic> request) async {
    try {
      final baseUrl = const String.fromEnvironment(
        "baseUrl",
        defaultValue: "http://10.0.2.2:5121/api/",
      );
      final url = Uri.parse("${baseUrl}reservations/$id");
      final headers = createHeaders();

      final body = jsonEncode(request);
      final response = await http.put(url, headers: headers, body: body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        return Reservation.fromJson(data);
      } else {
        throw Exception("Failed to update reservation: ${response.statusCode}");
      }
    } catch (e) {
      print('Error updating reservation: $e');
      rethrow;
    }
  }
}
