import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:qlctfe/models/budget_model.dart';
import 'package:intl/intl.dart';

class BudgetChartScreen extends StatelessWidget {
  final List<Budget> budgets;

  const BudgetChartScreen({super.key, required this.budgets});

  String _formatCurrency(double value) {
    final format = NumberFormat.compact(locale: 'vi_VN'); // gọn gàng: 3.5M, 500K
    return "${format.format(value)} ₫";
  }

  @override
  Widget build(BuildContext context) {
    if (budgets.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Thống kê ngân sách")),
        body: const Center(child: Text("Chưa có dữ liệu ngân sách")),
      );
    }

    final sorted = [...budgets]..sort((a, b) => b.amountLimit.compareTo(a.amountLimit));
    final maxLimit =
        sorted.map((b) => b.amountLimit).reduce((a, b) => a > b ? a : b);

    return Scaffold(
      appBar: AppBar(title: const Text("Thống kê ngân sách")),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              "Biểu đồ chi tiêu so với hạn mức",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),

            // === Biểu đồ cột kép ===
            Expanded(
              child: BarChart(
                BarChartData(
                  maxY: maxLimit * 1.1,
                  barGroups: List.generate(sorted.length, (i) {
                    final b = sorted[i];
                    final color = Colors.blueAccent;
                    final spentColor = b.spentAmount >= b.amountLimit
                        ? Colors.redAccent
                        : Colors.green;

                    return BarChartGroupData(
                      x: i,
                      barsSpace: 12,
                      barRods: [
                        // Hạn mức (xám)
                        BarChartRodData(
                          toY: b.amountLimit,
                          color: Colors.grey.shade400,
                          width: 14,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        // Đã chi (xanh hoặc đỏ)
                        BarChartRodData(
                          toY: b.spentAmount,
                          color: spentColor,
                          width: 14,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ],
                    );
                  }),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final i = value.toInt();
                          if (i < 0 || i >= sorted.length) return const SizedBox.shrink();
                          final name = sorted[i].categoryName ?? '';
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              name.length > 8 ? '${name.substring(0, 8)}…' : name,
                              style: const TextStyle(fontSize: 11),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 45,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            _formatCurrency(value),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawHorizontalLine: true,
                    horizontalInterval: maxLimit / 4,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.grey.shade300,
                      strokeWidth: 0.8,
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade400, width: 1),
                      left: BorderSide(color: Colors.grey.shade400, width: 1),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // === Chú thích ===
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.square, color: Colors.grey, size: 12),
                SizedBox(width: 4),
                Text("Hạn mức", style: TextStyle(fontSize: 12)),
                SizedBox(width: 16),
                Icon(Icons.square, color: Colors.green, size: 12),
                SizedBox(width: 4),
                Text("Đã chi", style: TextStyle(fontSize: 12)),
                SizedBox(width: 16),
                Icon(Icons.square, color: Colors.redAccent, size: 12),
                SizedBox(width: 4),
                Text("Vượt hạn mức", style: TextStyle(fontSize: 12)),
              ],
            ),

            const SizedBox(height: 12),

            // === Danh sách chi tiết ===
            Expanded(
              child: ListView.builder(
                itemCount: sorted.length,
                itemBuilder: (context, index) {
                  final b = sorted[index];
                  final ratio =
                      (b.spentAmount / b.amountLimit * 100).clamp(0, 100);
                  final color = b.spentAmount >= b.amountLimit
                      ? Colors.redAccent
                      : (ratio >= 70 ? Colors.orange : Colors.green);
                  return ListTile(
                    leading:
                        Icon(Icons.circle, color: color, size: 12),
                    title: Text(b.categoryName ?? ""),
                    subtitle: Text(
                      "Đã chi: ${_formatCurrency(b.spentAmount)} / ${_formatCurrency(b.amountLimit)} (${ratio.toStringAsFixed(1)}%)",
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
