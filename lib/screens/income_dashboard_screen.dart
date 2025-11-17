import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../api/transaction_service.dart';
import '../models/transaction_model.dart';

class IncomeDashboardScreen extends StatefulWidget {
  const IncomeDashboardScreen({super.key});

  @override
  State<IncomeDashboardScreen> createState() => _IncomeDashboardScreenState();
}

class _IncomeDashboardScreenState extends State<IncomeDashboardScreen> {
  final TransactionService _transactionService = TransactionService();
  bool _isLoading = true;
  List<TransactionModel> _incomes = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final incomes = await _transactionService.getIncomes();
      setState(() => _incomes = incomes);
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
    final totalIncome = _incomes.fold<double>(0, (sum, e) => sum + e.amount);

    final Map<String, double> categoryTotals = {};
    for (var t in _incomes) {
      categoryTotals[t.categoryName] =
          (categoryTotals[t.categoryName] ?? 0) + t.amount;
    }

    final List<Color> colorPalette = [
      Colors.green,
      Colors.teal,
      Colors.orangeAccent,
      Colors.purpleAccent,
      Colors.blueAccent,
      Colors.pinkAccent,
      Colors.indigo,
      Colors.brown,
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFFDF8F2),
      appBar: AppBar(
        backgroundColor: Colors.orange.shade100,
        title: const Text(
          "📈 Thống kê thu nhập",
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _incomes.isEmpty
              ? const Center(
                  child: Text(
                    "📉 Chưa có dữ liệu thu nhập nào.\nHãy thêm khoản thu trước nhé!",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildSummaryCard("Tổng thu", totalIncome, Colors.green),
                      const SizedBox(height: 24),
                      const Text(
                        "Phân bổ thu nhập theo danh mục",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 16),

                      // 🔵 Biểu đồ tròn (hiển thị giá trị tiền)
                      SizedBox(
                        height: 270,
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 0, // ✅ Không donut
                            borderData: FlBorderData(show: false),
                            sections: _buildChartSections(
                              categoryTotals,
                              colorPalette,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // 📋 Ghi chú danh mục + giá trị
                      ...categoryTotals.entries.map((e) {
                        final color = colorPalette[
                            categoryTotals.keys.toList().indexOf(e.key) %
                                colorPalette.length];
                        return ListTile(
                          leading: CircleAvatar(backgroundColor: color),
                          title: Text(e.key,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600)),
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
    final format = NumberFormat("#,##0", "vi_VN");
    return data.entries.map((e) {
      final color = colors[i++ % colors.length];
      return PieChartSectionData(
        color: color,
        value: e.value,
        radius: 80,
        title: "${format.format(e.value)} đ", // ✅ chỉ hiển thị giá trị tiền
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
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
                  color: color, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
