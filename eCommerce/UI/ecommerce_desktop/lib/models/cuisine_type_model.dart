class CuisineType {
  final int id;
  final String name;
  final String? description;
  final DateTime createdAt;
  final bool isActive;

  CuisineType({
    required this.id,
    required this.name,
    this.description,
    required this.createdAt,
    required this.isActive,
  });

  factory CuisineType.fromJson(Map<String, dynamic> json) {
    return CuisineType(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'],
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
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
    };
  }
}

