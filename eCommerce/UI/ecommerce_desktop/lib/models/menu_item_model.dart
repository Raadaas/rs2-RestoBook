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

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    // Parse category - can be int (enum) or string
    String? categoryStr;
    if (json['category'] != null) {
      if (json['category'] is int) {
        categoryStr = _categoryEnumToString(json['category'] as int);
      } else {
        categoryStr = json['category'].toString();
      }
    }

    // Parse allergens - can be int (flags enum) or string
    String? allergensStr;
    final allergensValue = json['allergens'];
    if (allergensValue != null) {
      if (allergensValue is int) {
        allergensStr = _allergenEnumToString(allergensValue);
      } else {
        allergensStr = allergensValue.toString();
      }
    }

    // Determine if vegetarian/vegan based on allergens
    // Note: This is a simplification - you may need to adjust based on your business logic
    final allergensInt = allergensValue is int ? allergensValue : 0;
    final isVegetarian = allergensInt == 0 || !_hasAllergen(allergensInt, [1, 2, 4, 8, 16, 64, 128]); // Not gluten, crustaceans, eggs, fish, peanuts, milk, nuts
    final isVegan = allergensInt == 0 || !_hasAllergen(allergensInt, [1, 2, 4, 8, 16, 32, 64, 128]); // Not any animal products

    return MenuItem(
      id: json['id'] ?? 0,
      restaurantId: json['restaurantId'] ?? 0,
      restaurantName: json['restaurantName'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      category: categoryStr,
      isVegetarian: json['isVegetarian'] ?? isVegetarian,
      isVegan: json['isVegan'] ?? isVegan,
      allergens: allergensStr,
      imageUrl: json['imageUrl']?.toString(),
      isAvailable: json['isAvailable'] ?? true,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
    );
  }

  static String? _categoryEnumToString(int value) {
    switch (value) {
      case 0: return 'Appetizer';
      case 1: return 'MainCourse';
      case 2: return 'Dessert';
      case 3: return 'Beverage';
      case 4: return 'Salad';
      case 5: return 'Soup';
      case 6: return 'SideDish';
      case 7: return 'Breakfast';
      case 8: return 'Lunch';
      case 9: return 'Dinner';
      default: return null;
    }
  }

  static String _allergenEnumToString(int value) {
    if (value == 0) return 'None';
    final allergens = <String>[];
    if (value & 1 != 0) allergens.add('Gluten');
    if (value & 2 != 0) allergens.add('Crustaceans');
    if (value & 4 != 0) allergens.add('Eggs');
    if (value & 8 != 0) allergens.add('Fish');
    if (value & 16 != 0) allergens.add('Peanuts');
    if (value & 32 != 0) allergens.add('Soybeans');
    if (value & 64 != 0) allergens.add('Milk');
    if (value & 128 != 0) allergens.add('Nuts');
    if (value & 256 != 0) allergens.add('Celery');
    if (value & 512 != 0) allergens.add('Mustard');
    if (value & 1024 != 0) allergens.add('Sesame');
    if (value & 2048 != 0) allergens.add('Sulfites');
    if (value & 4096 != 0) allergens.add('Lupin');
    if (value & 8192 != 0) allergens.add('Molluscs');
    return allergens.isEmpty ? 'None' : allergens.join(', ');
  }

  static bool _hasAllergen(int value, List<int> allergenFlags) {
    for (var flag in allergenFlags) {
      if ((value & flag) != 0) return true;
    }
    return false;
  }

  Map<String, dynamic> toJson() {
    // Convert category string back to enum int
    int? categoryInt = _categoryStringToEnum(category);

    // Convert allergen string back to enum int
    int allergenInt = _allergenStringToEnum(allergens);

    return {
      'id': id,
      'restaurantId': restaurantId,
      'restaurantName': restaurantName,
      'name': name,
      'description': description,
      'price': price,
      'category': categoryInt,
      'allergens': allergenInt,
      'imageUrl': imageUrl,
      'isAvailable': isAvailable,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  static int? _categoryStringToEnum(String? categoryStr) {
    if (categoryStr == null) return null;
    switch (categoryStr.toLowerCase()) {
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

  static int _allergenStringToEnum(String? allergenStr) {
    if (allergenStr == null || allergenStr.isEmpty || allergenStr.toLowerCase() == 'none') {
      return 0;
    }
    int value = 0;
    final allergens = allergenStr.split(',').map((e) => e.trim().toLowerCase()).toList();
    if (allergens.contains('gluten')) value |= 1;
    if (allergens.contains('crustaceans')) value |= 2;
    if (allergens.contains('eggs')) value |= 4;
    if (allergens.contains('fish')) value |= 8;
    if (allergens.contains('peanuts')) value |= 16;
    if (allergens.contains('soybeans')) value |= 32;
    if (allergens.contains('milk')) value |= 64;
    if (allergens.contains('nuts')) value |= 128;
    if (allergens.contains('celery')) value |= 256;
    if (allergens.contains('mustard')) value |= 512;
    if (allergens.contains('sesame')) value |= 1024;
    if (allergens.contains('sulfites')) value |= 2048;
    if (allergens.contains('lupin')) value |= 4096;
    if (allergens.contains('molluscs')) value |= 8192;
    return value;
  }
}
