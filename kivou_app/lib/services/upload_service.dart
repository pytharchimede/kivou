import 'dart:io';
import 'package:http/http.dart' as http;

class UploadService {
  UploadService({http.Client? client, String? baseUrl})
      : baseUrl = baseUrl ?? 'https://fidest.ci/kivou/backend';
  final String baseUrl;

  Future<String> uploadProviderPhoto(File file, {int? providerId}) async {
    final uri = Uri.parse('$baseUrl/api/providers/upload_photo.php');
    final req = http.MultipartRequest('POST', uri);
    req.files.add(await http.MultipartFile.fromPath('file', file.path));
    if (providerId != null) req.fields['provider_id'] = providerId.toString();
    final res = await http.Response.fromStream(await req.send());
    if (res.statusCode >= 400) {
      throw Exception('Upload failed: ${res.statusCode} ${res.body}');
    }
    // Expected: { ok: true, data: { url: "/kivou/backend/uploads/..." } }
    final body = res.body;
    if (!body.contains('"ok":true')) {
      throw Exception('Upload error: $body');
    }
    final match = RegExp('"url"\s*:\s*"([^"]+)"').firstMatch(body);
    if (match == null) throw Exception('Upload parse error: $body');
    return match.group(1)!;
  }
}
