import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:qlctfe/api/api_constants.dart';
import 'package:qlctfe/api/secure_storage.dart';

class RecurringService {
  Future<List<dynamic>> getRecurring() async {
    final token = await SecureStorage().getToken();

    final res = await http.get(
      Uri.parse(ApiConstants.recurring), // ✔ FIX URL
      headers: {"Authorization": "Bearer $token"},
    );

    if (res.statusCode == 200) {
      return json.decode(res.body);
    } else {
      throw Exception("Lỗi tải recurring");
    }
  }

  Future<bool> createRecurring(Map<String, dynamic> body) async {
    final token = await SecureStorage().getToken();

    final res = await http.post(
      Uri.parse(ApiConstants.recurring), // ✔ FIX URL
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: json.encode(body),
    );


    return res.statusCode == 200 || res.statusCode == 201;
  }

  Future<bool> deleteRecurring(int id) async {
    final token = await SecureStorage().getToken();

    final res = await http.delete(
      Uri.parse("${ApiConstants.recurring}/$id"), 
      headers: {"Authorization": "Bearer $token"},
    );


    return res.statusCode == 204;
  }

  Future<void> runNow() async {
    final token = await SecureStorage().getToken();

    final res = await http.post(
      Uri.parse("${ApiConstants.recurring}/run-now"), 
      headers: {"Authorization": "Bearer $token"},
    );

  }
}
