import 'api_client.dart';

class ReviewService {
  final ApiClient _api;
  ReviewService(this._api);

  Future<Map<String, dynamic>> create({
    required int bookingId,
    required int userId,
    required int providerId,
    required double rating,
    String? comment,
    String? photos,
  }) {
    return _api.postJson('/api/reviews/create.php', {
      'booking_id': bookingId,
      'user_id': userId,
      'provider_id': providerId,
      'rating': rating,
      'comment': comment,
      'photos': photos,
    });
  }
}
