import 'package:ecommerce_mobile/model/cuisine_type.dart';
import 'package:ecommerce_mobile/providers/base_provider.dart';

class CuisineTypeProvider extends BaseProvider<CuisineType> {
  CuisineTypeProvider() : super("cuisineTypes");

  @override
  CuisineType fromJson(dynamic json) {
    return CuisineType.fromJson(json);
  }
}
