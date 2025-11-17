import 'dart:convert';
import 'package:http/http.dart' as http;
import '../api/api_constants.dart';
import '../api/secure_storage.dart';
import '../models/budget_model.dart';

class BudgetService {
  Future<String> _getToken() async {
    final storage = SecureStorage();
    final token = await storage.getToken();
    if (token == null) throw Exception("Chưa đăng nhập!");
    return token;
  }

  Future<List<Budget>> fetchBudgets() async {
    final token = await _getToken();
    final url = Uri.parse(ApiConstants.budgets);

    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => Budget.fromJson(e)).toList();
    } else {
      throw Exception("Lỗi tải ngân sách: ${response.statusCode}");
    }
  }

  Future<void> createBudget(Map<String, dynamic> body) async {
    final token = await _getToken();
    final url = Uri.parse(ApiConstants.budgets);

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception("Lỗi tạo ngân sách: ${response.statusCode}");
    }
  }

  Future<void> deleteBudget(int id) async {
    final token = await _getToken();
    final url = Uri.parse("${ApiConstants.budgets}/$id");

    final response = await http.delete(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200 &&
        response.statusCode != 204) {
      throw Exception("Lỗi xoá ngân sách: ${response.statusCode}");
    }
  }
}
