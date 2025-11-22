import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:qlctfe/api/api_constants.dart';
import 'package:qlctfe/api/secure_storage.dart';

class NotificationService {
  final _storage = SecureStorage();

  Future<String?> _token() async => await _storage.getToken();

  // 🟢 Lấy danh sách thông báo
  Future<List<dynamic>> getNotifications() async {
    final token = await _token();

    final url = "${ApiConstants.baseUrl}/api/notifications";
    print("URL: $url");

    final res = await http.get(
      Uri.parse(url),
      headers: {"Authorization": "Bearer $token"},
    );

    print("Status: ${res.statusCode}");
    print("Body: ${res.body}");

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception("Không thể tải thông báo");
    }
  }

  // 🟡 Đánh dấu 1 cái đã đọc
  Future<void> markAsRead(int id) async {
    final token = await _token();
    await http.put(
      Uri.parse("${ApiConstants.baseUrl}/notifications/$id/read"),
      headers: {"Authorization": "Bearer $token"},
    );
  }

  // ⭐ Đánh dấu TẤT CẢ đã đọc
  Future<void> markAllAsRead() async {
    final token = await _token();
    await http.put(
      Uri.parse("${ApiConstants.baseUrl}/notifications/read-all"),
      headers: {"Authorization": "Bearer $token"},
    );
  }

  // 🔴 Xóa thông báo
  Future<void> deleteNotification(int id) async {
    final token = await _token();
    await http.delete(
      Uri.parse("${ApiConstants.baseUrl}/notifications/$id"),
      headers: {"Authorization": "Bearer $token"},
    );
  }
}
