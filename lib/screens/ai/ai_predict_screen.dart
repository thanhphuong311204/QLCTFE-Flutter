import 'package:flutter/material.dart';
import 'package:qlctfe/api/ai_prediction_service.dart';

class AIPredictScreen extends StatefulWidget {
  final int userId;

  const AIPredictScreen({super.key, required this.userId});

  @override
  State<AIPredictScreen> createState() => _AIPredictScreenState();
}

class _AIPredictScreenState extends State<AIPredictScreen> {
  final aiService = AIPredictionService();

  bool loading = true;
  Map<String, dynamic>? result;

  String formatVND(num value) {
    final str = value.toStringAsFixed(0);
    return str.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }

  @override
  void initState() {
    super.initState();
    loadAI();
  }

  Future<void> loadAI() async {
    final data = await aiService.predictSpending(
      widget.userId,
      DateTime.now().month,
    );

    setState(() {
      result = data;
      loading = false;
    });
  }

  Widget buildCard(String title, Widget child, {Color? color}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87)),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget buildWeekRow(String label, num spent, num suggest) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text("Đã tiêu: ${formatVND(spent)} VND",
              style: TextStyle(color: Colors.grey.shade700)),
          Text("Gợi ý: ${formatVND(suggest)} VND",
              style: const TextStyle(fontWeight: FontWeight.w600)),
          const Divider(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final predicted = (result?['predicted'] ?? 0) as num;
    final actual = (result?['actual'] ?? 0) as num;

    // Gợi ý tuần
    final w1 = (result?['week1'] ?? 0) as num;
    final w2 = (result?['week2'] ?? 0) as num;
    final w3 = (result?['week3'] ?? 0) as num;
    final w4 = (result?['week4'] ?? 0) as num;

    // Đã tiêu từng tuần
    final sw1 = (result?['spent_week1'] ?? 0) as num;
    final sw2 = (result?['spent_week2'] ?? 0) as num;
    final sw3 = (result?['spent_week3'] ?? 0) as num;
    final sw4 = (result?['spent_week4'] ?? 0) as num;

    return Scaffold(
      backgroundColor: const Color(0xFFFCF8F3),
      appBar: AppBar(
        backgroundColor: Colors.orange.shade100,
        elevation: 0,
        title: const Text("AI dự đoán chi tiêu",
            style: TextStyle(fontWeight: FontWeight.w700, color: Colors.black)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : result == null
              ? const Center(child: Text("Không có dữ liệu"))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      // Tổng dự đoán
                      buildCard(
                        "Dự đoán tháng này",
                        Text(
                          "${formatVND(predicted)} VND",
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                      ),

                      // Chi tiêu tháng
                      buildCard(
                        "Đã tiêu",
                        Text(
                          "${formatVND(actual)} VND",
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        color: Colors.orange.shade50,
                      ),

                      // Gợi ý theo tuần đẹp chuẩn ngân hàng
                      buildCard(
                        "Chi tiêu theo tuần (AI phân tích)",
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            buildWeekRow("Tuần 1", sw1, w1),
                            buildWeekRow("Tuần 2", sw2, w2),
                            buildWeekRow("Tuần 3", sw3, w3),
                            buildWeekRow("Tuần 4", sw4, w4),
                          ],
                        ),
                        color: Colors.orange.shade50,
                      ),

                      // Cảnh báo thông minh
                      buildCard(
                        actual > predicted
                            ? "⚠ Chi tiêu vượt mức!"
                            : "Chi tiêu ổn định",
                        Text(
                          actual > predicted
                              ? "Bạn đang tiêu vượt dự đoán AI."
                              : "Bạn đang chi tiêu hợp lý.",
                          style: TextStyle(
                              fontSize: 16,
                              color: actual > predicted
                                  ? Colors.red.shade700
                                  : Colors.green.shade700,
                              fontWeight: FontWeight.w600),
                        ),
                        color: actual > predicted
                            ? Colors.red.shade100
                            : Colors.green.shade100,
                      ),
                    ],
                  ),
                ),
    );
  }
}
