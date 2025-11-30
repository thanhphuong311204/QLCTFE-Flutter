import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../api/transaction_service.dart';
import '../api/wallet_service.dart';
import '../api/ai_service.dart';
import '../api/category_service.dart';
import '../models/wallet_model.dart';
import '../models/transaction_model.dart';
import '../models/category_model.dart';

class TransactionFormScreen extends StatefulWidget {
  final bool isExpense;
  int? categoryId;
  String? categoryName;
  final TransactionModel? transaction;

  TransactionFormScreen({
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
  final AIService _aiService = AIService();
  final CategoryService _categoryService = CategoryService();

  List<Wallet> _wallets = [];
  Wallet? _selectedWallet;
  List<CategoryModel> _categories = [];

  DateTime _selectedDate = DateTime.now();

  /// 🔥 DANH SÁCH GỢI Ý TỪ AI
  List<String> _aiSuggestions = [];
  bool _loadingAI = false;

  @override
  void initState() {
    super.initState();
    _loadWallets();
    _loadCategories();

    if (widget.transaction != null) {
      final tx = widget.transaction!;
      _amountController.text = tx.amount.toString();
      _noteController.text = tx.note ?? '';
      _selectedDate = DateTime.parse(tx.createdAt);
      widget.categoryId = tx.categoryId;
      widget.categoryName = tx.categoryName;
    }
  }

  // ---------------------- LOAD CATEGORY -----------------------
  Future<void> _loadCategories() async {
    try {
      final cats = await _categoryService.getCategories();
      setState(() => _categories = cats);
    } catch (_) {}
  }

  // ---------------------- LOAD WALLETS ------------------------
  Future<void> _loadWallets() async {
    try {
      final wallets = await _walletService.getWallets();
      setState(() {
        _wallets = wallets;
        _selectedWallet = wallets.isNotEmpty ? wallets.first : null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Không thể tải ví: $e")),
      );
    }
  }

  // ---------------------- MATCH CATEGORY -----------------------
  CategoryModel _smartMatchCategory(String name) {
    final lower = name.toLowerCase();

    return _categories.firstWhere(
      (c) => c.categoryName.toLowerCase() == lower,
      orElse: () => _categories.firstWhere((c) => c.categoryName == "Khác"),
    );
  }

  // ---------------------- CALL AI => MULTI SUGGESTIONS ---------
  Future<void> _runAISuggestion(String text) async {
    if (text.trim().length < 2) return;

    setState(() => _loadingAI = true);

    try {
      final res = await _aiService.suggestCategory(text.trim());

    setState(() {
  _aiSuggestions = [ res["category"] ?? "Khác" ];
});
    } catch (e) {
      _aiSuggestions = [];
    }

    setState(() => _loadingAI = false);
  }

  // ---------------------- SUBMIT -------------------------------
  Future<void> _submitTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedWallet == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("❌ Vui lòng chọn ví")));
      return;
    }

    if (widget.categoryId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("❌ Chưa chọn danh mục")));
      return;
    }

    final data = {
      "amount": double.parse(_amountController.text),
      "note": _noteController.text.trim(),
      "categoryId": widget.categoryId,
      "walletId": _selectedWallet!.id,
      "createdAt": DateFormat("yyyy-MM-dd").format(_selectedDate),
    };

    try {
      if (widget.transaction == null) {
        if (widget.isExpense) {
          await _transactionService.addExpense(data);
        } else {
          await _transactionService.addIncome(data);
        }
      } else {
        await _transactionService.updateTransaction(
          widget.transaction!.id,
          data,
          widget.transaction!.type == "expense",
        );
      }

      Navigator.pop(context, true);

    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("❌ Lỗi: $e")));
    }
  }

  // ---------------------- UI -----------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text(widget.transaction == null ? "Thêm giao dịch" : "Sửa giao dịch"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Số tiền
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: "Số tiền"),
                validator: (v) => v!.isEmpty ? "Không được để trống" : null,
              ),

              SizedBox(height: 16),

              // Ghi chú
              TextFormField(
                controller: _noteController,
                decoration: InputDecoration(labelText: "Ghi chú"),
                onChanged: _runAISuggestion,
              ),

              SizedBox(height: 12),

              // -------------------- MULTI SUGGESTION UI -------------------
              if (_loadingAI)
                Text("⏳ AI đang phân tích...", style: TextStyle(color: Colors.grey))
              else if (_aiSuggestions.isNotEmpty)
                Wrap(
                  spacing: 8,
                  children: _aiSuggestions.map((s) {
                    return ChoiceChip(
                      label: Text(s),
                      selected: false,
                      onSelected: (_) {
                        final matched = _smartMatchCategory(s);

                        setState(() {
                          widget.categoryId = matched.categoryId;
                          widget.categoryName = matched.categoryName;
                        });

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("✔ Đã chọn: ${matched.categoryName}")),
                        );
                      },
                    );
                  }).toList(),
                ),

              SizedBox(height: 16),

              // Ngày
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Ngày: ${DateFormat('dd/MM/yyyy').format(_selectedDate)}"),
                  TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2035),
                      );
                      if (picked != null) {
                        setState(() => _selectedDate = picked);
                      }
                    },
                    child: Text("Chọn ngày"),
                  ),
                ],
              ),

              SizedBox(height: 16),

              // Ví
              DropdownButtonFormField<Wallet>(
                value: _selectedWallet,
                decoration: InputDecoration(labelText: "Chọn ví"),
                items: _wallets.map((w) {
                  return DropdownMenuItem(
                    value: w,
                    child: Text("${w.walletName} (${w.balance} đ)"),
                  );
                }).toList(),
                onChanged: (w) => setState(() => _selectedWallet = w),
              ),

              SizedBox(height: 24),

              // Submit button
              ElevatedButton(
                onPressed: _submitTransaction,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      widget.isExpense ? Colors.redAccent : Colors.green,
                  padding: EdgeInsets.all(16),
                ),
                child: Text(
                  widget.transaction == null
                      ? (widget.isExpense ? "Thêm khoản chi" : "Thêm khoản thu")
                      : "Cập nhật giao dịch",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
