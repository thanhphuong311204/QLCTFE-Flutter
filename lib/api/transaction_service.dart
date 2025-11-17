import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:qlctfe/api/api_constants.dart';
import 'package:qlctfe/api/secure_storage.dart';
import '../models/transaction_model.dart';

class TransactionService {
  // 🔐 Lấy token từ SecureStorage
  Future<String> _getToken() async {
    final storage = SecureStorage();
    final token = await storage.getToken();

    if (token == null || token.isEmpty) {
      throw Exception("⚠️ Chưa đăng nhập hoặc token trống!");
    }

    return token.trim();
  }

  // 🟢 Lấy danh sách thu nhập
  Future<List<TransactionModel>> getIncomes() async {
    final token = await _getToken();
    print("🔑 Token đang dùng: $token");

    final response = await http.get(
      Uri.parse(ApiConstants.incomes),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((e) => TransactionModel.fromJson(e)).toList();
    } else {
      throw Exception("Không thể tải danh sách thu nhập (${response.statusCode})");
    }
  }

  // 🔴 Lấy danh sách chi tiêu
  Future<List<TransactionModel>> getExpenses() async {
    final token = await _getToken();

    final response = await http.get(
      Uri.parse(ApiConstants.expenses),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((e) => TransactionModel.fromJson(e)).toList();
    } else {
      throw Exception("Không thể tải danh sách chi tiêu (${response.statusCode})");
    }
  }

  // ➕ Thêm thu nhập
  Future<void> addIncome(Map<String, dynamic> data) async {
    await _createTransaction(ApiConstants.addIncome, data);
  }

  // ➕ Thêm chi tiêu
  Future<void> addExpense(Map<String, dynamic> data) async {
    await _createTransaction(ApiConstants.addExpense, data);
  }

  // ⚙️ Hàm xử lý chung cho Income + Expense
  Future<void> _createTransaction(String url, Map<String, dynamic> data) async {
    final token = await _getToken();

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: json.encode(data),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception("Không thể thêm giao dịch (${response.statusCode})");
    }
  }

  // ✏️ Cập nhật giao dịch
  Future<void> updateTransaction(
      int id, Map<String, dynamic> data, bool isExpense) async {

    final token = await _getToken();
    final url =
        "${isExpense ? ApiConstants.expenses : ApiConstants.incomes}/$id";

    final response = await http.put(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: json.encode(data),
    );

    if (response.statusCode != 200) {
      throw Exception("Không thể cập nhật giao dịch (${response.statusCode})");
    }
  }

  // 🗑️ Xoá giao dịch
  Future<void> deleteTransaction(int id, bool isExpense) async {
    final token = await _getToken();
    final url =
        "${isExpense ? ApiConstants.expenses : ApiConstants.incomes}/$id";

    final response = await http.delete(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception("Không thể xoá giao dịch (${response.statusCode})");
    } else {
      print("✅ Giao dịch $id xoá thành công (${response.statusCode})");
    }
  }
}
