import 'api_client.dart';

class CategoryService {
  final ApiClient _api;
  CategoryService(this._api);

  Future<List<String>> listNames() async {
    final list = await _api.getList('/api/categories/list.php', {});
    return list
        .map((e) => (e is Map && e['name'] != null) ? e['name'].toString() : '')
        .where((s) => s.isNotEmpty)
        .cast<String>()
        .toList();
  }
}
