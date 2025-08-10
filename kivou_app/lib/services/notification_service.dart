import 'api_client.dart';

class NotificationService {
  final ApiClient _api;
  NotificationService(this._api);

  Future<List<Map<String, dynamic>>> list() async {
    final data = await _api.getList('/api/notifications/list.php');
    return data.cast<Map<String, dynamic>>();
  }

  Future<void> create({required String title, String? body, int? providerId}) {
    return _api.postJson('/api/notifications/create.php', {
      'title': title,
      if (body != null) 'body': body,
      if (providerId != null) 'provider_id': providerId,
    });
  }

  Future<void> markRead(int id) {
    return _api.postJson('/api/notifications/mark_read.php', {'id': id});
  }
}
