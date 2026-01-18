import 'package:ecommerce_mobile/model/menu_item.dart';
import 'package:ecommerce_mobile/providers/base_provider.dart';

class MenuItemProvider extends BaseProvider<MenuItem> {
  MenuItemProvider() : super("menuItems");

  @override
  MenuItem fromJson(dynamic json) {
    return MenuItem.fromJson(json);
  }
}
