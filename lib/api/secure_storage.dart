import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  final _storage = const FlutterSecureStorage();
  static const String _tokenKey = 'token';

  // ✅ Lưu token
  Future<void> saveToken(String token) async {
    print('💾 [SecureStorage] Lưu token: $token');
    await _storage.write(key: _tokenKey, value: token);
  }

  // ✅ Lấy token
  Future<String?> getToken() async {
    final token = await _storage.read(key: _tokenKey);
    print('🔑 [SecureStorage] Đọc token: $token');
    return token;
  }

  // ✅ Xóa token
  Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
    print('🗑️ [SecureStorage] Xóa token');
  }

  // ✅ Xóa toàn bộ (nếu cần reset)
  Future<void> deleteAll() async {
    await _storage.deleteAll();
    print('🧹 [SecureStorage] Xóa toàn bộ dữ liệu');
  }
}
