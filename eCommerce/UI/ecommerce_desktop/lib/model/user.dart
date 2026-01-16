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
  final String? roleName; // First role name if available

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
    this.roleName,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // Extract first role name if roles array exists
    String? roleName;
    if (json['roles'] != null && json['roles'] is List && (json['roles'] as List).isNotEmpty) {
      roleName = json['roles'][0]['name'];
    }

    return User(
      id: json['id'] ?? 0,
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
      username: json['username'] ?? '',
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      lastLoginAt: json['lastLoginAt'] != null
          ? DateTime.parse(json['lastLoginAt'])
          : null,
      passwordChangedAt: json['passwordChangedAt'] != null
          ? DateTime.parse(json['passwordChangedAt'])
          : null,
      phoneNumber: json['phoneNumber'],
      cityId: json['cityId'],
      imageUrl: json['imageUrl'],
      roleName: roleName,
    );
  }
}

