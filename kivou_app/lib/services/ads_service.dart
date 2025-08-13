import 'api_client.dart';
import '../models/ad.dart';
import 'mappers.dart';

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
    List<String>? images, // multi-images
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
      // rétrocompatibilité: image_url (normalisée)
      if (imageUrl != null && imageUrl.isNotEmpty)
        'image_url': toServerImagePath(imageUrl),
      // encore plus compatible: certains backends utilisent 'image'
      if (imageUrl != null && imageUrl.isNotEmpty)
        'image': toServerImagePath(imageUrl),
      // sérialisation CSV (normalisée pour le serveur)
      if (images != null && images.isNotEmpty)
        'image_urls':
            images.map(toServerImagePath).where((s) => s.isNotEmpty).join(','),
      // et une liste brute si le backend sait la lire directement
      if (images != null && images.isNotEmpty)
        'images':
            images.map(toServerImagePath).where((s) => s.isNotEmpty).toList(),
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

  /// Récupère le détail d'une annonce (incluant images[])
  Future<Ad> detail(int id) async {
    final data = await _api.getJson('/api/ads/detail.php', {'id': id});
    return Ad.fromApi(data);
  }

  /// Ajoute des images supplémentaires à une annonce existante (table ad_images côté backend)
  Future<void> addImages(
      {required int adId, required List<String> images}) async {
    final list =
        images.map(toServerImagePath).where((s) => s.isNotEmpty).toList();
    if (list.isEmpty) return;
    await _api.postJson('/api/ads/add_images.php', {
      'ad_id': adId,
      'images': list,
    });
  }

  /// Supprime une image d'annonce (par id ou par URL)
  Future<void> deleteImage({required int adId, int? imageId, String? url}) {
    if (imageId == null && (url == null || url.isEmpty)) {
      throw ArgumentError('imageId or url must be provided');
    }
    final payload = {
      'ad_id': adId,
      if (imageId != null) 'image_id': imageId,
      if (url != null && url.isNotEmpty) 'url': toServerImagePath(url),
    };
    return _api.postJson('/api/ads/delete_image.php', payload).then((_) {});
  }

  /// Réordonne les images via leurs IDs
  Future<void> reorderImagesByIds(
      {required int adId, required List<int> imageIds}) async {
    if (imageIds.isEmpty) return;
    await _api.postJson('/api/ads/reorder_images.php', {
      'ad_id': adId,
      'order': imageIds,
    });
  }

  /// Réordonne les images via leurs URLs
  Future<void> reorderImagesByUrls(
      {required int adId, required List<String> urls}) async {
    final list =
        urls.map(toServerImagePath).where((s) => s.isNotEmpty).toList();
    if (list.isEmpty) return;
    await _api.postJson('/api/ads/reorder_images.php', {
      'ad_id': adId,
      'order': list,
    });
  }

  Future<Map<String, dynamic>> pinInConversation(
      {required int conversationId, required int adId}) async {
    return _api.postJson('/api/ads/pin_in_conversation.php', {
      'conversation_id': conversationId,
      'ad_id': adId,
    });
  }
}
