import 'api_client.dart';
import '../models/ad.dart';

class AdsService {
  final ApiClient _api;
  AdsService(this._api);

  Future<List<Ad>> list(
      {String? kind,
      String? authorType,
      String? category,
      String status = 'active',
      String? q,
      String? providerId,
      int limit = 50}) async {
    final query = <String, dynamic>{
      'status': status,
      if (kind != null) 'kind': kind,
      if (authorType != null) 'author_type': authorType,
      if (category != null) 'category': category,
      if (q != null && q.isNotEmpty) 'q': q,
      if (providerId != null) 'provider_id': providerId,
      'limit': limit,
    };
    final data = await _api.getList('/api/ads/list.php', query);
    return data.map((e) => Ad.fromApi(e as Map<String, dynamic>)).toList();
  }

  Future<Ad> create({
    required String kind,
    required String title,
    String? description,
    String? imageUrl,
    double? amount,
    String currency = 'XOF',
    String? category,
    String authorType = 'client',
    String? providerId,
    double? lat,
    double? lng,
  }) async {
    final payload = {
      'kind': kind,
      'title': title,
      if (description != null) 'description': description,
      if (imageUrl != null) 'image_url': imageUrl,
      if (amount != null) 'amount': amount,
      'currency': currency,
      if (category != null) 'category': category,
      'author_type': authorType,
      if (providerId != null) 'provider_id': providerId,
      if (lat != null && lng != null) ...{'lat': lat, 'lng': lng},
    };
    final data = await _api.postJson('/api/ads/create.php', payload);
    return Ad.fromApi(data);
  }

  Future<Map<String, dynamic>> pinInConversation(
      {required int conversationId, required int adId}) async {
    return _api.postJson('/api/ads/pin_in_conversation.php', {
      'conversation_id': conversationId,
      'ad_id': adId,
    });
  }
}
