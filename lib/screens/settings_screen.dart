import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:qlctfe/api/setting_service.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _service = SettingsService();

  bool loading = true;

  // --- DATABASE FIELDS ---
  String language = "vi";
  String currency = "VND";
  bool notificationEnabled = true;
  bool showBalance = true;
  bool autoBackup = false;
  String backupFrequency = "weekly";
  TimeOfDay reminderTime = const TimeOfDay(hour: 20, minute: 0);

  @override
  void initState() {
    super.initState();
    loadSettings();
  }

  Future<void> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLang = prefs.getString('language');
      if (savedLang != null) {
        language = savedLang;
        await context.setLocale(Locale(savedLang));
      }

      final data = await _service.getSettings();

      setState(() {
        language = data["language"] ?? language;
        currency = data["currency"] ?? "VND";
        notificationEnabled = data["notificationEnabled"] == true;
        showBalance = data["showBalanceOnHome"] == true;
        autoBackup = data["autoBackup"] == true;
        backupFrequency = data["backupFrequency"] ?? "weekly";

        if (data["reminderTime"] != null) {
          final t = data["reminderTime"].split(":");
          reminderTime = TimeOfDay(
            hour: int.parse(t[0]),
            minute: int.parse(t[1]),
          );
        }

        loading = false;
      });
    } catch (e) {
      print("ERROR LOADING SETTINGS: $e");
      setState(() => loading = false);
    }
  }

  Future<void> saveSettings() async {
    final map = {
      "language": language,
      "currency": currency,
      "notificationEnabled": notificationEnabled,
      "showBalanceOnHome": showBalance,
      "autoBackup": autoBackup,
      "backupFrequency": backupFrequency,
      "reminderTime":
          "${reminderTime.hour.toString().padLeft(2, '0')}:${reminderTime.minute.toString().padLeft(2, '0')}",
    };

    try {
      await _service.updateSettings(map);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("✔ Đã lưu")));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("❌ Lỗi lưu: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("settings.title".tr()),
        backgroundColor: Colors.orange.shade200,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text("settings.language".tr(),
              style: const TextStyle(fontWeight: FontWeight.bold)),
          _dropdown(
            value: language,
            items: const {"vi": "Tiếng Việt", "en": "English"},
            onChanged: (v) async {
              if (v == null) return;
              setState(() => language = v);

              // 🔥 Chỉ cần gọi 1 lần duy nhất
              await context.setLocale(Locale(v));

              // Lưu lại lựa chọn
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('language', v);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '✅ Ngôn ngữ đã đổi thành ${v == "vi" ? "Tiếng Việt" : "English"}',
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 14),

          Text(
            "settings.currency".tr(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          _dropdown(
            value: currency,
            items: const {"VND": "VND", "USD": "USD"},
            onChanged: (v) => setState(() => currency = v!),
          ),

          const SizedBox(height: 20),

          _switch(
            "settings.notifications".tr(),
            notificationEnabled,
            (v) => setState(() => notificationEnabled = v),
          ),

          _switch(
            "settings.show_balance".tr(),
            showBalance,
            (v) => setState(() => showBalance = v),
          ),

          _switch(
            "settings.auto_backup".tr(),
            autoBackup,
            (v) => setState(() => autoBackup = v),
          ),

          if (autoBackup)
            _dropdown(
              value: backupFrequency,
              items: {
                "daily": "Hàng ngày",
                "weekly": "Hàng tuần",
                "monthly": "Hàng tháng",
              },
              onChanged: (v) => setState(() => backupFrequency = v!),
            ),

          const SizedBox(height: 20),

          Text(
            "settings.reminder_time".tr(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          ListTile(
            title: Text(
              reminderTime.format(context),
              style: const TextStyle(fontSize: 16),
            ),
            trailing: const Icon(Icons.timer),
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: reminderTime,
              );
              if (picked != null) {
                setState(() => reminderTime = picked);
              }
            },
          ),

          const SizedBox(height: 30),

          ElevatedButton(
            onPressed: saveSettings,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              "common.save".tr(),
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dropdown({
    required String value,
    required Map<String, String> items,
    required Function(String?) onChanged,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          underline: const SizedBox(),
          items: items.entries
              .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _switch(String label, bool value, Function(bool) onChanged) {
    return Card(
      child: SwitchListTile(
        title: Text(label),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}
