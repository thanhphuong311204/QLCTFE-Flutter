import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qlctfe/api/budget_service.dart';
import 'package:qlctfe/models/budget_model.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:easy_localization/easy_localization.dart';

class BudgetCalendarScreen extends StatefulWidget {
  const BudgetCalendarScreen({super.key});

  @override
  State<BudgetCalendarScreen> createState() => _BudgetCalendarScreenState();
}

class _BudgetCalendarScreenState extends State<BudgetCalendarScreen> {
  final BudgetService _budgetService = BudgetService();
  late Future<List<Budget>> _budgetsFuture;

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  DateTime _selectedMonth = DateTime.now();

  // Map để lưu ngày nào có ngân sách (dấu chấm)
  Map<DateTime, List<Budget>> _events = {};

  @override
  void initState() {
    super.initState();
    _budgetsFuture = _budgetService.fetchBudgets();
  }

  // 🧩 Lọc ngân sách theo tháng đang chọn
  List<Budget> _filterByMonth(List<Budget> budgets) {
    return budgets.where((b) {
      final start =
          DateTime.tryParse(b.startDate?.toString() ?? "") ?? DateTime.now();
      return start.year == _selectedMonth.year &&
          start.month == _selectedMonth.month;
    }).toList();
  }

  // 📍 Tạo map sự kiện (ngày có ngân sách)
  Map<DateTime, List<Budget>> _groupBudgetsByDate(List<Budget> budgets) {
    final Map<DateTime, List<Budget>> data = {};
    for (var b in budgets) {
      final start = DateTime.tryParse(b.startDate?.toString() ?? "");
      if (start != null) {
        final date = DateTime(start.year, start.month, start.day);
        if (data[date] == null) {
          data[date] = [];
        }
        data[date]!.add(b);
      }
    }
    return data;
  }

  // 💰 Format tiền
  String _formatCurrency(double value) {
    final format = NumberFormat("#,##0", "vi_VN");
    return "${format.format(value)} ₫";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("budget.budget_calendar".tr())),
      body: FutureBuilder<List<Budget>>(
        future: _budgetsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Lỗi: ${snapshot.error}"));
          }

          final allBudgets = snapshot.data ?? [];
          final monthBudgets = _filterByMonth(allBudgets);
          _events = _groupBudgetsByDate(allBudgets);

          return Column(
            children: [
              TableCalendar(
                focusedDay: _focusedDay,
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                calendarFormat: CalendarFormat.month,
                locale: 'vi_VN',
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),

                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                    _selectedMonth = selectedDay;
                  });
                },

                onPageChanged: (focusedDay) {
                  setState(() {
                    _focusedDay = focusedDay;
                    _selectedMonth = focusedDay;
                  });
                },

                headerStyle: const HeaderStyle(
                  titleCentered: true,
                  formatButtonVisible: false,
                ),

                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: Colors.orange.shade300,
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: const BoxDecoration(
                    color: Colors.blueAccent,
                    shape: BoxShape.circle,
                  ),
                  markersMaxCount: 1,
                  markerDecoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),

                eventLoader: (day) {
                  final date = DateTime(day.year, day.month, day.day);
                  return _events[date] ?? [];
                },
              ),

              const SizedBox(height: 10),

              Text(
                "budget.budget_for_month".tr(
                  args: [DateFormat('MM/yyyy').format(_selectedMonth)],
                ),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              Expanded(
                child: monthBudgets.isEmpty
                    ? Center(child: Text("budget.no_budget_this_month".tr()))
                    : ListView.builder(
                        itemCount: monthBudgets.length,
                        itemBuilder: (context, index) {
                          final b = monthBudgets[index];
                          final ratio = (b.spentAmount / b.amountLimit * 100)
                              .clamp(0, 100);
                          final color = ratio >= 90
                              ? Colors.red
                              : (ratio >= 70 ? Colors.orange : Colors.green);

                          return ListTile(
                            leading: Icon(Icons.circle, color: color, size: 12),
                            title: Text(b.categoryName ?? ""),
                            subtitle: Text(
                              "${"budget.spent_label".tr()}: ${_formatCurrency(b.spentAmount)} / "
                              "${_formatCurrency(b.amountLimit)} (${ratio.toStringAsFixed(1)}%)",
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
