class City {
  final int id;
  final String name;
  final String? postalCode;
  final String? region;
  final DateTime createdAt;
  final bool isActive;

  City({
    required this.id,
    required this.name,
    this.postalCode,
    this.region,
    required this.createdAt,
    required this.isActive,
  });

  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      postalCode: json['postalCode'],
      region: json['region'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'postalCode': postalCode,
      'region': region,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
    };
  }
}
