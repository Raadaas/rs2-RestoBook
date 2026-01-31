class User {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String username;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final DateTime? passwordChangedAt;
  final String? phoneNumber;
  final int? cityId;
  final String? imageUrl;

  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.username,
    required this.isActive,
    required this.createdAt,
    this.lastLoginAt,
    this.passwordChangedAt,
    this.phoneNumber,
    this.cityId,
    this.imageUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
      username: json['username'] ?? '',
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      lastLoginAt: json['lastLoginAt'] != null
          ? DateTime.parse(json['lastLoginAt'] as String)
          : null,
      passwordChangedAt: json['passwordChangedAt'] != null
          ? DateTime.parse(json['passwordChangedAt'] as String)
          : null,
      phoneNumber: json['phoneNumber'] as String?,
      cityId: json['cityId'] as int?,
      imageUrl: json['imageUrl'] as String?,
    );
  }
}
