class SpecialOffer {
  final int id;
  final int restaurantId;
  final String restaurantName;
  final String title;
  final String? description;
  final double price;
  final DateTime validFrom;
  final DateTime validTo;
  final bool isActive;
  final DateTime createdAt;

  SpecialOffer({
    required this.id,
    required this.restaurantId,
    required this.restaurantName,
    required this.title,
    this.description,
    required this.price,
    required this.validFrom,
    required this.validTo,
    required this.isActive,
    required this.createdAt,
  });

  factory SpecialOffer.fromJson(Map<String, dynamic> json) {
    return SpecialOffer(
      id: json['id'] ?? 0,
      restaurantId: json['restaurantId'] ?? 0,
      restaurantName: json['restaurantName'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      validFrom: json['validFrom'] != null 
          ? DateTime.parse(json['validFrom']) 
          : DateTime.now(),
      validTo: json['validTo'] != null 
          ? DateTime.parse(json['validTo']) 
          : DateTime.now(),
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'restaurantId': restaurantId,
      'restaurantName': restaurantName,
      'title': title,
      'description': description,
      'price': price,
      'validFrom': validFrom.toIso8601String(),
      'validTo': validTo.toIso8601String(),
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

