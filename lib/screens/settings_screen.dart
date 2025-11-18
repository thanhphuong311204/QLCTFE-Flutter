import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:qlctfe/api/setting_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _service = SettingService();

  String language = "vi";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("settings".tr()),
        backgroundColor: Colors.orange.shade200,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("language".tr(),
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold)),

            const SizedBox(height: 10),

            DropdownButton<String>(
              value: language,
              items: const [
                DropdownMenuItem(value: "vi", child: Text("Tiếng Việt")),
                DropdownMenuItem(value: "en", child: Text("English")),
              ],
              onChanged: (v) async {
                if (v == null) return;

                setState(() => language = v);

                // đổi ngôn ngữ toàn app
                if (v == "vi") {
                  await context.setLocale(const Locale('vi', 'VN'));
                } else {
                  await context.setLocale(const Locale('en', 'US'));
                }
              },
            ),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: () async {
                await _service.updateSettings({"language": language});

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("save".tr())),
                );
              },
              child: Text("save".tr()),
            )
          ],
        ),
      ),
    );
  }
}
