import 'package:flutter/material.dart';
import 'package:qlctfe/api/setting_service.dart';
import 'package:intl/intl.dart';

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
      final data = await _service.getSettings();

      setState(() {
        language = data["language"] ?? "vi";
        currency = data["currency"] ?? "VND";
        notificationEnabled = data["notificationEnabled"] == true;
        showBalance = data["showBalanceOnHome"] == true;
        autoBackup = data["autoBackup"] == true;
        backupFrequency = data["backupFrequency"] ?? "weekly";

        if (data["reminderTime"] != null) {
          final t = data["reminderTime"].split(":");
          reminderTime =
              TimeOfDay(hour: int.parse(t[0]), minute: int.parse(t[1]));
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✔ Đã lưu")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Lỗi lưu: $e")),
      );
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
      appBar: AppBar(
        title: const Text("Cài đặt"),
        backgroundColor: Colors.orange.shade200,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text("Ngôn ngữ", style: TextStyle(fontWeight: FontWeight.bold)),
          _dropdown(
            value: language,
            items: const {"vi": "Tiếng Việt", "en": "English"},
            onChanged: (v) => setState(() => language = v!),
          ),

          const SizedBox(height: 14),

          const Text("Đơn vị tiền tệ", style: TextStyle(fontWeight: FontWeight.bold)),
          _dropdown(
            value: currency,
            items: const {"VND": "VND", "USD": "USD"},
            onChanged: (v) => setState(() => currency = v!),
          ),

          const SizedBox(height: 20),

          _switch("Thông báo", notificationEnabled,
              (v) => setState(() => notificationEnabled = v)),

          _switch("Hiện số dư ở trang chủ", showBalance,
              (v) => setState(() => showBalance = v)),

          _switch("Tự động sao lưu", autoBackup,
              (v) => setState(() => autoBackup = v)),

          if (autoBackup)
            _dropdown(
              value: backupFrequency,
              items: const {
                "daily": "Hàng ngày",
                "weekly": "Hàng tuần",
                "monthly": "Hàng tháng",
              },
              onChanged: (v) => setState(() => backupFrequency = v!),
            ),

          const SizedBox(height: 20),

          const Text("Giờ nhắc nhở",
              style: TextStyle(fontWeight: FontWeight.bold)),
          ListTile(
            title: Text(
              "${reminderTime.format(context)}",
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
            child: const Text("Lưu",
                style: TextStyle(color: Colors.white, fontSize: 16)),
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
              .map((e) => DropdownMenuItem(
                    value: e.key,
                    child: Text(e.value),
                  ))
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
