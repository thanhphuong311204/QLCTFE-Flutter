import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:qlctfe/api/api_constants.dart';

class AIPredictionService {
  Future<Map<String, dynamic>> predictSpending(int userId, int month) async {
    final url = Uri.parse(ApiConstants.aiPredict);

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "userId": userId,
        "month": month,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Lỗi AI: ${response.body}");
    }
  }
}
