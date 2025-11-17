import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../api/goal_service.dart';
import '../api/category_service.dart';
import '../api/wallet_service.dart';
import '../models/goal_model.dart';
import '../models/category_model.dart';
import '../models/wallet_model.dart';

class GoalScreen extends StatefulWidget {
  const GoalScreen({super.key});

  @override
  State<GoalScreen> createState() => _GoalScreenState();
}

class _GoalScreenState extends State<GoalScreen> {
  final GoalService _goalService = GoalService();
  final CategoryService _categoryService = CategoryService();
  final WalletService _walletService = WalletService();

  late Future<List<GoalModel>> _goals;
  List<CategoryModel> _categories = [];
  List<Wallet> _wallets = [];

  @override
  void initState() {
    super.initState();
    _goals = _goalService.getGoals(); // ✅ Không dùng setState() ở đây
    _loadDropdownData();
  }

  /// ✅ Chỉ dùng setState() để gán dữ liệu đã load xong
  Future<void> _loadDropdownData() async {
    try {
      final cats = await _categoryService.getCategories();
      final wallets = await _walletService.getWallets();
      if (!mounted) return;
      setState(() {
        _categories = cats;
        _wallets = wallets;
      });
    } catch (e) {
      print("⚠️ Lỗi load dropdown: $e");
    }
  }

  /// ✅ Tải lại danh sách mục tiêu (dùng để refresh)
  Future<void> _refreshGoals() async {
    final refreshed = _goalService.getGoals();
    if (!mounted) return;
    setState(() {
      _goals = refreshed;
    });
  }

  Future<void> _deleteGoal(int id) async {
    try {
      await _goalService.deleteGoal(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("🗑️ Xoá mục tiêu thành công")),
      );
      _refreshGoals();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Lỗi khi xoá mục tiêu: $e")),
      );
    }
  }

  Future<void> _addGoalDialog() async {
    final nameController = TextEditingController();
    final targetController = TextEditingController();
    CategoryModel? selectedCategory;
    Wallet? selectedWallet;
    DateTime? selectedDate;

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text("🎯 Thêm mục tiêu mới"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: "Tên mục tiêu"),
                ),
                TextField(
                  controller: targetController,
                  decoration: const InputDecoration(labelText: "Số tiền cần đạt"),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<Wallet>(
                  value: selectedWallet,
                  items: _wallets
                      .map((w) => DropdownMenuItem(
                            value: w,
                            child: Text(w.walletName),
                          ))
                      .toList(),
                  onChanged: (w) => setStateDialog(() => selectedWallet = w),
                  decoration: const InputDecoration(labelText: "Chọn ví"),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<CategoryModel>(
                  value: selectedCategory,
                  items: _categories
                      .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text(c.categoryName),
                          ))
                      .toList(),
                  onChanged: (c) => setStateDialog(() => selectedCategory = c),
                  decoration: const InputDecoration(labelText: "Chọn danh mục"),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        selectedDate == null
                            ? "Chưa chọn hạn"
                            : "Hạn: ${DateFormat('dd/MM/yyyy').format(selectedDate!)}",
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.calendar_month),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setStateDialog(() => selectedDate = picked);
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Huỷ"),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final target = double.tryParse(targetController.text) ?? 0;

                if (name.isEmpty ||
                    target <= 0 ||
                    selectedWallet == null ||
                    selectedCategory == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("⚠️ Vui lòng nhập đầy đủ thông tin")),
                  );
                  return;
                }

                await _goalService.addGoal({
                  "goalName": name,
                  "targetAmount": target,
                  "currentAmount": 0,
                  "walletName": selectedWallet!.walletName,
                  "categoryName": selectedCategory!.categoryName,
                  "deadline": selectedDate?.toIso8601String(),
                });

                if (!mounted) return;
                Navigator.pop(context);
                _refreshGoals();
              },
              child: const Text("Thêm"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateProgressDialog(int goalId) async {
    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("➕ Cập nhật tiến độ"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: "Nhập số tiền muốn thêm (đ)",
            hintText: "VD: 500000",
          ),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Huỷ"),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(controller.text.trim()) ?? 0;
              if (amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("⚠️ Nhập số tiền hợp lệ!")),
                );
                return;
              }

              try {
                await _goalService.updateProgress(goalId, amount);
                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("✅ Cập nhật tiến độ thành công!")),
                );
                _refreshGoals();
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("❌ Lỗi cập nhật tiến độ: $e")),
                );
              }
            },
            child: const Text("Lưu"),
          ),
        ],
      ),
    );
  }

  Color _getProgressColor(double percent) {
    if (percent >= 100) return Colors.green;
    if (percent >= 50) return Colors.orange;
    return Colors.redAccent;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCF8F3),
      appBar: AppBar(
        title: const Text("🎯 Mục tiêu tài chính"),
        backgroundColor: Colors.orange.shade100,
        centerTitle: true,
      ),
      body: FutureBuilder<List<GoalModel>>(
        future: _goals,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            print("⚠️ Error loading goals: ${snapshot.error}");
            return Center(child: Text("❌ Lỗi: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Chưa có mục tiêu nào."));
          }

          final goals = snapshot.data!;
          return RefreshIndicator(
            onRefresh: _refreshGoals,
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: goals.length,
              itemBuilder: (context, index) {
                final g = goals[index];
                final percent = g.targetAmount == 0
                    ? 0.0
                    : (g.currentAmount / g.targetAmount) * 100;
                final isCompleted = percent >= 100;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                g.goalName,
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline,
                                      color: Colors.blueAccent),
                                  tooltip: "Cập nhật tiến độ",
                                  onPressed: () => _updateProgressDialog(g.goalId),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      color: Colors.redAccent),
                                  onPressed: () => _deleteGoal(g.goalId),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Mục tiêu: ${NumberFormat("#,##0", "vi_VN").format(g.targetAmount)} đ",
                          style: const TextStyle(color: Colors.black54),
                        ),
                        Text(
                          "Đã đạt: ${NumberFormat("#,##0", "vi_VN").format(g.currentAmount)} đ",
                          style: const TextStyle(color: Colors.black54),
                        ),
                        const SizedBox(height: 6),
                        LinearProgressIndicator(
                          value: (percent / 100).clamp(0.0, 1.0),
                          backgroundColor: Colors.grey.shade200,
                          color: _getProgressColor(percent),
                          minHeight: 8,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isCompleted
                                  ? "🎉 Hoàn thành mục tiêu!"
                                  : "Tiến độ: ${percent.toStringAsFixed(1)}%",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _getProgressColor(percent),
                              ),
                            ),
                            if (g.deadline != null)
                              Text(
                                "⏰ ${DateFormat('dd/MM/yyyy').format(g.deadline!)}",
                                style: const TextStyle(
                                    fontSize: 13, color: Colors.black54),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orangeAccent,
        onPressed: _addGoalDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
