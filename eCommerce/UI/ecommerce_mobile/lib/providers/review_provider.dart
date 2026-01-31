import 'package:ecommerce_mobile/model/review.dart';
import 'package:ecommerce_mobile/providers/base_provider.dart';
import 'package:ecommerce_mobile/providers/auth_provider.dart';

class ReviewProvider extends BaseProvider<Review> {
  ReviewProvider() : super("reviews");

  @override
  Review fromJson(dynamic json) => Review.fromJson(json);

  Future<List<Review>> getMyReviews() async {
    final userId = AuthProvider.userId;
    if (userId == null) return [];
    final result = await get(filter: {'UserId': userId, 'RetrieveAll': true});
    return result.items ?? [];
  }

  Future<Review> updateReview(Review r, {required int rating, required String? comment}) async {
    final body = {
      'reservationId': r.reservationId,
      'userId': r.userId,
      'restaurantId': r.restaurantId,
      'rating': rating,
      'comment': comment,
      'foodQuality': r.foodQuality,
      'serviceQuality': r.serviceQuality,
      'ambienceRating': r.ambienceRating,
      'valueForMoney': r.valueForMoney,
      'isVerified': r.isVerified,
    };
    final updated = await update(r.id, body);
    return updated as Review;
  }

  Future<void> deleteReview(int id) async {
    await delete(id);
  }
}
