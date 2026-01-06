import 'package:json_annotation/json_annotation.dart';

part 'menu_item_model.g.dart';

@JsonSerializable()
class MenuItem {
  final int id;
  final int restaurantId;
  final String restaurantName;
  final String name;
  final String? description;
  final double price;
  final String? category;
  final bool isVegetarian;
  final bool isVegan;
  final String? allergens;
  final String? imageUrl;
  final bool isAvailable;
  final DateTime createdAt;

  MenuItem({
    required this.id,
    required this.restaurantId,
    required this.restaurantName,
    required this.name,
    this.description,
    required this.price,
    this.category,
    required this.isVegetarian,
    required this.isVegan,
    this.allergens,
    this.imageUrl,
    required this.isAvailable,
    required this.createdAt,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) =>
      _$MenuItemFromJson(json);
  Map<String, dynamic> toJson() => _$MenuItemToJson(this);
}

