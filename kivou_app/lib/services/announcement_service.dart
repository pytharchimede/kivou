import 'api_client.dart';
import '../models/announcement.dart';

class AnnouncementService {
  final ApiClient _api;
  AnnouncementService(this._api);

  Future<List<Announcement>> list({String? type, String? authorRole}) async {
    final list = await _api.getList('/api/announcements/list.php', {
      if (type != null) 'type': type,
      if (authorRole != null) 'author_role': authorRole,
    });
    return list
        .map((e) => Announcement.fromApi(e as Map<String, dynamic>))
        .toList();
  }

  Future<int> create({
    required String type, // request|offer
    required String authorRole, // client|provider
    String? providerId,
    required String title,
    String? description,
    double? price,
    List<String>? images,
  }) async {
    final data = await _api.postJson('/api/announcements/create.php', {
      'type': type,
      'author_role': authorRole,
      if (providerId != null) 'provider_id': providerId,
      'title': title,
      if (description != null) 'description': description,
      if (price != null) 'price': price,
      'images': images ?? const <String>[],
    });
    return int.tryParse(data['id']?.toString() ?? '') ?? 0;
  }
}
