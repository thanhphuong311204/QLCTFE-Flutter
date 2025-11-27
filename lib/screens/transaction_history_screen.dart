import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../api/transaction_service.dart';
import '../models/transaction_model.dart';

// 🧩 Thư viện xuất Excel & lưu file
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:universal_html/html.dart' as html;

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({Key? key}) : super(key: key);

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  final TransactionService _service = TransactionService();
  late Future<List<TransactionModel>> _transactions;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  void _loadTransactions() {
    setState(() {
      _transactions = _fetchAllTransactions();
    });
  }

  Future<Directory?> getDownloadDirectory() async {
    if (Platform.isAndroid) {
      final dir = Directory('/storage/emulated/0/Download');
      if (await dir.exists()) return dir;
    }
    return await getApplicationDocumentsDirectory();
  }

  Future<List<TransactionModel>> _fetchAllTransactions() async {
    final expenses = await _service.getExpenses();
    final incomes = await _service.getIncomes();
    final all = [...expenses, ...incomes];
    all.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return all;
  }

  Future<void> _deleteTransaction(TransactionModel tx) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Xác nhận xoá"),
        content: Text("Bạn có chắc muốn xoá giao dịch '${tx.note}' không?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Huỷ"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text("Xoá"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _service.deleteTransaction(tx.id, tx.type == "expense");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("🗑️ Đã xoá giao dịch thành công.")),
        );
        _loadTransactions();
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("❌ Lỗi khi xoá: $e")));
      }
    }
  }

  String _formatCurrency(double amount) {
    final format = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    return format.format(amount);
  }

  /// 💾 Xuất file Excel
  Future<void> _exportToExcel(List<TransactionModel> transactions) async {
    try {
      if (transactions.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Không có dữ liệu để xuất.")),
        );
        return;
      }

      // 🟡 Tạo Excel
      final excel = Excel.createExcel();
      final sheet = excel['GiaoDich'];
      sheet.appendRow([
        TextCellValue("ID"),
        TextCellValue("Loại"),
        TextCellValue("Danh mục"),
        TextCellValue("Ghi chú"),
        TextCellValue("Số tiền"),
        TextCellValue("Ví"),
        TextCellValue("Ngày tạo"),
      ]);

      // 🟢 Ghi dữ liệu thực
      for (var tx in transactions) {
        sheet.appendRow([
          TextCellValue(tx.id.toString()),
          TextCellValue(tx.type == "expense" ? "Chi" : "Thu"),
          TextCellValue(tx.categoryName),
          TextCellValue(tx.note),
          TextCellValue(_formatCurrency(tx.amount)),
          TextCellValue(tx.walletName),
          TextCellValue(
            DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(tx.createdAt)),
          ),
        ]);
      }

      final bytes = excel.encode();
      if (bytes == null) throw Exception("Không thể tạo file Excel.");

      // 🧩 Nếu đang chạy Web
      if (kIsWeb) {
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute(
            "download",
            "transactions_${DateTime.now().millisecondsSinceEpoch}.xlsx",
          )
          ..click();
        html.Url.revokeObjectUrl(url);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ File Excel đã được tải xuống.")),
        );
        return;
      }

      final dir = await getDownloadDirectory();
      final filePath =
          '${dir?.path}/transactions_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      final file = File(filePath!)
        ..createSync(recursive: true)
        ..writeAsBytesSync(bytes, flush: true);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ File Excel đã được lưu tại: $filePath")),
      );
      await OpenFilex.open(filePath);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("❌ Lỗi khi xuất Excel: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCF8F3),
      appBar: AppBar(
        title: const Text("Lịch sử giao dịch"),
        backgroundColor: Colors.orange.shade100,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: "Xuất Excel",
            onPressed: () async {
              final data = await _transactions;
              _exportToExcel(data);
            },
          ),
        ],
      ),
      body: FutureBuilder<List<TransactionModel>>(
        future: _transactions,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.orangeAccent),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text("❌ Lỗi khi tải dữ liệu: ${snapshot.error}"),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Không có giao dịch nào."));
          }

          final transactions = snapshot.data!;

          return RefreshIndicator(
            onRefresh: () async => _loadTransactions(),
            child: ListView.builder(
              itemCount: transactions.length,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemBuilder: (context, index) {
                final tx = transactions[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 12,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: tx.type == "expense"
                              ? Colors.redAccent.withOpacity(0.1)
                              : Colors.green.withOpacity(0.1),
                          child: Icon(
                            tx.type == "expense"
                                ? Icons.arrow_downward
                                : Icons.arrow_upward,
                            color: tx.type == "expense"
                                ? Colors.redAccent
                                : Colors.green,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tx.note.isNotEmpty ? tx.note : tx.categoryName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                DateFormat(
                                  'dd/MM/yyyy HH:mm',
                                ).format(DateTime.parse(tx.createdAt)),
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                "Ví: ${tx.walletName}",
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          children: [
                            Text(
                              _formatCurrency(tx.amount),
                              style: TextStyle(
                                color: tx.type == "expense"
                                    ? Colors.redAccent
                                    : Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.grey,
                              ),
                              onPressed: () => _deleteTransaction(tx),
                              tooltip: "Xoá giao dịch",
                              constraints: const BoxConstraints(),
                              padding: EdgeInsets.zero,
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
    );
  }
}
