import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SessionStorage {
  static const _kToken = 'kivou_token';
  static const _kUser = 'kivou_user';
  final FlutterSecureStorage _s = const FlutterSecureStorage();

  Future<void> saveSession(String token, Map<String, dynamic> user) async {
    await _s.write(key: _kToken, value: token);
    await _s.write(key: _kUser, value: jsonEncode(user));
  }

  Future<String?> get token async => _s.read(key: _kToken);
  Future<Map<String, dynamic>?> get user async {
    final raw = await _s.read(key: _kUser);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> clear() async {
    await _s.delete(key: _kToken);
    await _s.delete(key: _kUser);
  }
}
