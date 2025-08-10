import 'api_client.dart';

class ProviderService {
  final ApiClient _api;
  ProviderService(this._api);

  Future<List<dynamic>> list({String? category, double? minRating, String? q}) {
    final query = <String, dynamic>{};
    if (category != null) query['category'] = category;
    if (minRating != null) query['minRating'] = minRating;
    if (q != null && q.isNotEmpty) query['q'] = q;
    return _api.getList('/api/providers/list.php', query);
  }

  Future<Map<String, dynamic>> registerProvider({
    required String name,
    required String email,
    required String phone,
    required List<String> categories,
    required double pricePerHour,
    String? description,
    double? latitude,
    double? longitude,
  }) {
    return _api.postJson('/api/providers/register.php', {
      'name': name,
      'email': email,
      'phone': phone,
      'categories': categories,
      'price_per_hour': pricePerHour,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
    });
  }

  Future<Map<String, dynamic>> detail(int id) async {
    return _api.getJson('/api/providers/detail.php', {'id': id});
  }
}
