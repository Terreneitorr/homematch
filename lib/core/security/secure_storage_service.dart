import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // 4 campos sensibles
  static const _keyToken = 'access_token';
  static const _keyUserId = 'user_id';
  static const _keyUserEmail = 'user_email';
  static const _keyUserRole = 'user_role';

  static Future<void> saveSecureData({
    required String token,
    required String userId,
    required String email,
    required String role,
  }) async {
    await Future.wait([
      _storage.write(key: _keyToken, value: token),
      _storage.write(key: _keyUserId, value: userId),
      _storage.write(key: _keyUserEmail, value: email),
      _storage.write(key: _keyUserRole, value: role),
    ]);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: _keyToken);
  }

  static Future<Map<String, String?>> getAllSecureData() async {
    return {
      'token': await _storage.read(key: _keyToken),
      'userId': await _storage.read(key: _keyUserId),
      'email': await _storage.read(key: _keyUserEmail),
      'role': await _storage.read(key: _keyUserRole),
    };
  }

  /// WIPE REMOTO — elimina todos los datos sensibles
  static Future<void> wipeAllData() async {
    await _storage.deleteAll();
  }

  static Future<void> deleteToken() async {
    await _storage.delete(key: _keyToken);
  }
}