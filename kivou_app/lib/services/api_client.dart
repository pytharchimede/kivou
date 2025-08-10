import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  ApiClient({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        baseUrl = baseUrl ?? 'https://fidest.ci/kivou/backend';

  final http.Client _client;
  final String baseUrl;
  String? _bearerToken;

  void setBearerToken(String? token) {
    _bearerToken = token;
  }

  Uri _u(String path, [Map<String, dynamic>? query]) =>
      Uri.parse('$baseUrl$path')
          .replace(queryParameters: query?.map((k, v) => MapEntry(k, '$v')));

  Future<Map<String, dynamic>> postJson(
      String path, Map<String, dynamic> body) async {
    final headers = {
      'Content-Type': 'application/json',
      if (_bearerToken != null) 'Authorization': 'Bearer $_bearerToken',
    };
    final res =
        await _client.post(_u(path), headers: headers, body: jsonEncode(body));
    final map = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 400 || map['ok'] != true) {
      throw ApiException(map['error'] ?? 'HTTP_${res.statusCode}',
          map['message'] ?? 'Unknown error');
    }
    return map['data'] as Map<String, dynamic>;
  }

  Future<List<dynamic>> getList(String path,
      [Map<String, dynamic>? query]) async {
    final headers = {
      if (_bearerToken != null) 'Authorization': 'Bearer $_bearerToken',
    };
    final res = await _client.get(_u(path, query), headers: headers);
    final map = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 400 || map['ok'] != true) {
      throw ApiException(map['error'] ?? 'HTTP_${res.statusCode}',
          map['message'] ?? 'Unknown error');
    }
    return map['data'] as List<dynamic>;
  }
}

class ApiException implements Exception {
  final String code;
  final String message;
  ApiException(this.code, this.message);
  @override
  String toString() => 'ApiException($code): $message';
}
