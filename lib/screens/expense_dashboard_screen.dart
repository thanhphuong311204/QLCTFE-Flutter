import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../api/transaction_service.dart';
import '../models/transaction_model.dart';

class ExpenseDashboardScreen extends StatefulWidget {
  const ExpenseDashboardScreen({super.key});

  @override
  State<ExpenseDashboardScreen> createState() => _ExpenseDashboardScreenState();
}

class _ExpenseDashboardScreenState extends State<ExpenseDashboardScreen> {
  final TransactionService _transactionService = TransactionService();
  bool _isLoading = true;
  List<TransactionModel> _expenses = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final expenses = await _transactionService.getExpenses();
      setState(() => _expenses = expenses);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Lỗi khi tải dữ liệu: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalExpense = _expenses.fold<double>(0, (sum, e) => sum + e.amount);

    final Map<String, double> categoryTotals = {};
    for (var t in _expenses) {
      categoryTotals[t.categoryName] =
          (categoryTotals[t.categoryName] ?? 0) + t.amount;
    }

    final List<Color> colorPalette = [
      Colors.redAccent,
      Colors.orangeAccent,
      Colors.purpleAccent,
      Colors.teal,
      Colors.blueAccent,
      Colors.green,
      Colors.pinkAccent,
      Colors.indigo,
      Colors.brown,
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("📊 Thống kê chi tiêu"),
        backgroundColor: Colors.orange.shade100,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _expenses.isEmpty
              ? const Center(child: Text("📉 Chưa có dữ liệu chi tiêu"))
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildSummaryCard("Tổng chi", totalExpense, Colors.red),
                      const SizedBox(height: 24),
                      const Text(
                        "Phân bổ chi tiêu theo danh mục",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),

                      SizedBox(
                        height: 270,
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 0, 
                            borderData: FlBorderData(show: false),
                            sections: _buildChartSections(
                              categoryTotals,
                              colorPalette,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      ...categoryTotals.entries.map((e) {
                        final color = colorPalette[
                            categoryTotals.keys.toList().indexOf(e.key) %
                                colorPalette.length];
                        return ListTile(
                          leading: CircleAvatar(backgroundColor: color),
                          title: Text(
                            e.key,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          trailing: Text(
                            "${NumberFormat("#,##0", "vi_VN").format(e.value)} đ",
                            style: const TextStyle(color: Colors.black54),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
    );
  }

  List<PieChartSectionData> _buildChartSections(
    Map<String, double> data,
    List<Color> colors,
  ) {
    int i = 0;

    return data.entries.map((e) {
      final color = colors[i++ % colors.length];
      return PieChartSectionData(
        color: color,
        value: e.value,
        radius: 80,
        showTitle: false
      );
    }).toList();
  }

  Widget _buildSummaryCard(String title, double amount, Color color) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16)),
            Text(
              "${NumberFormat("#,##0", "vi_VN").format(amount)} đ",
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
