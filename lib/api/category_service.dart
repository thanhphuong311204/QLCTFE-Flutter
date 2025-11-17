import 'package:http/http.dart' as http;
import 'package:qlctfe/api/api_constants.dart';
import 'dart:convert';
import '../models/category_model.dart';


class CategoryService {
  /// Lấy danh sách category công khai (is_public = 1)
  Future<List<CategoryModel>> getPublicCategories() async {
    final url = Uri.parse(ApiConstants.categories); // http://<ip>:8080/api/categories
    final response = await http.get(url, headers: {
      "Content-Type": "application/json",
    });

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => CategoryModel.fromJson(e)).toList();
    } else {
      throw Exception(
          "Không thể tải danh mục (${response.statusCode}): ${response.body}");
    }
    
  }
    /// 🔹 Lấy danh sách danh mục có xác thực (dành cho user đã đăng nhập)
  Future<List<CategoryModel>> getCategories() async {
    final url = Uri.parse(ApiConstants.categories);
    final response = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
        // ⚙️ Nếu có token (trường hợp user đã đăng nhập)
        // M có thể bỏ SharedPreferences nếu chưa cần
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => CategoryModel.fromJson(e)).toList();
    } else {
      throw Exception(
          "Không thể tải danh mục có xác thực (${response.statusCode}): ${response.body}");
    }
  }

}
