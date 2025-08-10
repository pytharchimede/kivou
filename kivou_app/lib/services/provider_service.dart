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
}
