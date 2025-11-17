import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:qlctfe/api/api_constants.dart';
import 'package:qlctfe/api/secure_storage.dart';

class AuthService {
  // 🔹 Đăng ký tài khoản mới
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

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Đăng ký thành công cho $email');
        return true;
      } else {
        print('❌ Lỗi đăng ký: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('⚠️ Lỗi ngoại lệ khi đăng ký: $e');
      return false;
    }
  }

  // 🔹 Đăng nhập người dùng
  Future<bool> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      final url = Uri.parse(ApiConstants.login);
      print('📤 Gửi yêu cầu đăng nhập tới: $url');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      print('🔙 Mã phản hồi: ${response.statusCode}');
      print('🧾 Nội dung phản hồi: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String? rawToken = data['token'] ?? data['accessToken'];

        if (rawToken == null || rawToken.isEmpty) {
          print('⚠️ Token rỗng trong phản hồi.');
          return false;
        }

        // ✅ Làm sạch token nếu có "Bearer "
        rawToken = rawToken.replaceAll('Bearer ', '').trim();

        // ✅ Xóa hết token cũ trước khi lưu
        final storage = SecureStorage();
        await storage.deleteAll();

        // 🔹 Lưu token và xác nhận lại
        await storage.saveToken(rawToken);
        final check = await storage.getToken();
        print('💾 Token đã lưu vào SecureStorage: $check');

        if (check == null || check.isEmpty) {
          print('⚠️ Cảnh báo: token chưa được lưu chính xác!');
          return false;
        }

        return true;
      } else {
        print('❌ Đăng nhập thất bại: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('⚠️ Lỗi ngoại lệ khi đăng nhập: $e');
      return false;
    }
  }

  // 🔹 Kiểm tra đăng nhập
  Future<bool> isLoggin() async {
    final storage = SecureStorage();
    final token = await storage.getToken();

    if (token == null || token.isEmpty) {
      print('🚫 Chưa đăng nhập hoặc token trống.');
      return false;
    }

    print('🔑 Token lấy ra từ SecureStorage: $token');
    return true;
  }

  // 🔹 Đăng xuất
  Future<void> logout() async {
    final storage = SecureStorage();
    await storage.deleteAll();
    print('🚪 Đã đăng xuất và xóa token khỏi SecureStorage.');
  }
}
