class Restaurant {
  final int id;
  final int ownerId;
  final String ownerName;
  final String name;
  final String? description;
  final String address;
  final int cityId;
  final String cityName;
  final double? latitude;
  final double? longitude;
  final String? phoneNumber;
  final String? email;
  final int cuisineTypeId;
  final String cuisineTypeName;
  final double? averageRating;
  final int totalReviews;
  final bool hasParking;
  final bool hasTerrace;
  final bool isKidFriendly;
  final String openTime; // Format: "HH:mm:ss"
  final String closeTime; // Format: "HH:mm:ss"
  final DateTime createdAt;
  final bool isActive;

  Restaurant({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    required this.name,
    this.description,
    required this.address,
    required this.cityId,
    required this.cityName,
    this.latitude,
    this.longitude,
    this.phoneNumber,
    this.email,
    required this.cuisineTypeId,
    required this.cuisineTypeName,
    this.averageRating,
    required this.totalReviews,
    required this.hasParking,
    required this.hasTerrace,
    required this.isKidFriendly,
    required this.openTime,
    required this.closeTime,
    required this.createdAt,
    required this.isActive,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      id: json['id'] ?? 0,
      ownerId: json['ownerId'] ?? 0,
      ownerName: json['ownerName'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      address: json['address'] ?? '',
      cityId: json['cityId'] ?? 0,
      cityName: json['cityName'] ?? '',
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
      phoneNumber: json['phoneNumber'],
      email: json['email'],
      cuisineTypeId: json['cuisineTypeId'] ?? 0,
      cuisineTypeName: json['cuisineTypeName'] ?? '',
      averageRating: json['averageRating'] != null ? (json['averageRating'] as num).toDouble() : null,
      totalReviews: json['totalReviews'] ?? 0,
      hasParking: json['hasParking'] ?? false,
      hasTerrace: json['hasTerrace'] ?? false,
      isKidFriendly: json['isKidFriendly'] ?? false,
      openTime: json['openTime'] ?? '09:00:00',
      closeTime: json['closeTime'] ?? '22:00:00',
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'name': name,
      'description': description,
      'address': address,
      'cityId': cityId,
      'cityName': cityName,
      'latitude': latitude,
      'longitude': longitude,
      'phoneNumber': phoneNumber,
      'email': email,
      'cuisineTypeId': cuisineTypeId,
      'cuisineTypeName': cuisineTypeName,
      'averageRating': averageRating,
      'totalReviews': totalReviews,
      'hasParking': hasParking,
      'hasTerrace': hasTerrace,
      'isKidFriendly': isKidFriendly,
      'openTime': openTime,
      'closeTime': closeTime,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
    };
  }
}
