import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../api/transaction_service.dart';
import '../models/transaction_model.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({Key? key}) : super(key: key);

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  final TransactionService _service = TransactionService();
  late Future<List<TransactionModel>> _transactions;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  /// 🔄 Tải lại toàn bộ giao dịch
  void _loadTransactions() {
    setState(() {
      _transactions = _fetchAllTransactions();
    });
  }

  /// 🧾 Gộp thu nhập + chi tiêu
  Future<List<TransactionModel>> _fetchAllTransactions() async {
    final expenses = await _service.getExpenses();
    final incomes = await _service.getIncomes();

    final all = [...expenses, ...incomes];
    all.sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Mới nhất lên đầu
    return all;
  }

  /// 🗑️ Xoá giao dịch
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Lỗi khi xoá: $e")),
        );
      }
    }
  }

  String _formatCurrency(double amount) {
    final format = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    return format.format(amount);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCF8F3),
      appBar: AppBar(
        title: const Text("Lịch sử giao dịch"),
        backgroundColor: Colors.orange.shade100,
        centerTitle: true,
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
            return const Center(
              child: Text("Không có giao dịch nào."),
            );
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
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
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
                            mainAxisAlignment: MainAxisAlignment.center,
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
                                DateFormat('dd/MM/yyyy HH:mm')
                                    .format(DateTime.parse(tx.createdAt)),
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
                          mainAxisAlignment: MainAxisAlignment.center,
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
                              icon: const Icon(Icons.delete_outline, color: Colors.grey),
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
