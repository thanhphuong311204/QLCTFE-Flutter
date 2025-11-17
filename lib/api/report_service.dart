import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:qlctfe/api/api_constants.dart';
import 'package:qlctfe/api/secure_storage.dart';
import 'package:qlctfe/models/report_model.dart';

class ReportService {
  Future<List<ReportModel>> fetchReports() async {
    final token = await SecureStorage().getToken();

    final res = await http.get(
      Uri.parse("${ApiConstants.baseUrl}/reports"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      return (data as List).map((e) => ReportModel.fromJson(e)).toList();
    } else {
      throw Exception("Lỗi tải báo cáo: ${res.statusCode}");
    }
  }

  Future<void> createReport(Map<String, dynamic> body) async {
    final token = await SecureStorage().getToken();

    final res = await http.post(
      Uri.parse("${ApiConstants.baseUrl}/reports"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: json.encode(body),
    );

    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception("Tạo báo cáo thất bại: ${res.statusCode}");
    }
  }
}
