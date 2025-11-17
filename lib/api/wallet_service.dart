// lib/api/wallet_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:qlctfe/api/secure_storage.dart';
import '../models/wallet_model.dart';
import 'api_constants.dart';

class WalletService {
  // 🔐 Lấy token từ SecureStorage (KHÔNG dùng SharedPreferences nữa)
  Future<String> _getToken() async {
    final storage = SecureStorage();
    final token = await storage.getToken();

    if (token == null || token.isEmpty) {
      throw Exception("⚠️ Chưa đăng nhập");
    }

    return token.trim();
  }

  // 📦 Lấy danh sách ví
  Future<List<Wallet>> getWallets() async {
    final token = await _getToken();   // lấy token từ SecureStorage
    final url = Uri.parse(ApiConstants.wallets);

    print("🟢 [GET] $url");
    print("📤 Token gửi đi: Bearer $token");

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    print("📥 Code: ${response.statusCode}");
    print("📦 Body: ${response.body}");

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => Wallet.fromJson(e)).toList();
    } else if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception("🚫 Không có quyền hoặc token không hợp lệ");
    } else {
      throw Exception("🚫 Lỗi khi tải ví (${response.statusCode})");
    }
  }

  // ➕ Thêm ví mới
  Future<void> addWallet({
    required String walletName,
    required double balance,
    required String type,
  }) async {
    final token = await _getToken();
    final url = Uri.parse(ApiConstants.wallets);

    final body = {
      "walletName": walletName,
      "balance": balance,
      "type": type,
    };

    print("🟢 [POST] $url");
    print("📤 Body: $body");
    print("📤 Token gửi đi: Bearer $token");

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    print("📥 Code: ${response.statusCode}");
    print("📦 Body: ${response.body}");

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception("🚫 Lỗi khi thêm ví (${response.statusCode})");
    }
  }

  // ✏️ Cập nhật ví
  Future<void> updateWallet(int walletId, Map<String, dynamic> data) async {
    final token = await _getToken();
    final url = Uri.parse("${ApiConstants.wallets}/$walletId");

    print("🟢 [PUT] $url");
    print("📤 Token gửi đi: Bearer $token");

    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );

    print("📥 Code: ${response.statusCode}");
    print("📦 Body: ${response.body}");

    if (response.statusCode != 200) {
      throw Exception("🚫 Lỗi khi cập nhật ví (${response.statusCode})");
    }
  }

  // 🗑️ Xóa ví
  Future<void> deleteWallet(int walletId) async {
    final token = await _getToken();
    final url = Uri.parse("${ApiConstants.wallets}/$walletId");

    print("🟢 [DELETE] $url");
    print("📤 Token gửi đi: Bearer $token");

    final response = await http.delete(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    print("📥 Code: ${response.statusCode}");
    print("📦 Body: ${response.body}");

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception("🚫 Lỗi khi xóa ví (${response.statusCode})");
    }
  }
}
