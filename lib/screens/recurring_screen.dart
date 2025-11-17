import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:qlctfe/api/api_constants.dart';
import 'package:qlctfe/api/secure_storage.dart';

class RecurringScreen extends StatefulWidget {
  const RecurringScreen({super.key});

  @override
  State<RecurringScreen> createState() => _RecurringScreenState();
}

class _RecurringScreenState extends State<RecurringScreen> {
  List<dynamic> recurringList = [];
  List<dynamic> categories = [];

  bool loading = true;

  final TextEditingController amountC = TextEditingController();
  final TextEditingController noteC = TextEditingController();

  int? selectedCategoryId;
  String frequency = "monthly";
  DateTime nextDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    loadCategories();
    loadRecurring();
  }

  // =============================
  // 🔥 Load danh mục
  // =============================
  Future<void> loadCategories() async {
    final token = await SecureStorage().getToken();

    final res = await http.get(
      Uri.parse(ApiConstants.categories),
      headers: {"Authorization": "Bearer $token"},
    );

    if (res.statusCode == 200) {
      setState(() {
        categories = json.decode(res.body);
      });
    } else {
      print("❌ Không load được categories: ${res.body}");
    }
  }

  // =============================
  // 🔥 Load danh sách recurring
  // =============================
  Future<void> loadRecurring() async {
    setState(() => loading = true);

    try {
      final token = await SecureStorage().getToken();
      final res = await http.get(
        Uri.parse(ApiConstants.recurring),
        headers: {"Authorization": "Bearer $token"},
      );

      if (res.statusCode == 200) {
        recurringList = json.decode(res.body);
      } else {
        print("❌ Load recurring thất bại: ${res.body}");
      }
    } catch (e) {
      print("❌ Load recurring lỗi: $e");
    }

    setState(() => loading = false);
  }

  // =============================
  // ➕ Tạo recurring
  // =============================
  Future<void> createRecurring() async {
    final token = await SecureStorage().getToken();

    final body = {
      "categoryId": selectedCategoryId, // ✔ ID danh mục
      "amount": double.tryParse(amountC.text) ?? 0,
      "note": noteC.text.trim(),
      "frequency": frequency,
      "nextDate": nextDate.toString().split(" ")[0], // ✔ yyyy-MM-dd
    };

    try {
      final res = await http.post(
        Uri.parse(ApiConstants.recurring),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: json.encode(body),
      );

      print("📩 API tạo recurring: ${res.statusCode} - ${res.body}");

      if (res.statusCode == 200 || res.statusCode == 201) {
        Navigator.pop(context);
        loadRecurring();
      } else {
        print("❌ Lỗi tạo recurring: ${res.body}");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Không thể tạo giao dịch định kỳ")),
        );
      }
    } catch (e) {
      print("❌ Lỗi tạo recurring: $e");
    }
  }

  // =============================
  // 🗑 Xóa
  // =============================
  Future<void> deleteRecurring(int id) async {
    final token = await SecureStorage().getToken();

    await http.delete(
      Uri.parse("${ApiConstants.recurring}/$id"),
      headers: {"Authorization": "Bearer $token"},
    );

    loadRecurring();
  }

  // =============================
  // ▶ Test chạy ngay
  // =============================
  Future<void> runNow() async {
    final token = await SecureStorage().getToken();

    await http.post(
      Uri.parse("${ApiConstants.recurring}/run-now"),
      headers: {"Authorization": "Bearer $token"},
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Đã chạy recurring ngay lập tức!")),
    );
  }

  // =============================
  // ➕ Popup thêm giao dịch
  // =============================
  void openAddDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Tạo giao dịch định kỳ"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              // 🔻 Dropdown DANH MỤC
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(labelText: "Danh mục"),
                value: selectedCategoryId,
                items: categories.map<DropdownMenuItem<int>>((c) {
                  return DropdownMenuItem(
                    value: c["categoryId"],
                    child: Text(c["categoryName"]),
                  );
                }).toList(),
                onChanged: (v) {
                  setState(() => selectedCategoryId = v);
                },
              ),

              TextField(
                controller: amountC,
                decoration: const InputDecoration(labelText: "Số tiền"),
                keyboardType: TextInputType.number,
              ),

              TextField(
                controller: noteC,
                decoration: const InputDecoration(labelText: "Ghi chú"),
              ),

              const SizedBox(height: 10),

              // 🔁 Frequency Dropdown
              DropdownButton(
                value: frequency,
                items: const [
                  DropdownMenuItem(value: "daily", child: Text("Hàng ngày")),
                  DropdownMenuItem(value: "weekly", child: Text("Hàng tuần")),
                  DropdownMenuItem(value: "monthly", child: Text("Hàng tháng")),
                  DropdownMenuItem(value: "yearly", child: Text("Hàng năm")),
                ],
                onChanged: (v) => setState(() => frequency = v!),
              ),

              const SizedBox(height: 10),

              ElevatedButton(
                onPressed: () {
                  if (selectedCategoryId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Vui lòng chọn danh mục")),
                    );
                    return;
                  }
                  createRecurring();
                },
                child: const Text("Tạo"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =============================
  // 🖼 Giao diện
  // =============================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Giao dịch định kỳ"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: runNow,
          )
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: openAddDialog,
        child: const Icon(Icons.add),
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : recurringList.isEmpty
              ? const Center(child: Text("Không có giao dịch định kỳ"))
              : ListView.builder(
                  itemCount: recurringList.length,
                  itemBuilder: (context, i) {
                    final r = recurringList[i];

                    final categoryName =
                        r["category"]?["categoryName"] ?? "(Không rõ danh mục)";

                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: ListTile(
                        title: Text(r["note"] ?? "Không có ghi chú"),

                        subtitle: Text(
                          "Số tiền: ${r["amount"]}\n"
                          "Danh mục: $categoryName\n"
                          "Lặp: ${r["frequency"]}\n"
                          "Ngày kế tiếp: ${r["nextDate"]}",
                        ),

                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => deleteRecurring(r["id"]),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
