import 'dart:io';
import 'package:http/http.dart' as http;

class AnnouncementUploadService {
  AnnouncementUploadService({http.Client? client, String? baseUrl})
      : baseUrl = baseUrl ?? 'https://fidest.ci/kivou/backend';
  final String baseUrl;

  Future<String> upload(File file) async {
    final uri = Uri.parse('$baseUrl/api/announcements/upload_image.php');
    final req = http.MultipartRequest('POST', uri);
    req.files.add(await http.MultipartFile.fromPath('file', file.path));
    final res = await http.Response.fromStream(await req.send());
    if (res.statusCode >= 400 || !res.body.contains('"ok":true')) {
      throw Exception('Upload failed: ${res.statusCode} ${res.body}');
    }
    final match = RegExp('"url"\s*:\s*"([^"]+)"').firstMatch(res.body);
    if (match == null) throw Exception('Upload parse error: ${res.body}');
    return match.group(1)!;
  }
}
