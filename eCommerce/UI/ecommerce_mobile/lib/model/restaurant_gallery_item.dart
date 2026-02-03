class RestaurantGalleryItem {
  final int id;
  final int restaurantId;
  final String imageUrl;
  final String? imageType;
  final int displayOrder;
  final DateTime? uploadedAt;

  RestaurantGalleryItem({
    required this.id,
    required this.restaurantId,
    required this.imageUrl,
    this.imageType,
    required this.displayOrder,
    this.uploadedAt,
  });

  factory RestaurantGalleryItem.fromJson(Map<String, dynamic> json) {
    return RestaurantGalleryItem(
      id: json['id'] ?? 0,
      restaurantId: json['restaurantId'] ?? 0,
      imageUrl: json['imageUrl'] ?? '',
      imageType: json['imageType'],
      displayOrder: json['displayOrder'] ?? 0,
      uploadedAt: json['uploadedAt'] != null
          ? DateTime.tryParse(json['uploadedAt'].toString())
          : null,
    );
  }
}
