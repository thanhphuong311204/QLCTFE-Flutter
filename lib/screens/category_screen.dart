import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:qlctfe/api/auth_service.dart';
import 'package:qlctfe/api/category_service.dart';
import 'package:qlctfe/api/notification_service.dart';
import 'package:qlctfe/models/category_model.dart';
import 'package:qlctfe/screens/ai/ai_predict_screen.dart';
import 'package:qlctfe/screens/assistant_chat_screen.dart';
import 'package:qlctfe/screens/budget_screen.dart';
import 'package:qlctfe/screens/expense_dashboard_screen.dart';
import 'package:qlctfe/screens/goal_screen.dart';
import 'package:qlctfe/screens/income_dashboard_screen.dart';
import 'package:qlctfe/screens/login_screen.dart';
import 'package:qlctfe/screens/notification_screen.dart';
import 'package:qlctfe/screens/recurring_screen.dart';
import 'package:qlctfe/screens/register_screen.dart';
import 'package:qlctfe/screens/report_screen.dart';
import 'package:qlctfe/screens/settings_screen.dart';
import 'package:qlctfe/screens/transaction_form_screen.dart';
import 'package:qlctfe/screens/transaction_history_screen.dart';
import 'package:qlctfe/screens/wallet_screen.dart';

import '../../core/services/streak_provider.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({Key? key}) : super(key: key);

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final _auth = AuthService();
  final _categoryService = CategoryService();
  final _notiService = NotificationService();

  late Future<List<CategoryModel>> _categoriesFuture;
  int _unread = 0;

  @override
  void initState() {
    super.initState();
    _categoriesFuture = _categoryService.getPublicCategories();
    _loadUnreadNotifications();
  }

  Future<void> _loadUnreadNotifications() async {
    try {
      final list = await _notiService.getNotifications();
      setState(() {
        _unread = list.where((n) => n["isRead"] == false).length;
      });
    } catch (_) {}
  }

  Future<void> _requireLogin(VoidCallback action) async {
    final loggedIn = await _auth.isLoggin();
    if (!mounted) return;

    if (!loggedIn) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );

      if (result == 'register') {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RegisterScreen()),
        );
      }
    } else {
      action();
    }
  }

  Future<void> _logout() async {
    await _auth.logout();
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("🚪 Đã đăng xuất.")));

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Stack(
        children: [
          Scaffold(
            backgroundColor: const Color(0xFFFCF8F3),
            appBar: _buildAppBar(),
            body: FutureBuilder<List<CategoryModel>>(
              future: _categoriesFuture,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.orangeAccent),
                  );
                } else if (snap.hasError) {
                  return Center(child: Text("❌ Lỗi: ${snap.error}"));
                }

                final list = snap.data ?? [];
                final expenses =
                    list.where((c) => c.type == "expense").toList();
                final incomes =
                    list.where((c) => c.type == "income").toList();

                return TabBarView(
                  children: [
                    _buildCategoryGrid(expenses),
                    _buildCategoryGrid(incomes),
                  ],
                );
              },
            ),
            bottomNavigationBar: _buildBottomButtons(),
          ),

          // ⭐⭐⭐ FLOATING ASSISTANT CHAT BUBBLE ⭐⭐⭐
          Positioned(
            right: 18,
            bottom: 110,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AssistantChatScreen(),
                  ),
                );
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                width: 65,
                height: 65,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF7B61FF),
                      Color(0xFF9D4DFF),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.20),
                      blurRadius: 10,
                      offset: const Offset(0, 6),
                    )
                  ],
                ),
                child: const Icon(
                  Icons.smart_toy_outlined,
                  color: Colors.white,
                  size: 34,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.orange.shade100,
      elevation: 0,
      title: Text(
        'category_screen.title'.tr(),
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: Colors.black87,
        ),
      ),
      centerTitle: true,
      actions: [
        Consumer<StreakProvider>(
          builder: (context, streak, child) {
            return GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, "/streak-dashboard");
              },
              child: Padding(
                padding: const EdgeInsets.only(right: 12, top: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.local_fire_department,
                      color: Colors.orange.shade700,
                      size: 30,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "${streak.currentStreak}",
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),

        Stack(
          children: [
            IconButton(
              tooltip: "Thông báo",
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () async {
                try {
                  await _notiService.markAllAsRead();
                } catch (_) {}

                setState(() => _unread = 0);

                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotificationScreen()),
                );

                _loadUnreadNotifications();
              },
            ),
            if (_unread > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    "$_unread",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),

        IconButton(
          tooltip: "Cài đặt",
          icon: const Icon(Icons.settings),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            );
          },
        ),

        IconButton(
          icon: const Icon(Icons.person),
          onPressed: () {
            Navigator.pushNamed(context, "/profile");
          },
        ),

        Builder(
          builder: (appBarContext) {
            return IconButton(
              tooltip: "Menu",
              icon: const Icon(Icons.more_vert),
              onPressed: () => _openMenuSheet(appBarContext),
            );
          },
        ),
      ],
      bottom: const TabBar(
        labelColor: Colors.orange,
        unselectedLabelColor: Colors.grey,
        indicatorColor: Colors.orangeAccent,
        tabs: [
          Tab(text: "Chi tiêu"),
          Tab(text: "Thu nhập"),
        ],
      ),
    );
  }

  void _openMenuSheet(BuildContext parentContext) {
    showModalBottomSheet(
      context: parentContext,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _menuItem(Icons.bar_chart, "Thống kê", () {
                  Navigator.pop(sheetContext);

                  final controller = DefaultTabController.of(parentContext);
                  final index = controller?.index ?? 0;

                  final target = index == 0
                      ? const ExpenseDashboardScreen()
                      : const IncomeDashboardScreen();

                  Navigator.push(
                    parentContext,
                    MaterialPageRoute(builder: (_) => target),
                  );
                }),
                _menuItem(Icons.insert_chart, "Báo cáo tổng hợp", () {
                  Navigator.pop(sheetContext);
                  _requireLogin(
                    () => Navigator.push(
                      parentContext,
                      MaterialPageRoute(builder: (_) => const ReportScreen()),
                    ),
                  );
                }),
                _menuItem(Icons.auto_awesome, "AI dự đoán chi tiêu", () async {
                  Navigator.pop(sheetContext);

                  final profile = await _auth.getProfile();
                  final userId = profile?["id"];

                  if (userId == null) return;

                  _requireLogin(() {
                    Navigator.push(
                      parentContext,
                      MaterialPageRoute(
                        builder: (_) => AIPredictScreen(userId: userId),
                      ),
                    );
                  });
                }),
                _menuItem(Icons.autorenew, "Giao dịch định kỳ", () {
                  Navigator.pop(sheetContext);
                  _requireLogin(
                    () => Navigator.push(
                      parentContext,
                      MaterialPageRoute(builder: (_) => const RecurringScreen()),
                    ),
                  );
                }),
                _menuItem(Icons.history, "Lịch sử giao dịch", () {
                  Navigator.pop(sheetContext);
                  _requireLogin(
                    () => Navigator.push(
                      parentContext,
                      MaterialPageRoute(
                        builder: (_) => const TransactionHistoryScreen(),
                      ),
                    ),
                  );
                }),
                _menuItem(Icons.account_balance_wallet, "Ví", () {
                  Navigator.pop(sheetContext);
                  _requireLogin(
                    () => Navigator.push(
                      parentContext,
                      MaterialPageRoute(builder: (_) => const WalletScreen()),
                    ),
                  );
                }),
                _menuItem(Icons.flag_outlined, "Mục tiêu", () {
                  Navigator.pop(sheetContext);
                  _requireLogin(
                    () => Navigator.push(
                      parentContext,
                      MaterialPageRoute(builder: (_) => const GoalScreen()),
                    ),
                  );
                }),
                _menuItem(Icons.account_balance, "Ngân sách", () {
                  Navigator.pop(sheetContext);
                  _requireLogin(
                    () => Navigator.push(
                      parentContext,
                      MaterialPageRoute(builder: (_) => const BudgetScreen()),
                    ),
                  );
                }),
                const Divider(height: 25),
                _menuItem(Icons.logout, "Đăng xuất", () async {
                  Navigator.pop(sheetContext);
                  await _logout();
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _menuItem(IconData icon, String text, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, size: 28, color: Colors.orange.shade700),
      title: Text(
        text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      onTap: onTap,
    );
  }

  Widget _buildCategoryGrid(List<CategoryModel> list) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: list.length,
      itemBuilder: (context, i) {
        final cat = list[i];
        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _requireLogin(() async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TransactionFormScreen(
                  isExpense: cat.type == "expense",
                  categoryId: cat.categoryId,
                  categoryName: cat.categoryName,
                ),
              ),
            );
            if (result == "refresh") {
              _loadUnreadNotifications();
            }
          }),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(2, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.network(
                  cat.iconUrl ?? "",
                  height: 42,
                  width: 42,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.image_not_supported, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    cat.categoryName,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomButtons() {
    return FutureBuilder<List<CategoryModel>>(
      future: _categoriesFuture,
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox.shrink();

        final list = snap.data!;
        final defaultExpense = list.firstWhere(
          (c) => c.type == "expense" && c.categoryName == "Chi tiêu khác",
          orElse: () => CategoryModel(
            categoryId: 1,
            categoryName: "Chi tiêu khác",
            type: "expense",
          ),
        );

        final defaultIncome = list.firstWhere(
          (c) => c.type == "income" && c.categoryName == "Thu nhập khác",
          orElse: () => CategoryModel(
            categoryId: 2,
            categoryName: "Thu nhập khác",
            type: "income",
          ),
        );

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 30),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildActionButton(
                "Nhập khoản chi",
                Icons.remove_circle_outline,
                Colors.redAccent,
                () => _requireLogin(() async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TransactionFormScreen(
                        isExpense: true,
                        categoryId: defaultExpense.categoryId,
                        categoryName: defaultExpense.categoryName,
                      ),
                    ),
                  );

                  if (result == "refresh") {
                    _loadUnreadNotifications();
                  }
                }),
              ),

              _buildActionButton(
                "Nhập khoản thu",
                Icons.add_circle_outline,
                Colors.green,
                () => _requireLogin(() async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TransactionFormScreen(
                        isExpense: false,
                        categoryId: defaultIncome.categoryId,
                        categoryName: defaultIncome.categoryName,
                      ),
                    ),
                  );

                  if (result == "refresh") {
                    _loadUnreadNotifications();
                  }
                }),
              ),
            ],
          ),
        );
      },
    );
  }

  ElevatedButton _buildActionButton(
    String text,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.15),
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: Icon(icon),
      label: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
      onPressed: onTap,
    );
  }
}
