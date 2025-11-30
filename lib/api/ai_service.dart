import 'package:dio/dio.dart';
import 'api_constants.dart';

class AIService {
  final Dio _dio = Dio(BaseOptions(
    headers: {"Content-Type": "application/json"},
  ));

  Future<Map<String, dynamic>> suggestCategory(String description) async {
    final res = await _dio.post(
      ApiConstants.aiSuggest,
      data: {"description": description},
    );
    return res.data;
  }
}
