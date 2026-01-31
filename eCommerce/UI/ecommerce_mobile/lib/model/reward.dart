class Reward {
  final int id;
  final String title;
  final String? description;
  final int pointsRequired;
  final int? restaurantId;
  final bool isActive;
  final DateTime createdAt;
  final int timesClaimed;
  final bool canRedeem;

  Reward({
    required this.id,
    required this.title,
    this.description,
    required this.pointsRequired,
    this.restaurantId,
    required this.isActive,
    required this.createdAt,
    required this.timesClaimed,
    required this.canRedeem,
  });

  factory Reward.fromJson(Map<String, dynamic> json) {
    return Reward(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'],
      pointsRequired: json['pointsRequired'] ?? 0,
      restaurantId: json['restaurantId'],
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      timesClaimed: json['timesClaimed'] ?? 0,
      canRedeem: json['canRedeem'] ?? false,
    );
  }
}
