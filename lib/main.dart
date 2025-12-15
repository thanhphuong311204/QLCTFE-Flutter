import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';

import 'package:qlctfe/api/fcm_service.dart';
import 'package:qlctfe/screens/category_screen.dart';
import 'package:qlctfe/screens/flash_screen.dart';
import 'package:qlctfe/screens/profile/profile_screen.dart';
import 'package:qlctfe/screens/profile/change_password_screen.dart';
import 'package:qlctfe/screens/streak_dashboard_screen.dart';

import 'core/services/streak_provider.dart';

// Background Firebase handler
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await Firebase.initializeApp();

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  final fcmService = FCMService();
  await fcmService.initialize();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('vi')],
      path: 'assets/lang',
      fallbackLocale: const Locale('vi'),
      saveLocale: true,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => StreakProvider())],
      child: Builder(
        builder: (context) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'QLCT',
            theme: ThemeData(
              colorSchemeSeed: Colors.orange,
              useMaterial3: true,
            ),

            // Localization setup
            locale: context.locale,
            supportedLocales: context.supportedLocales,
            localizationsDelegates: context.localizationDelegates,

            // Routes giữ nguyên
            routes: {
              "/profile": (_) => const ProfileScreen(),
              "/change-password": (_) => const ChangePasswordScreen(),
              "/streak-dashboard": (_) => const StreakDashboardScreen(),

            },

            // Flash screen giữ nguyên
            home: const CategoryScreen(),
          );
        },
      ),
    );
  }
}
