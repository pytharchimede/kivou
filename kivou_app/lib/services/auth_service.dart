import 'api_client.dart';

class AuthService {
  final ApiClient _api;
  AuthService(this._api);

  Future<Map<String, dynamic>> login(String email, String password) {
    return _api.postJson(
        '/api/auth/login.php', {'email': email, 'password': password});
  }

  Future<Map<String, dynamic>> register(
      String email, String password, String name,
      {String? phone}) {
    return _api.postJson('/api/auth/register.php',
        {'email': email, 'password': password, 'name': name, 'phone': phone});
  }
}
