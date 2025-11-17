import 'package:flutter/material.dart';
import 'package:qlctfe/api/budget_service.dart';
import 'package:qlctfe/api/secure_storage.dart';
import 'package:qlctfe/api/api_constants.dart';
import 'package:qlctfe/models/budget_model.dart';
import 'package:qlctfe/models/category_model.dart';
import 'package:qlctfe/models/wallet_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({Key? key}) : super(key: key);

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final BudgetService _budgetService = BudgetService();
  late Future<List<Budget>> _budgetsFuture;

  @override
  void initState() {
    super.initState();
    _budgetsFuture = _budgetService.fetchBudgets();
  }

  // 🧮 Format tiền VND
  String _formatCurrency(double amount) {
    final format = NumberFormat("#,##0", "vi_VN");
    return "${format.format(amount)} ₫";
  }

  // 🟢 Hiển thị dialog thêm ngân sách
  void _showAddBudgetDialog() async {
    try {
      final categories = await fetchCategories();
      final wallets = await fetchWallets();

      CategoryModel? selectedCategory;
      Wallet? selectedWallet;
      final TextEditingController _limitCtrl = TextEditingController();

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: const Text("Thêm ngân sách mới"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 🔽 Dropdown chọn danh mục
                  DropdownButtonFormField<CategoryModel>(
                    decoration: const InputDecoration(labelText: "Danh mục"),
                    value: selectedCategory,
                    items: categories
                        .where((c) => c.type == "expense") // chỉ lấy loại chi tiêu
                        .map((c) => DropdownMenuItem(
                              value: c,
                              child: Text(c.categoryName),
                            ))
                        .toList(),
                    onChanged: (value) {
                      selectedCategory = value;
                    },
                  ),
                  const SizedBox(height: 10),

                  // 🔽 Dropdown chọn ví
                  DropdownButtonFormField<Wallet>(
                    decoration: const InputDecoration(labelText: "Ví (tùy chọn)"),
                    value: selectedWallet,
                    items: wallets
                        .map((w) => DropdownMenuItem(
                              value: w,
                              child: Text(w.walletName),
                            ))
                        .toList(),
                    onChanged: (value) {
                      selectedWallet = value;
                    },
                  ),
                  const SizedBox(height: 10),

                  // 🔢 Hạn mức
                  TextField(
                    controller: _limitCtrl,
                    decoration: const InputDecoration(labelText: "Hạn mức (VNĐ)"),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Hủy")),
              ElevatedButton(
                onPressed: () async {
                  if (selectedCategory == null || _limitCtrl.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text("Vui lòng chọn danh mục và nhập hạn mức")));
                    return;
                  }

                  await _budgetService.createBudget({
                    "categoryName": selectedCategory!.categoryName,
                    "walletName": selectedWallet?.walletName ?? "",
                    "amountLimit": double.tryParse(_limitCtrl.text) ?? 0,
                    "startDate": DateTime.now().toIso8601String(),
                    "endDate": DateTime.now()
                        .add(const Duration(days: 30))
                        .toIso8601String(),
                  });

                  Navigator.pop(context);
                  setState(() {
                    _budgetsFuture = _budgetService.fetchBudgets();
                  });
                },
                child: const Text("Lưu"),
              ),
            ],
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi khi tải dữ liệu: $e")),
      );
    }
  }

  // 🧱 Item hiển thị từng ngân sách
  Widget _buildBudgetCard(Budget budget) {
    final percent = (budget.spentAmount / budget.amountLimit).clamp(0, 1);
    final progressColor = percent >= 0.9
        ? Colors.red
        : (percent >= 0.7 ? Colors.orange : Colors.green);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              budget.categoryName ?? "Không có danh mục",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: percent.toDouble(),
              color: progressColor,
              backgroundColor: Colors.grey[300],
              minHeight: 8,
              borderRadius: BorderRadius.circular(10),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Đã chi: ${_formatCurrency(budget.spentAmount)}"),
                Text("Giới hạn: ${_formatCurrency(budget.amountLimit)}"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 🧩 UI tổng thể
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ngân sách"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_outlined),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddBudgetDialog,
          ),
        ],
      ),
      body: FutureBuilder<List<Budget>>(
        future: _budgetsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Lỗi: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Chưa có ngân sách nào"));
          }

          final budgets = snapshot.data!;
          return ListView.builder(
            itemCount: budgets.length,
            itemBuilder: (context, index) =>
                _buildBudgetCard(budgets[index]),
          );
        },
      ),
    );
  }

  // 🧠 Load danh mục
  Future<List<CategoryModel>> fetchCategories() async {
    final token = await SecureStorage().getToken();
    final res = await http.get(
      Uri.parse("${ApiConstants.categories}"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (res.statusCode == 200) {
      List data = json.decode(res.body);
      return data.map((e) => CategoryModel.fromJson(e)).toList();
    } else {
      throw Exception("Lỗi tải danh mục: ${res.statusCode}");
    }
  }

  // 💰 Load ví
  Future<List<Wallet>> fetchWallets() async {
    final token = await SecureStorage().getToken();
    print("🔑 Token gửi tới backend: $token");
    final res = await http.get(
      Uri.parse("${ApiConstants.wallets}"),
      headers: {"Authorization": "Bearer $token"},
    );
    if (res.statusCode == 200) {
      List data = json.decode(res.body);
      return data.map((e) => Wallet.fromJson(e)).toList();
    } else {
      throw Exception("Lỗi tải ví: ${res.statusCode}");
    }
  }
}
