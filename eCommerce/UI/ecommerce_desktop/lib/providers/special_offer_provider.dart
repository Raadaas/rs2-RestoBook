import 'package:ecommerce_desktop/models/special_offer_model.dart';
import 'package:ecommerce_desktop/providers/base_provider.dart';
import 'package:ecommerce_desktop/model/search_result.dart';
import 'package:http/http.dart' as http;

class SpecialOfferProvider extends BaseProvider<SpecialOffer> {
  SpecialOfferProvider() : super("specialoffers");

  List<SpecialOffer> _specialOffers = [];
  bool _isLoading = false;
  String? _error;

  List<SpecialOffer> get specialOffers => _specialOffers;
  bool get isLoading => _isLoading;
  String? get error => _error;

  @override
  SpecialOffer fromJson(dynamic json) {
    return SpecialOffer.fromJson(json);
  }

  Future<void> loadSpecialOffers(int restaurantId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final filter = {'restaurantId': restaurantId};
      final result = await get(filter: filter);
      _specialOffers = result.items ?? [];
      _error = null;
    } catch (e) {
      _error = e.toString();
      _specialOffers = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<SpecialOffer> insert(dynamic request) async {
    final item = await super.insert(request);
    await loadSpecialOffers(request['restaurantId'] as int);
    return item;
  }

  Future<SpecialOffer> updateItem(int id, dynamic request) async {
    final item = await update(id, request);
    await loadSpecialOffers(request['restaurantId'] as int);
    return item;
  }

  Future<bool> delete(int id) async {
    const baseUrl = String.fromEnvironment("baseUrl",
        defaultValue: "http://localhost:5121/api/");
    var url = "${baseUrl}specialoffers/$id";
    var uri = Uri.parse(url);
    var headers = createHeaders();

    var response = await http.delete(uri, headers: headers);

    if (isValidResponse(response)) {
      // Reload special offers if we have restaurantId
      if (_specialOffers.isNotEmpty) {
        final restaurantId = _specialOffers.first.restaurantId;
        await loadSpecialOffers(restaurantId);
      }
      return true;
    } else {
      throw Exception("Unknown error");
    }
  }
}

