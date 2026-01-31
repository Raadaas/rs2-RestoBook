import 'dart:convert';
import 'package:ecommerce_desktop/providers/base_provider.dart';
import 'package:ecommerce_desktop/models/reward_model.dart';
import 'package:http/http.dart' as http;

class RewardProvider extends BaseProvider<Reward> {
  RewardProvider() : super("Rewards");

  @override
  Reward fromJson(data) {
    return Reward.fromJson(data);
  }

  Future<bool> delete(int id) async {
    const baseUrl = String.fromEnvironment("baseUrl",
        defaultValue: "http://localhost:5121/api/");
    var url = "${baseUrl}Rewards/$id";
    var uri = Uri.parse(url);
    var headers = createHeaders();

    var response = await http.delete(uri, headers: headers);

    if (isValidResponse(response)) {
      return true;
    } else {
      return false;
    }
  }
}
