import 'package:flutter/material.dart';
import '../../api/auth_service.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final usernameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final confirmCtrl = TextEditingController();
  final _auth = AuthService();

  bool _isLoading = false;
  bool _obscure1 = true;
  bool _obscure2 = true;

  Future<void> _register() async {
    final username = usernameCtrl.text.trim();
    final email = emailCtrl.text.trim();
    final password = passCtrl.text.trim();
    final confirm = confirmCtrl.text.trim();
    final phone = phoneCtrl.text.trim();

    if (username.isEmpty || email.isEmpty || password.isEmpty || confirm.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Vui lòng nhập đầy đủ thông tin")),
      );
      return;
    }

    if (password != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Mật khẩu xác nhận không khớp")),
      );
      return;
    }

    setState(() => _isLoading = true);
    final success = await _auth.registerUser(
      username: username,
      email: email,
      password: password,
      phoneNumber: phone,
    );
    setState(() => _isLoading = false);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("🎉 Đăng ký thành công! Hãy đăng nhập để tiếp tục.")),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Đăng ký thất bại. Vui lòng thử lại.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF6FF),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 50),

            // 🐷 Ảnh con lợn tiết kiệm
            Image.asset(
              'assets/images/piggy.png',
              width: 140,
              height: 140,
            ),

            const SizedBox(height: 20),
            const Text(
              "Tạo tài khoản mới 🧡",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              "Đăng ký để bắt đầu quản lý chi tiêu",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 30),

            // ✏️ Họ và tên
            _buildTextField(usernameCtrl, "Họ và tên", Icons.person_outline, false),

            // 📞 Số điện thoại
            _buildTextField(phoneCtrl, "Số điện thoại", Icons.phone, false,
                keyboardType: TextInputType.phone),

            // 📧 Email
            _buildTextField(emailCtrl, "Email", Icons.email_outlined, false,
                keyboardType: TextInputType.emailAddress),

            // 🔑 Mật khẩu
            _buildTextField(passCtrl, "Mật khẩu", Icons.lock_outline, _obscure1,
                onToggle: () => setState(() => _obscure1 = !_obscure1)),

            // 🔁 Xác nhận mật khẩu
            _buildTextField(confirmCtrl, "Xác nhận mật khẩu", Icons.lock_outline, _obscure2,
                onToggle: () => setState(() => _obscure2 = !_obscure2)),

            const SizedBox(height: 30),

            // 🔘 Nút đăng ký
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade400,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 4,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Đăng ký",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 20),

            // 🔄 Quay lại đăng nhập
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Đã có tài khoản? "),
                GestureDetector(
                  onTap: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  ),
                  child: const Text(
                    "Đăng nhập ngay",
                    style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint,
      IconData icon, bool obscure,
      {TextInputType? keyboardType, VoidCallback? onToggle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.orange),
          suffixIcon: onToggle != null
              ? IconButton(
                  icon: Icon(
                    obscure ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey,
                  ),
                  onPressed: onToggle,
                )
              : null,
          hintText: hint,
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
