import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qlctfe/api/user_service.dart';
import 'change_password_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _service = UserService();
  bool loading = true;
  bool uploadingAvatar = false;

  String email = "";
  String? avatarUrl;
  String? createdAt;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadUser();
  }

Future<void> loadUser() async {
  try {
    final data = await _service.getCurrentUser();

    setState(() {
      nameController.text = data["fullName"] ?? "";
      phoneController.text = data["phone"] ?? "";
      email = data["email"];
      avatarUrl = data["avatarUrl"];
      createdAt = data["createdAt"];
      loading = false;
    });
  } catch (e) {
    setState(() {  // <-- thêm dòng này
      loading = false;
    });

    // Debug xem lỗi gì
    print("LỖI loadUser: $e");
  }
}

  String getJoinDate(String iso) {
    try {
      return DateFormat('dd/MM/yyyy').format(DateTime.parse(iso));
    } catch (_) {
      return "";
    }
  }

  // ============================================
  // 🔥 PICK AVATAR + REQUEST PERMISSION + CROP
  // ============================================
  Future<void> pickAvatar() async {
    // 1. Xin permission cho Android 13+
    final status = await Permission.photos.request();

    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Bạn phải cho phép quyền truy cập ảnh")),
      );
      return;
    }

    // 2. Chọn ảnh
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked == null) return;

    await uploadAvatar(picked.path);
  }

  Future<void> uploadAvatar(String filePath) async {
    setState(() => uploadingAvatar = true);

    final url = await _service.uploadAvatar(filePath);

    if (url != null) {
      setState(() => avatarUrl = url);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✔ Đã cập nhật ảnh đại diện")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Không thể cập nhật ảnh")),
      );
    }

    setState(() => uploadingAvatar = false);
  }

  Future<void> saveProfile() async {
    try {
      await _service.updateProfile(
        fullName: nameController.text,
        phone: phoneController.text,
      );

      setState(() {});

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("✔ Đã cập nhật")));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Lỗi: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.orange.shade50,
      appBar: AppBar(
        title: const Text(
          "Hồ sơ cá nhân",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.orange.shade200,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: uploadingAvatar ? null : pickAvatar,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black12, blurRadius: 8, spreadRadius: 1)
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 55,
                      backgroundImage:
                          avatarUrl != null ? NetworkImage(avatarUrl!) : null,
                      child: avatarUrl == null
                          ? const Icon(Icons.person,
                              size: 60, color: Colors.grey)
                          : null,
                    ),
                  ),
                  if (uploadingAvatar)
                    const CircularProgressIndicator(color: Colors.orange)
                ],
              ),
            ),

            const SizedBox(height: 12),

            Text(
              nameController.text.isEmpty ? "Chưa có tên" : nameController.text,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              email,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 15,
              ),
            ),

            const SizedBox(height: 6),

            if (createdAt != null)
              Text(
                "Tham gia từ: ${getJoinDate(createdAt!)}",
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                ),
              ),

            const SizedBox(height: 30),

            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: "Họ tên",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),

            const SizedBox(height: 14),

            TextField(
              controller: phoneController,
              decoration: InputDecoration(
                labelText: "Số điện thoại",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              keyboardType: TextInputType.phone,
            ),

            const SizedBox(height: 28),

            ElevatedButton(
              onPressed: saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 40),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text(
                "Lưu thay đổi",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),

            const SizedBox(height: 16),

            OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ChangePasswordScreen()),
                );
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.orange),
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 40),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text(
                "Đổi mật khẩu",
                style: TextStyle(color: Colors.orange),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
