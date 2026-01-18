class MenuItem {
  final int id;
  final int restaurantId;
  final String name;
  final String? description;
  final double price;
  final int? category; // MenuCategory enum value (0-9), 3 = Beverage
  final bool isAvailable;

  MenuItem({
    this.id = 0,
    this.restaurantId = 0,
    this.name = '',
    this.description,
    this.price = 0.0,
    this.category,
    this.isAvailable = true,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['id'] ?? 0,
      restaurantId: json['restaurantId'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'],
      price: json['price'] != null ? (json['price'] as num).toDouble() : 0.0,
      category: json['category'],
      isAvailable: json['isAvailable'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'restaurantId': restaurantId,
      'name': name,
      'description': description,
      'price': price,
      'category': category,
      'isAvailable': isAvailable,
    };
  }
}
