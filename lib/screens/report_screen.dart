import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:qlctfe/api/report_service.dart';
import 'package:qlctfe/models/report_model.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({Key? key}) : super(key: key);

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final ReportService _reportService = ReportService();
  late Future<List<ReportModel>> _reportsFuture;
  int selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _reportsFuture = _reportService.fetchReports();
  }

  String _formatMoney(double value) {
    final format = NumberFormat("#,##0", "vi_VN");
    return "${format.format(value)} ₫";
  }

  List<ReportModel> _filterByYear(List<ReportModel> allReports) {
    return allReports.where((r) => r.startDate.year == selectedYear).toList();
  }

  Map<String, double> _calculateYearTotals(List<ReportModel> reports) {
    double totalIncome = 0;
    double totalExpense = 0;
    for (var r in reports) {
      totalIncome += r.totalIncome;
      totalExpense += r.totalExpense;
    }
    return {"income": totalIncome, "expense": totalExpense};
  }

  // 🟢 Tạo báo cáo – phiên bản đã sửa lỗi async trong setState
  void _showCreateDialog() {
    String? selectedType;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Tạo báo cáo mới"),
        content: DropdownButtonFormField<String>(
          decoration: const InputDecoration(labelText: "Loại báo cáo"),
          items: const [
            DropdownMenuItem(value: "WEEKLY", child: Text("Báo cáo tuần")),
            DropdownMenuItem(value: "MONTHLY", child: Text("Báo cáo tháng")),
            DropdownMenuItem(value: "YEARLY", child: Text("Báo cáo năm")),
          ],
          onChanged: (v) => selectedType = v,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (selectedType != null) {
                DateTime now = DateTime.now();
                DateTime start, end;

                if (selectedType == "WEEKLY") {
                  start = now.subtract(Duration(days: now.weekday - 1));
                  end = start.add(const Duration(days: 6));
                } else if (selectedType == "MONTHLY") {
                  start = DateTime(now.year, now.month, 1);
                  end = DateTime(now.year, now.month + 1, 0);
                } else {
                  start = DateTime(now.year, 1, 1);
                  end = DateTime(now.year, 12, 31);
                }

                // Gọi API tạo báo cáo
                await _reportService.createReport({
                  "reportType": selectedType!,
                  "startDate": start.toIso8601String(),
                  "endDate": end.toIso8601String(),
                });

                // Tải lại dữ liệu báo cáo – KHÔNG dùng async trong setState
                final newFuture = _reportService.fetchReports();
                setState(() {
                  _reportsFuture = newFuture;
                });

                Navigator.pop(context);
              }
            },
            child: const Text("Tạo"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Báo cáo & Thống kê"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_chart),
            onPressed: _showCreateDialog,
          ),
        ],
      ),
      body: FutureBuilder<List<ReportModel>>(
        future: _reportsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Lỗi: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Chưa có báo cáo nào"));
          }

          final reports = _filterByYear(snapshot.data!);
          if (reports.isEmpty) {
            return Center(child: Text("Không có dữ liệu cho năm $selectedYear"));
          }

          final totals = _calculateYearTotals(reports);

          return Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Chọn năm:", style: TextStyle(fontWeight: FontWeight.bold)),
                    DropdownButton<int>(
                      value: selectedYear,
                      items: List.generate(5, (i) {
                        final y = DateTime.now().year - i;
                        return DropdownMenuItem(value: y, child: Text(y.toString()));
                      }),
                      onChanged: (val) {
                        if (val != null) setState(() => selectedYear = val);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                Expanded(
                  flex: 2,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      borderData: FlBorderData(show: false),
                      gridData: FlGridData(show: true),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index >= reports.length) return Container();
                              return Text(
                                DateFormat('MM').format(reports[index].startDate),
                                style: const TextStyle(fontSize: 11),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: true, reservedSize: 45),
                        ),
                      ),
                      barGroups: reports.asMap().entries.map((entry) {
                        final i = entry.key;
                        final r = entry.value;
                        return BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(toY: r.totalIncome, color: Colors.green, width: 12),
                            BarChartRodData(toY: r.totalExpense, color: Colors.red, width: 12),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Expanded(
                  flex: 1,
                  child: PieChart(
                    PieChartData(
                      sections: [
                        PieChartSectionData(
                          value: totals["income"],
                          title: "Thu",
                          color: Colors.green,
                          radius: 60,
                        ),
                        PieChartSectionData(
                          value: totals["expense"],
                          title: "Chi",
                          color: Colors.red,
                          radius: 60,
                        ),
                      ],
                      centerSpaceRadius: 40,
                    ),
                  ),
                ),

                const SizedBox(height: 10),
                Text(
                  "Tổng thu: ${_formatMoney(totals["income"]!)}   |   Tổng chi: ${_formatMoney(totals["expense"]!)}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),

                const Divider(height: 25),

                Expanded(
                  flex: 2,
                  child: ListView.builder(
                    itemCount: reports.length,
                    itemBuilder: (context, index) {
                      final r = reports[index];
                      return Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          title: Text("Báo cáo: ${r.reportType}"),
                          subtitle: Text(
                            "Từ ${DateFormat('dd/MM').format(r.startDate)} - ${DateFormat('dd/MM').format(r.endDate)}",
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text("Thu: ${_formatMoney(r.totalIncome)}",
                                  style: const TextStyle(color: Colors.green)),
                              Text("Chi: ${_formatMoney(r.totalExpense)}",
                                  style: const TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
