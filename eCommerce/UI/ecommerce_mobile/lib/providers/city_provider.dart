import 'package:ecommerce_mobile/model/city.dart';
import 'package:ecommerce_mobile/model/search_result.dart';
import 'package:ecommerce_mobile/providers/base_provider.dart';

class CityProvider extends BaseProvider<City> {
  CityProvider() : super('cities');

  @override
  City fromJson(dynamic json) {
    return City.fromJson(json as Map<String, dynamic>);
  }

  Future<List<City>> getActive() async {
    final result = await get(filter: {'isActive': true});
    return result.items ?? [];
  }
}
