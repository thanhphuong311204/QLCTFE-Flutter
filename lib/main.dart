import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:qlctfe/api/secure_storage.dart';
import 'package:qlctfe/screens/category_screen.dart';

void main() async {
  // ✅ Cho phép dùng async và khởi tạo Flutter
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Khởi tạo định dạng ngày tháng tiếng Việt
  await initializeDateFormatting('vi_VN', null);

  // 🔥 XÓA TOKEN CŨ trước khi chạy app (fix lỗi JWT expired / 403)
  final storage = SecureStorage();
  await storage.deleteAll();
  print("🧹 Đã xóa toàn bộ token cũ khỏi SecureStorage trước khi chạy app.");

  // 🚀 Chạy app chính
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Quản lý chi tiêu',
      theme: ThemeData(
        colorSchemeSeed: Colors.orangeAccent,
        useMaterial3: true,
      ),

      // 🌏 Cấu hình đa ngôn ngữ (localization)
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('vi', 'VN'), // Tiếng Việt
        Locale('en', 'US'), // Tiếng Anh (fallback)
      ],

      // 🏠 Màn hình chính
      home: const CategoryScreen(),
    );
  }
}
