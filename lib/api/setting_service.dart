import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:qlctfe/api/api_constants.dart';
import 'package:qlctfe/api/secure_storage.dart';

class SettingsService {
  final storage = SecureStorage();

  Future<Map<String, dynamic>> getSettings() async {
    final token = await storage.getToken();

    final res = await http.get(
      Uri.parse(ApiConstants.settings),
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    if (res.statusCode == 200) {
      return json.decode(res.body);
    }

    throw Exception("Lỗi tải setting: ${res.statusCode}");
  }

  Future<void> updateSettings(Map<String, dynamic> body) async {
    final token = await storage.getToken();

    final res = await http.put(
      Uri.parse(ApiConstants.settings),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: json.encode(body),
    );

    if (res.statusCode != 200) {
      throw Exception("Lỗi cập nhật setting: ${res.statusCode}");
    }
  }
}
