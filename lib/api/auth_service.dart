import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:qlctfe/api/api_constants.dart';
import 'package:qlctfe/api/secure_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  final SecureStorage _storage = SecureStorage();

  // ========================= REGISTER =========================
  Future<bool> registerUser({
    required String username,
    required String email,
    required String password,
    required String phoneNumber,
  }) async {
    try {
      final url = Uri.parse(ApiConstants.register);
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
          'phone': phoneNumber,
        }),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  // ========================= LOGIN =========================
  Future<bool> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      final url = Uri.parse(ApiConstants.login);

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Token backend trả
        String? rawToken = data['token'] ?? data['accessToken'];
        print("🔥 TOKEN BACKEND TRẢ: $rawToken");

        if (rawToken == null || rawToken.isEmpty) {
          return false;
        }

        // ⭐ Lưu token vào SecureStorage
        await _storage.saveToken(rawToken);

        return true;
      } else {
        return false;
      }
    } catch (e) {
      print("❌ Login error: $e");
      return false;
    }
  }

  // ========================= CHECK LOGIN =========================
  Future<bool> isLoggin() async {
    final token = await _storage.getToken();
    return token != null && token.isNotEmpty;
  }

  // ========================= LOGOUT =========================
  Future<void> logout() async {
    await _storage.deleteAll();
  }

  // ========================= GET TOKEN (⭐ QUAN TRỌNG) =========================
  Future<String?> getToken() async {
    return await _storage.getToken();
  }

  // ========================= PROFILE =========================
  Future<Map<String, dynamic>?> getProfile() async {
    final token = await _storage.getToken();
    if (token == null) return null;

    final url = Uri.parse("${ApiConstants.baseUrl}/api/user/profile");

    final response = await http.get(
      url,
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    return null;
  }
}
