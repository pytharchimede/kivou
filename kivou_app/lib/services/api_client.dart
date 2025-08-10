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
    final raw = res.body;
    Map<String, dynamic>? map;
    try {
      map = (raw.isNotEmpty ? jsonDecode(raw) : null) as Map<String, dynamic>?;
    } catch (_) {
      map = null;
    }
    if (map == null) {
      throw ApiException(
          'INVALID_RESPONSE',
          'Réponse serveur invalide (HTTP ${res.statusCode}).' +
              (raw.isEmpty
                  ? ''
                  : ' Détails: ${raw.substring(0, raw.length.clamp(0, 200))}'));
    }
    if (res.statusCode >= 400 || map['ok'] != true) {
      throw ApiException(map['error']?.toString() ?? 'HTTP_${res.statusCode}',
          map['message']?.toString() ?? 'Erreur inconnue');
    }
    final data = map['data'];
    return (data is Map<String, dynamic>) ? data : <String, dynamic>{};
  }

  Future<List<dynamic>> getList(String path,
      [Map<String, dynamic>? query]) async {
    final headers = {
      if (_bearerToken != null) 'Authorization': 'Bearer $_bearerToken',
    };
    final res = await _client.get(_u(path, query), headers: headers);
    final raw = res.body;
    Map<String, dynamic>? map;
    try {
      map = (raw.isNotEmpty ? jsonDecode(raw) : null) as Map<String, dynamic>?;
    } catch (_) {
      map = null;
    }
    if (map == null) {
      throw ApiException(
          'INVALID_RESPONSE',
          'Réponse serveur invalide (HTTP ${res.statusCode}).' +
              (raw.isEmpty
                  ? ''
                  : ' Détails: ${raw.substring(0, raw.length.clamp(0, 200))}'));
    }
    if (res.statusCode >= 400 || map['ok'] != true) {
      throw ApiException(map['error']?.toString() ?? 'HTTP_${res.statusCode}',
          map['message']?.toString() ?? 'Erreur inconnue');
    }
    final data = map['data'];
    return (data is List<dynamic>) ? data : const [];
  }
}

class ApiException implements Exception {
  final String code;
  final String message;
  ApiException(this.code, this.message);
  @override
  String toString() => 'ApiException($code): $message';
}
