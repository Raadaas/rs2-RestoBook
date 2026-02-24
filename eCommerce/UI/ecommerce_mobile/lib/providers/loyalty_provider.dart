import 'dart:convert';
import 'package:ecommerce_mobile/model/reward.dart';
import 'package:ecommerce_mobile/providers/auth_provider.dart';
import 'package:http/http.dart' as http;

class LoyaltyProvider {
  static String get _baseUrl =>
      const String.fromEnvironment("baseUrl", defaultValue: "http://10.0.2.2:5121/api/");

  Map<String, String> _headers() {
    final t = AuthProvider.token;
    final auth = t != null && t.isNotEmpty
        ? "Bearer $t"
        : "Basic ${base64Encode(utf8.encode('${AuthProvider.username ?? ""}:${AuthProvider.password ?? ""}'))}";
    return {"Content-Type": "application/json", "Authorization": auth};
  }

  Future<LoyaltyPointsResult> getMyPoints() async {
    try {
      final url = Uri.parse("${_baseUrl}loyalty/points");
      final res = await http.get(url, headers: _headers());
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final data = jsonDecode(res.body) as Map<String, dynamic>?;
        if (data == null) return LoyaltyPointsResult(currentPoints: 0, totalPointsEarned: 0);
        final current = data['currentPoints'] ?? data['CurrentPoints'];
        final total = data['totalPointsEarned'] ?? data['TotalPointsEarned'];
        return LoyaltyPointsResult(
          currentPoints: (current is int) ? current : (current != null ? int.tryParse(current.toString()) ?? 0 : 0),
          totalPointsEarned: (total is int) ? total : (total != null ? int.tryParse(total.toString()) ?? 0 : 0),
        );
      }
    } catch (_) {}
    return LoyaltyPointsResult(currentPoints: 0, totalPointsEarned: 0);
  }

  Future<List<Reward>> getAvailableRewards(int? restaurantId) async {
    try {
      var url = "${_baseUrl}loyalty/rewards";
      if (restaurantId != null) {
        url = "$url?restaurantId=$restaurantId";
      }
      final uri = Uri.parse(url);
      final res = await http.get(uri, headers: _headers());
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final data = jsonDecode(res.body);
        if (data is List) {
          return data.map((e) => Reward.fromJson(e as Map<String, dynamic>)).toList();
        }
      }
    } catch (_) {}
    return [];
  }

  Future<bool> redeemReward(int rewardId) async {
    try {
      final url = Uri.parse("${_baseUrl}loyalty/rewards/$rewardId/redeem");
      final res = await http.post(url, headers: _headers());
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (_) {}
    return false;
  }
}

class LoyaltyPointsResult {
  final int currentPoints;
  final int totalPointsEarned;
  LoyaltyPointsResult({required this.currentPoints, required this.totalPointsEarned});
}
