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
    int? category;
    final cat = json['category'];
    if (cat != null) {
      if (cat is int) {
        category = cat;
      } else if (cat is String) {
        category = _categoryStringToInt(cat);
      }
    }
    return MenuItem(
      id: json['id'] ?? 0,
      restaurantId: json['restaurantId'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'],
      price: json['price'] != null ? (json['price'] as num).toDouble() : 0.0,
      category: category,
      isAvailable: json['isAvailable'] ?? true,
    );
  }

  static int? _categoryStringToInt(String s) {
    switch (s.toLowerCase()) {
      case 'appetizer': return 0;
      case 'maincourse': return 1;
      case 'dessert': return 2;
      case 'beverage': return 3;
      case 'salad': return 4;
      case 'soup': return 5;
      case 'sidedish': return 6;
      case 'breakfast': return 7;
      case 'lunch': return 8;
      case 'dinner': return 9;
      default: return null;
    }
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
