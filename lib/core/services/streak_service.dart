import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:qlctfe/models/streak.dart';
import '../../api/api_constants.dart';

class StreakService {

  Future<Streak> getStreak(String token) async {
    final response = await http.get(
      Uri.parse(ApiConstants.streak),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      return Streak.fromJson(json.decode(response.body));
    } else {
      throw Exception("Không lấy được streak: ${response.body}");
    }
  }
}
