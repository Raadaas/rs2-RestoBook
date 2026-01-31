class Reward {
  int? id;
  String? title;
  String? description;
  int? pointsRequired;
  bool? isActive;
  DateTime? createdAt;
  int? timesClaimed;
  bool? canRedeem;

  Reward({
    this.id,
    this.title,
    this.description,
    this.pointsRequired,
    this.isActive,
    this.createdAt,
    this.timesClaimed,
    this.canRedeem,
  });

  factory Reward.fromJson(Map<String, dynamic> json) {
    return Reward(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      pointsRequired: json['pointsRequired'],
      isActive: json['isActive'],
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : null,
      timesClaimed: json['timesClaimed'],
      canRedeem: json['canRedeem'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'pointsRequired': pointsRequired,
      'isActive': isActive,
      'createdAt': createdAt?.toIso8601String(),
      'timesClaimed': timesClaimed,
      'canRedeem': canRedeem,
    };
  }
}
