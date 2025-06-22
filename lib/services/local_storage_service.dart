import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LocalStorageService {
  // Inisialisasi storage
  static const _storage = FlutterSecureStorage();

  static Future<void> saveUserData(
    Map<String, dynamic> userData,
    String token,
  ) async {
    await _storage.write(key: 'user', value: jsonEncode(userData));
    await _storage.write(key: 'token', value: token);
  }

  static Future<Map<String, dynamic>?> getUserData() async {
    final jsonString = await _storage.read(key: 'user');
    if (jsonString != null) {
      return jsonDecode(jsonString);
    }
    return null;
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: 'token');
  }

  static Future<void> clear() async {
    await _storage.delete(key: 'user');
    await _storage.delete(key: 'token');
  }
}
