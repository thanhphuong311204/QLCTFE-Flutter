import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/wallet_model.dart';
import '../models/transaction_model.dart';
import '../api/transaction_service.dart';

class WalletDetailScreen extends StatefulWidget {
  final Wallet wallet;

  const WalletDetailScreen({Key? key, required this.wallet}) : super(key: key);

  @override
  State<WalletDetailScreen> createState() => _WalletDetailScreenState();
}

class _WalletDetailScreenState extends State<WalletDetailScreen> {
  final TransactionService _transactionService = TransactionService();
  bool _isLoading = true;
  List<TransactionModel> _transactions = [];

  @override
  void initState() {
    super.initState();
    _loadWalletTransactions();
  }

  Future<void> _loadWalletTransactions() async {
    setState(() => _isLoading = true);
    try {
      final incomes = await _transactionService.getIncomes();
      final expenses = await _transactionService.getExpenses();

      final all = [...incomes, ...expenses]
          .where((t) => t.walletId == widget.wallet.id)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      setState(() => _transactions = all);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Lỗi khi tải giao dịch: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final format = NumberFormat("#,##0", "vi_VN");

    // 🧮 Tính tổng thu, tổng chi và số dư hiện tại
    final totalIncome = _transactions
        .where((t) => t.type == "income")
        .fold<double>(0, (sum, t) => sum + t.amount);

    final totalExpense = _transactions
        .where((t) => t.type == "expense")
        .fold<double>(0, (sum, t) => sum + t.amount);

    final balance =
        widget.wallet.balance + totalIncome - totalExpense; // ✅ FIX LOGIC
    final difference = (totalIncome - totalExpense);

    return Scaffold(
      backgroundColor: const Color(0xFFFCF8F3),
      appBar: AppBar(
        title: Text(widget.wallet.walletName),
        backgroundColor: Colors.orange.shade100,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadWalletTransactions,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildWalletInfoCard(widget.wallet, balance, difference, format),
                  const SizedBox(height: 16),
                  _buildSummaryCard("Tổng thu", totalIncome, Colors.green),
                  const SizedBox(height: 8),
                  _buildSummaryCard("Tổng chi", totalExpense, Colors.redAccent),
                  const SizedBox(height: 16),
                  const Text(
                    "Lịch sử giao dịch",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  ..._transactions.map((tx) => _buildTransactionTile(tx, format)),
                ],
              ),
            ),
    );
  }

  // 🧾 Thông tin ví + biến động
  Widget _buildWalletInfoCard(
      Wallet wallet, double balance, double difference, NumberFormat format) {
    final diffColor = difference >= 0 ? Colors.green : Colors.redAccent;
    final diffSign = difference >= 0 ? "+" : "-";

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(wallet.walletName,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("Loại ví: ${wallet.type}",
                style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            Text(
              "Số dư ban đầu: ${format.format(wallet.balance)} đ",
              style: const TextStyle(color: Colors.black87, fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text(
              "Biến động: $diffSign${format.format(difference.abs())} đ",
              style: TextStyle(
                color: diffColor,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Số dư hiện tại: ${format.format(balance)} đ",
              style: const TextStyle(
                color: Colors.blueAccent,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 💰 Tổng thu & chi
  Widget _buildSummaryCard(String title, double amount, Color color) {
    final format = NumberFormat("#,##0", "vi_VN");
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title,
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            Text("${format.format(amount)} đ",
                style: TextStyle(
                    color: color, fontWeight: FontWeight.bold, fontSize: 15)),
          ],
        ),
      ),
    );
  }

  // 📜 Hiển thị từng giao dịch trong ví
  Widget _buildTransactionTile(TransactionModel tx, NumberFormat format) {
    final color = tx.type == "expense" ? Colors.redAccent : Colors.green;
    final icon =
        tx.type == "expense" ? Icons.arrow_downward : Icons.arrow_upward;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          child: Icon(icon, color: color),
        ),
        title: Text(
          tx.note.isNotEmpty ? tx.note : tx.categoryName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          DateFormat('dd/MM/yyyy HH:mm')
              .format(DateTime.tryParse(tx.createdAt) ?? DateTime.now()),
        ),
        trailing: Text(
          "${tx.type == "expense" ? "-" : "+"}${format.format(tx.amount)} đ",
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
