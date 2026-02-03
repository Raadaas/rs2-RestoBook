class RestaurantGalleryItem {
  int? id;
  int? restaurantId;
  String? imageUrl;
  String? imageType;
  int? displayOrder;
  DateTime? uploadedAt;

  RestaurantGalleryItem({
    this.id,
    this.restaurantId,
    this.imageUrl,
    this.imageType,
    this.displayOrder,
    this.uploadedAt,
  });

  factory RestaurantGalleryItem.fromJson(Map<String, dynamic> json) {
    return RestaurantGalleryItem(
      id: json['id'],
      restaurantId: json['restaurantId'],
      imageUrl: json['imageUrl'],
      imageType: json['imageType'],
      displayOrder: json['displayOrder'] ?? 0,
      uploadedAt: json['uploadedAt'] != null
          ? DateTime.parse(json['uploadedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'restaurantId': restaurantId,
      'imageUrl': imageUrl,
      'imageType': imageType,
      'displayOrder': displayOrder,
      'uploadedAt': uploadedAt?.toIso8601String(),
    };
  }
}
