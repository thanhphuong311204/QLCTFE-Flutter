import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../api/transaction_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TransactionService _transactionService = TransactionService();

  bool _loading = true;
  double totalIncome = 0;
  double totalExpense = 0;
  Map<String, double> categoryTotals = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final incomes = await _transactionService.getIncomes();
      final expenses = await _transactionService.getExpenses();

      // Tổng thu & chi
      totalIncome = incomes.fold(0, (sum, t) => sum + t.amount);
      totalExpense = expenses.fold(0, (sum, t) => sum + t.amount);

      // Gom chi tiêu theo danh mục
      categoryTotals.clear();
      for (var t in expenses) {
        categoryTotals[t.categoryName] =
            (categoryTotals[t.categoryName] ?? 0) + t.amount;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Lỗi tải dữ liệu: $e")),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  String _fmt(double value) {
    return NumberFormat.currency(locale: "vi_VN", symbol: "đ", decimalDigits: 0)
        .format(value);
  }

  @override
  Widget build(BuildContext context) {
    final balance = totalIncome - totalExpense;

    return Scaffold(
      appBar: AppBar(
        title: const Text("📊 Thống kê tổng quan"),
        backgroundColor: Colors.orange.shade100,
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // 🧾 Tổng thu – chi – số dư
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSummaryRow("💰 Tổng thu", totalIncome, Colors.green),
                          const SizedBox(height: 6),
                          _buildSummaryRow("💸 Tổng chi", totalExpense, Colors.redAccent),
                          const Divider(),
                          _buildSummaryRow(
                            "🧮 Cân đối",
                            balance,
                            balance >= 0 ? Colors.green : Colors.redAccent,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 🥧 Biểu đồ tròn
                  if (categoryTotals.isNotEmpty) ...[
                    const Text(
                      "Phân bổ chi tiêu theo danh mục",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 250,
                      child: PieChart(
                        PieChartData(
                          sections: categoryTotals.entries.map((e) {
                            final percent =
                                (e.value / totalExpense * 100).toStringAsFixed(1);
                            return PieChartSectionData(
                              title: "${e.key}\n$percent%",
                              value: e.value,
                              radius: 70,
                              titleStyle: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            );
                          }).toList(),
                          sectionsSpace: 2,
                          centerSpaceRadius: 40,
                        ),
                      ),
                    ),
                  ] else
                    const Center(
                        child: Text("Chưa có dữ liệu chi tiêu để hiển thị")),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryRow(String label, double value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        Text(
          _fmt(value),
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}
