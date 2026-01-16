import 'package:ecommerce_desktop/models/cuisine_type_model.dart';
import 'package:ecommerce_desktop/providers/base_provider.dart';

class CuisineTypeProvider extends BaseProvider<CuisineType> {
  CuisineTypeProvider() : super("cuisineTypes");

  @override
  CuisineType fromJson(dynamic json) {
    return CuisineType.fromJson(json);
  }
}

