import 'dart:io';
import 'package:http/http.dart' as http;

class ChatUploadService {
  ChatUploadService({http.Client? client, String? baseUrl})
      : baseUrl = baseUrl ?? 'https://fidest.ci/kivou/backend';
  final String baseUrl;

  Future<String> uploadAttachment(File file) async {
    final uri = Uri.parse('$baseUrl/api/chat/upload_attachment.php');
    final req = http.MultipartRequest('POST', uri);
    req.files.add(await http.MultipartFile.fromPath('file', file.path));
    final res = await http.Response.fromStream(await req.send());
    if (res.statusCode >= 400) {
      throw Exception('Upload failed: ${res.statusCode} ${res.body}');
    }
    final body = res.body;
    final match = RegExp('"url"\s*:\s*"([^"]+)"').firstMatch(body);
    if (match == null) throw Exception('Upload parse error: $body');
    return match.group(1)!;
  }
}
