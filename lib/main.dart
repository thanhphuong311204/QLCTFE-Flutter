import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:qlctfe/screens/category_screen.dart';
import 'package:qlctfe/screens/profile/profile_screen.dart';
import 'package:qlctfe/screens/profile/change_password_screen.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('vi', 'VN'),
        Locale('en', 'US'),
      ],
      path: 'assets/lang',
      fallbackLocale: const Locale('vi', 'VN'),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      
      debugShowCheckedModeBanner: false,
      title: 'QLCT',
      theme: ThemeData(
        colorSchemeSeed: Colors.orange,
        useMaterial3: true,
      ),
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      routes: {
    "/profile": (_) => const ProfileScreen(),
    "/change-password": (_) => const ChangePasswordScreen(),
  },
      home: const CategoryScreen(),
    );
  }
}
