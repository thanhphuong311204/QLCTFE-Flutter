import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qlctfe/api/secure_storage.dart';
import 'package:qlctfe/api/api_constants.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();

  String? _email;
  String? _username;
  String? _avatarUrl;
  String? _createdAt;
  int? _walletCount;
  double? _totalBalance;

  File? _pickedImage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    final token = await SecureStorage().getToken();

    try {
      final res = await http.get(
        Uri.parse("${ApiConstants.baseUrl}/api/user/profile"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (res.statusCode == 200) {
        final data = json.decode(res.body);

        setState(() {
          _nameCtrl.text = data['fullName'] ?? "";
          _phoneCtrl.text = data['phone'] ?? "";
          _email = data['email'];
          _username = data['username'];
          _avatarUrl = data['avatarUrl'];
          _createdAt = data['createdAt'];
          _walletCount = data['walletCount'];
          _totalBalance = (data['totalBalance'] ?? 0).toDouble();
        });
      } else {
        throw Exception("Không thể tải thông tin người dùng (status ${res.statusCode})");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi khi tải hồ sơ: $e")),
      );
    }
  }

Future<void> _pickImage() async {
  final picker = ImagePicker();
  final image = await picker.pickImage(source: ImageSource.gallery);

  if (image != null) {
    setState(() {
      _pickedImage = File(image.path);
    });

    await _uploadAvatar();
  }
}
Future<void> _uploadAvatar() async {
  if (_pickedImage == null) return;

  setState(() => _isLoading = true);

  try {
    final token = await SecureStorage().getToken();
    final uri = Uri.parse("${ApiConstants.baseUrl}/api/upload/image");

    var request = http.MultipartRequest("POST", uri);
    request.headers["Authorization"] = "Bearer $token";

    request.files.add(
      await http.MultipartFile.fromPath(
        "file",
        _pickedImage!.path,
      ),
    );

    final streamed = await request.send();
    final responseBody = await streamed.stream.bytesToString();

    print("📌 Upload response: $responseBody");

    if (streamed.statusCode == 200) {
      final jsonData = json.decode(responseBody);

      setState(() {
        _avatarUrl =
            "${jsonData["avatarUrl"]}?v=${DateTime.now().millisecondsSinceEpoch}";
        _pickedImage = null;
      });

      // 🔥 Reload profile để đảm bảo avatar được update từ backend
      await _fetchProfile();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Upload avatar thành công!")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Upload thất bại (${streamed.statusCode})")),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Lỗi upload avatar: $e")),
    );
  } finally {
    setState(() => _isLoading = false);
  }
}

  /// 💾 Gửi yêu cầu cập nhật thông tin
  Future<void> _updateProfile() async {
    setState(() => _isLoading = true);
    final token = await SecureStorage().getToken();

    try {
      final body = json.encode({
        "fullName": _nameCtrl.text.trim(),
        "phone": _phoneCtrl.text.trim(),
      });

      final res = await http.put(
        Uri.parse("${ApiConstants.baseUrl}/api/user/profile"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: body,
      );

      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Cập nhật thành công!")));
        _fetchProfile(); // reload lại
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Cập nhật thất bại: ${res.statusCode}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Lỗi: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _formatMoney(double value) {
    return "${value.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')} ₫";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffFEF5E7),
      appBar: AppBar(
        title: const Text("Hồ sơ cá nhân"),
        backgroundColor: const Color(0xffF4C97D),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 55,
                backgroundColor: Colors.grey[300],
                backgroundImage: _pickedImage != null
    ? FileImage(_pickedImage!)
    : (_avatarUrl != null
        ? NetworkImage(_avatarUrl!)
        : null),
child: (_pickedImage == null && _avatarUrl == null)
    ? const Icon(Icons.person, size: 45, color: Colors.grey)
    : Align(
        alignment: Alignment.bottomRight,
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.camera_alt, size: 18, color: Colors.orange),
        ),
      ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _nameCtrl.text.isNotEmpty ? _nameCtrl.text : "Chưa có tên",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              _email ?? _username ?? "Không có email",
              style: const TextStyle(color: Colors.grey),
            ),
            const Divider(height: 30, thickness: 1),

            _buildInfoRow(Icons.phone, "Số điện thoại",
                _phoneCtrl.text.isNotEmpty ? _phoneCtrl.text : "Chưa cập nhật"),
            _buildInfoRow(Icons.calendar_today, "Ngày tạo tài khoản",
                _createdAt != null ? _createdAt!.split('T')[0] : "Chưa có"),
            _buildInfoRow(Icons.account_balance_wallet, "Số lượng ví",
                _walletCount != null ? "$_walletCount ví" : "Đang tải..."),
            _buildInfoRow(Icons.attach_money, "Tổng số dư",
                _totalBalance != null ? _formatMoney(_totalBalance!) : "Đang tải..."),

            const SizedBox(height: 20),

            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: "Họ tên",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: "Số điện thoại",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _updateProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xffF4C97D),
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Cập nhật thông tin",
                      style: TextStyle(fontWeight: FontWeight.bold)),
            ),

            const SizedBox(height: 15),
            OutlinedButton(
              onPressed: () => Navigator.pushNamed(context, '/change-password'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.orange),
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text("Đổi mật khẩu",
                  style: TextStyle(color: Colors.orange)),
            ),
            const SizedBox(height: 15),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.orangeAccent),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.black54, fontSize: 13)),
                Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
