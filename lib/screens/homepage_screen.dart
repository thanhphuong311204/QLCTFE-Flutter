import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'category_screen.dart';

class HomePageScreen extends StatelessWidget {
  const HomePageScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const CategoryScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Trang chính"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: const Center(
        child: Text("Chào mừng bạn đến ứng dụng quản lý chi tiêu!"),
      ),
    );
  }
}
