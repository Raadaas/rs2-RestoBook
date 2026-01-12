import 'package:ecommerce_desktop/models/menu_item_model.dart';
import 'package:ecommerce_desktop/providers/base_provider.dart';
import 'package:ecommerce_desktop/model/search_result.dart';
import 'package:http/http.dart' as http;

class MenuItemProvider extends BaseProvider<MenuItem> {
  MenuItemProvider() : super("menuitems");

  List<MenuItem> _menuItems = [];
  bool _isLoading = false;
  String? _error;

  List<MenuItem> get menuItems => _menuItems;
  bool get isLoading => _isLoading;
  String? get error => _error;

  @override
  MenuItem fromJson(dynamic json) {
    return MenuItem.fromJson(json);
  }

  Future<void> loadMenuItems(int restaurantId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final filter = {'restaurantId': restaurantId};
      final result = await get(filter: filter);
      _menuItems = result.items ?? [];
      _error = null;
    } catch (e) {
      _error = e.toString();
      _menuItems = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<MenuItem> insert(dynamic request) async {
    final item = await super.insert(request);
    await loadMenuItems(request['restaurantId'] as int);
    return item;
  }

  Future<MenuItem> updateItem(int id, dynamic request) async {
    final item = await update(id, request);
    await loadMenuItems(request['restaurantId'] as int);
    return item;
  }

  Future<bool> delete(int id) async {
    const baseUrl = String.fromEnvironment("baseUrl",
        defaultValue: "http://localhost:5121/api/");
    var url = "${baseUrl}menuitems/$id";
    var uri = Uri.parse(url);
    var headers = createHeaders();

    var response = await http.delete(uri, headers: headers);

    if (isValidResponse(response)) {
      // Reload menu items if we have restaurantId
      if (_menuItems.isNotEmpty) {
        final restaurantId = _menuItems.first.restaurantId;
        await loadMenuItems(restaurantId);
      }
      return true;
    } else {
      throw Exception("Unknown error");
    }
  }
}

