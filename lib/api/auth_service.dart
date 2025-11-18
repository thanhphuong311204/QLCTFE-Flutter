import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:qlctfe/api/api_constants.dart';
import 'package:qlctfe/api/secure_storage.dart';

class AuthService {
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

        // 👉 GIỮ NGUYÊN token backend trả về
        String? rawToken = data['token'] ?? data['accessToken'];
        print("🔥 TOKEN BACKEND TRẢ: $rawToken"); 
        if (rawToken == null || rawToken.isEmpty) {
          return false;
        }

        // ❌ Không xoá chữ Bearer nữa
        // rawToken = rawToken.replaceAll("Bearer ", "").trim();

        final storage = SecureStorage();

        await storage.saveToken(rawToken);

        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  Future<bool> isLoggin() async {
    final storage = SecureStorage();
    final token = await storage.getToken();

    return token != null && token.isNotEmpty;
  }

  Future<void> logout() async {
    final storage = SecureStorage();
    await storage.deleteAll();
  }
}
