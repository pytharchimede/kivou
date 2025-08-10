import 'api_client.dart';

class BookingService {
  final ApiClient _api;
  BookingService(this._api);

  Future<Map<String, dynamic>> create({
    required int userId,
    required int providerId,
    required String serviceCategory,
    String? description,
    required DateTime scheduledAt,
    required double duration,
    required double totalPrice,
  }) {
    return _api.postJson('/api/bookings/create.php', {
      'user_id': userId,
      'provider_id': providerId,
      'service_category': serviceCategory,
      'service_description': description,
      'scheduled_at':
          scheduledAt.toIso8601String().substring(0, 19).replaceFirst('T', ' '),
      'duration': duration,
      'total_price': totalPrice,
    });
  }

  Future<List<dynamic>> listByUser(int userId) {
    return _api.getList('/api/bookings/list_by_user.php', {'user_id': userId});
  }
}
