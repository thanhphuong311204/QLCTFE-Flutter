import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../api/transaction_service.dart';
import '../api/wallet_service.dart';
import '../models/wallet_model.dart';
import '../models/transaction_model.dart';

class TransactionFormScreen extends StatefulWidget {
  final bool isExpense;
  final int? categoryId;
  final String? categoryName;
  final TransactionModel? transaction;

  const TransactionFormScreen({
    super.key,
    required this.isExpense,
    this.categoryId,
    this.categoryName,
    this.transaction,
  });

  @override
  State<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends State<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  final TransactionService _transactionService = TransactionService();
  final WalletService _walletService = WalletService();

  List<Wallet> _wallets = [];
  Wallet? _selectedWallet;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadWallets();

    // Nếu có transaction => fill dữ liệu vào form
    if (widget.transaction != null) {
      final tx = widget.transaction!;
      _amountController.text = tx.amount.toString();
      _noteController.text = tx.note ?? '';
      _selectedDate = DateTime.parse(tx.createdAt);
    }
  }

  Future<void> _loadWallets() async {
    try {
      final wallets = await _walletService.getWallets();
      setState(() {
        _wallets = wallets;
        if (wallets.isNotEmpty) {
          _selectedWallet = wallets.first;
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Không thể tải danh sách ví: $e")),
      );
    }
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      locale: const Locale('vi', 'VN'),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _submitTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedWallet == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Vui lòng chọn ví")),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Số tiền phải lớn hơn 0")),
      );
      return;
    }

    final note = _noteController.text.trim();
    final data = {
      "amount": amount,
      "note": note,
      "categoryId": widget.categoryId ?? widget.transaction?.categoryId,
      "walletId": _selectedWallet!.id,
      "createdAt": DateFormat('yyyy-MM-dd').format(_selectedDate),
    };

    try {
      if (widget.transaction == null) {
        if (widget.isExpense) {
          await _transactionService.addExpense(data);
        } else {
          await _transactionService.addIncome(data);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Thêm giao dịch thành công!")),
        );
      } else {
        await _transactionService.updateTransaction(
          widget.transaction!.id,
          data,
          widget.transaction!.type == "expense",
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Đã cập nhật giao dịch!")),
        );
      }
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("❌ Lỗi: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.transaction == null
            ? "Thêm giao dịch - ${widget.categoryName ?? (widget.isExpense ? 'Chi tiêu' : 'Thu nhập')}"
            : "Sửa giao dịch"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Số tiền"),
                validator: (value) =>
                    value!.isEmpty ? "Vui lòng nhập số tiền" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(labelText: "Ghi chú"),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Ngày: ${DateFormat('dd/MM/yyyy').format(_selectedDate)}"),
                  TextButton(
                    onPressed: () => _pickDate(context),
                    child: const Text("Chọn ngày"),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<Wallet>(
                value: _selectedWallet,
                decoration: const InputDecoration(labelText: "Chọn ví"),
                items: _wallets.map((wallet) {
                  final formattedBalance =
                      NumberFormat("#,##0", "vi_VN").format(wallet.balance);
                  return DropdownMenuItem<Wallet>(
                    value: wallet,
                    child: Text("${wallet.walletName} (${formattedBalance} đ)"),
                  );
                }).toList(),
                validator: (value) =>
                    value == null ? "Vui lòng chọn ví" : null,
                onChanged: (wallet) =>
                    setState(() => _selectedWallet = wallet),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitTransaction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.isExpense
                      ? Colors.redAccent
                      : Colors.green,
                  padding: const EdgeInsets.all(16),
                ),
                child: Text(
                  widget.transaction == null
                      ? (widget.isExpense ? "Thêm khoản chi" : "Thêm khoản thu")
                      : "Cập nhật giao dịch",
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
