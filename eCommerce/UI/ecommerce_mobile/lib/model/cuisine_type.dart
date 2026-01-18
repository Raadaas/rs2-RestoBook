class CuisineType {
  final int id;
  final String name;
  final String? description;
  final bool isActive;

  CuisineType({
    this.id = 0,
    this.name = '',
    this.description,
    this.isActive = true,
  });

  factory CuisineType.fromJson(Map<String, dynamic> json) {
    return CuisineType(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'],
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'isActive': isActive,
    };
  }
}
