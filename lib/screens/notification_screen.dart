import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:qlctfe/api/notification_service.dart';

// 👉 IMPORT các màn hình đích
import 'package:qlctfe/screens/transaction_history_screen.dart';
import 'package:qlctfe/screens/income_dashboard_screen.dart';
import 'package:qlctfe/screens/budget_screen.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final _service = NotificationService();
  late Future<List<dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.getNotifications();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _service.getNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCF8F3),
      appBar: AppBar(
        title: Text("settings.notifications".tr()),
        backgroundColor: Colors.orange.shade100,
      ),
      body: FutureBuilder(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.orangeAccent),
            );
          }

          final list = snapshot.data!;

          if (list.isEmpty) {
            return const Center(child: Text("Không có thông báo nào"));
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: list.length,
              itemBuilder: (context, i) {
                final n = list[i];

                final bool isRead = n["isRead"] == true;

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: Icon(
                      Icons.notifications_active_outlined,
                      color: isRead ? Colors.grey : Colors.orange,
                      size: 28,
                    ),
                    title: Text(
                      (n["notificationTitle"] ?? "").toString(),
                      style: TextStyle(
                        fontWeight: isRead
                            ? FontWeight.normal
                            : FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      (n["notificationMessage"] ?? "").toString(),
                      style: const TextStyle(color: Colors.black54),
                    ),

                    onTap: () {
                      final refType = n["referenceType"];
                      final refId = n["referenceId"];
                      print("Tapped → $refType | $refId");

                      if (refType == null) return;

                      if (refType == "EXPENSE") {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TransactionHistoryScreen(),
                          ),
                        );
                      }

                      // INCOME → mở dashboard thu nhập
                      if (refType == "INCOME") {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const IncomeDashboardScreen(),
                          ),
                        );
                      }

                      // BUDGET → mở màn hình ngân sách
                      if (refType == "BUDGET") {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const BudgetScreen(),
                          ),
                        );
                      }
                    },

                    trailing: PopupMenuButton(
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: "read",
                          child: Text(isRead ? "Đã đọc" : "Đánh dấu đã đọc"),
                        ),
                        const PopupMenuItem(
                          value: "delete",
                          child: Text("Xóa"),
                        ),
                      ],
                      onSelected: (value) async {
                        if (value == "read") {
                          await _service.markAsRead(n["notificationId"]);
                        } else {
                          await _service.deleteNotification(
                            n["notificationId"],
                          );
                        }
                        _refresh();
                      },
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
