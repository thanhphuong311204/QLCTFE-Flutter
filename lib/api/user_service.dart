import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:qlctfe/api/api_constants.dart';
import 'package:qlctfe/api/secure_storage.dart';
import 'package:http_parser/http_parser.dart';

class UserService {
  final storage = SecureStorage();

  Future<Map<String, dynamic>> getCurrentUser() async {
    final token = await storage.getToken();

    final res = await http.get(
      Uri.parse("${ApiConstants.users}/me"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (res.statusCode == 200) {
      return json.decode(res.body);
    }
    throw Exception("Cannot load user: ${res.statusCode}");
  }

  Future<bool> updateProfile({
    required String fullName,
    required String phone,
  }) async {
    final token = await storage.getToken();

    final res = await http.put(
      Uri.parse("${ApiConstants.users}/update-profile"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: json.encode({
        "fullName": fullName,
        "phone": phone,
      }),
    );

    return res.statusCode == 200;
  }

  Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final token = await storage.getToken();

    final res = await http.put(
Uri.parse("${ApiConstants.baseUrl}/api/user/change-password"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: json.encode({
        "oldPassword": oldPassword,
        "newPassword": newPassword,
      }),
    );

    return res.statusCode == 200;
  }

  Future<String?> uploadAvatar(String filePath) async {
  final token = await storage.getToken();

  final uri = Uri.parse("${ApiConstants.users}/upload-avatar");

  final request = http.MultipartRequest("POST", uri);

  request.headers.addAll({
    "Authorization": "Bearer $token",
    "Accept": "application/json",
  });

  String ext = filePath.split(".").last.toLowerCase();

  String mimeType = "jpg";
  if (ext == "png") mimeType = "png";
  if (ext == "jpeg") mimeType = "jpeg";
  if (ext == "heic") mimeType = "heic";

  final file = await http.MultipartFile.fromPath(
    "avatar",
    filePath,
    contentType: MediaType("image", mimeType),
  );

  request.files.add(file);

  final response = await request.send();
  final res = await http.Response.fromStream(response);

  if (res.statusCode == 200) {
    final jsonMap = json.decode(res.body);
    return jsonMap["avatarUrl"];
  } else {
    print("Upload failed: ${res.statusCode} - ${res.body}");
  }

  return null;
}


}
