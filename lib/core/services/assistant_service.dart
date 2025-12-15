import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../api/api_constants.dart';

class AssistantService {
  Future<String> askAssistant(String question, String mode) async {
    final url = Uri.parse("${ApiConstants.baseUrl}/api/assistant/ask");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "question": question,
        "mode": mode,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["reply"] ?? "Trợ lý bị lỗi không trả lời.";
    } else {
      return "⚠ Lỗi server: ${response.statusCode}";
    }
  }
}
