import 'package:ecommerce_desktop/models/restaurant_model.dart';
import 'package:ecommerce_desktop/providers/base_provider.dart';
import 'package:ecommerce_desktop/model/search_result.dart';

class RestaurantProvider extends BaseProvider<Restaurant> {
  RestaurantProvider() : super("restaurants");

  @override
  Restaurant fromJson(dynamic json) {
    return Restaurant.fromJson(json);
  }

  Future<SearchResult<Restaurant>> getRestaurantsByOwner(int ownerId) async {
    return await get(filter: {'ownerId': ownerId, 'isActive': true});
  }
}

