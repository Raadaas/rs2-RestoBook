class City {
  final int id;
  final String name;
  final bool isActive;

  City({
    required this.id,
    required this.name,
    this.isActive = true,
  });

  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      isActive: json['isActive'] ?? true,
    );
  }
}
