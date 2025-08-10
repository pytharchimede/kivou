import 'dart:io';
import 'package:http/http.dart' as http;

class UploadService {
  UploadService({http.Client? client, String? baseUrl})
      : baseUrl = baseUrl ?? 'https://fidest.ci/kivou/backend';
  final String baseUrl;

  Future<String> uploadProviderPhoto(
    File file, {
    int? providerId,
    String? bearerToken,
  }) async {
    final uri = Uri.parse('$baseUrl/api/providers/upload_photo.php');

    Future<http.Response> _tryFieldName(String fieldName) async {
      final req = http.MultipartRequest('POST', uri);
      if (bearerToken != null && bearerToken.isNotEmpty) {
        req.headers['Authorization'] = 'Bearer $bearerToken';
      }
      req.files.add(await http.MultipartFile.fromPath(fieldName, file.path));
      if (providerId != null) {
        req.fields['provider_id'] = providerId.toString();
      }
      final streamed = await req.send();
      return http.Response.fromStream(streamed);
    }

    // 1) Essai avec 'file', 2) fallback 'photo'
    http.Response res = await _tryFieldName('file');
    if (res.statusCode >= 400 || !res.body.contains('"ok":true')) {
      res = await _tryFieldName('photo');
    }
    if (res.statusCode >= 400) {
      throw Exception('Upload failed: ${res.statusCode} ${res.body}');
    }
    final body = res.body;
    if (!body.contains('"ok":true')) {
      throw Exception('Upload error: $body');
    }
    final match = RegExp('"url"\s*:\s*"([^"]+)"').firstMatch(body);
    if (match == null) throw Exception('Upload parse error: $body');
    return match.group(1)!;
  }
}
