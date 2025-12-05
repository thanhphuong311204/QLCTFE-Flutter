import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_constants.dart';

class AIService {
  Future<Map<String, dynamic>> suggestCategory(
      String description, bool isExpense) async {
    final url = Uri.parse(ApiConstants.aiSuggest);

    final type = isExpense ? 'expense' : 'income';

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'description': description,
        'type': type, 
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Lỗi khi gọi AI API: ${response.statusCode}');
    }
  }
}
