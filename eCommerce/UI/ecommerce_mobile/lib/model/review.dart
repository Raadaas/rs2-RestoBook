class Review {
  final int id;
  final int reservationId;
  final int userId;
  final String userName;
  final int restaurantId;
  final String restaurantName;
  final int rating;
  final String? comment;
  final int? foodQuality;
  final int? serviceQuality;
  final int? ambienceRating;
  final int? valueForMoney;
  final DateTime createdAt;
  final bool isVerified;

  Review({
    required this.id,
    required this.reservationId,
    required this.userId,
    required this.userName,
    required this.restaurantId,
    required this.restaurantName,
    required this.rating,
    this.comment,
    this.foodQuality,
    this.serviceQuality,
    this.ambienceRating,
    this.valueForMoney,
    required this.createdAt,
    required this.isVerified,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] ?? 0,
      reservationId: json['reservationId'] ?? 0,
      userId: json['userId'] ?? 0,
      userName: json['userName'] ?? '',
      restaurantId: json['restaurantId'] ?? 0,
      restaurantName: json['restaurantName'] ?? '',
      rating: json['rating'] ?? 0,
      comment: json['comment'],
      foodQuality: json['foodQuality'],
      serviceQuality: json['serviceQuality'],
      ambienceRating: json['ambienceRating'],
      valueForMoney: json['valueForMoney'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      isVerified: json['isVerified'] ?? false,
    );
  }
}
