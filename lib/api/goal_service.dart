import 'dart:convert';
import 'package:http/http.dart' as http;
import '../api/api_constants.dart';
import '../api/secure_storage.dart';
import '../models/goal_model.dart';

class GoalService {
  Future<String> _getToken() async {
    final storage = SecureStorage();
    final token = await storage.getToken();

    if (token == null || token.isEmpty) {
      throw Exception("🚫 Chưa đăng nhập!");
    }

    return token;
  }

  Future<List<GoalModel>> getGoals() async {
    final token = await _getToken();
    final url = Uri.parse(ApiConstants.goals);


    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );


    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => GoalModel.fromJson(e)).toList();
    } else {
      throw Exception('Lỗi tải mục tiêu (${response.statusCode})');
    }
  }

  Future<void> addGoal(Map<String, dynamic> goalData) async {
    final token = await _getToken();
    final url = Uri.parse(ApiConstants.goals);


    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(goalData),
    );


    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Lỗi tạo mục tiêu: ${response.statusCode}');
    }
  }

  Future<void> updateProgress(int goalId, double amount) async {
    final token = await _getToken();
    final url = Uri.parse('${ApiConstants.goals}/$goalId/progress');
    final body = jsonEncode({'amount': amount});


    final response = await http.put(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: body,
    );


    if (response.statusCode != 200) {
      throw Exception('Lỗi cập nhật tiến độ (${response.statusCode})');
    }
  }

  // 🟢 Xoá mục tiêu
  Future<void> deleteGoal(int id) async {
    final token = await _getToken();
    final url = Uri.parse('${ApiConstants.goals}/$id');


    final response = await http.delete(
      url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );


    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Lỗi xoá mục tiêu (${response.statusCode})');
    }
  }
}
