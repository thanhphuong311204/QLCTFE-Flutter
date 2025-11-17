import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../api/wallet_service.dart';
import '../models/wallet_model.dart';
import 'wallet_detail_screen.dart'; // ✅ thêm dòng này để import màn chi tiết ví

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final WalletService _walletService = WalletService();
  List<Wallet> _wallets = [];

  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();
  String _selectedType = "Tiền mặt";

  final List<String> _walletTypes = [
    "Tiền mặt",
    "Ngân hàng",
    "Tiết kiệm",
    "Đầu tư",
    "E-Wallet"
  ];

  @override
  void initState() {
    super.initState();
    _loadWallets();
  }

  Future<void> _loadWallets() async {
    try {
      final wallets = await _walletService.getWallets();
      setState(() => _wallets = wallets);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("❌ Lỗi khi tải ví: $e")));
    }
  }

  // 🪙 Thêm ví mới
  Future<void> _addWallet() async {
    _nameController.clear();
    _balanceController.clear();
    _selectedType = "Tiền mặt";
    _showWalletDialog(isEdit: false);
  }

  // ✏️ Sửa ví
  Future<void> _editWallet(Wallet wallet) async {
    _nameController.text = wallet.walletName;
    _balanceController.text = wallet.balance.toString();
    _selectedType = wallet.type;
    _showWalletDialog(isEdit: true, walletId: wallet.id!);
  }

  // 📋 Hộp thoại thêm / sửa ví
  void _showWalletDialog({required bool isEdit, int? walletId}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isEdit ? "✏️ Sửa ví" : "🪙 Thêm ví mới"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Tên ví"),
            ),
            TextField(
              controller: _balanceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Số dư"),
            ),
            DropdownButtonFormField<String>(
              value: _selectedType,
              items: _walletTypes
                  .map((type) =>
                      DropdownMenuItem(value: type, child: Text(type)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedType = v!),
              decoration: const InputDecoration(labelText: "Loại ví"),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Hủy")),
          ElevatedButton(
            onPressed: () async {
              final name = _nameController.text.trim();
              final balance = double.tryParse(_balanceController.text) ?? 0;

              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("⚠️ Nhập tên ví")),
                );
                return;
              }

              if (isEdit) {
                await _walletService.updateWallet(walletId!, {
                  "walletName": name,
                  "balance": balance,
                  "type": _selectedType,
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("✅ Cập nhật ví thành công!")),
                );
              } else {
                await _walletService.addWallet(
                  walletName: name,
                  balance: balance,
                  type: _selectedType,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("✅ Thêm ví thành công!")),
                );
              }

              if (!mounted) return;
              Navigator.pop(context);
              await _loadWallets();
            },
            child: Text(isEdit ? "Lưu" : "Thêm"),
          ),
        ],
      ),
    );
  }

  // 🗑️ Xóa ví (có xác nhận)
  Future<void> _deleteWallet(int walletId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("⚠️ Xóa ví"),
        content: const Text("Bạn có chắc chắn muốn xóa ví này không?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Xóa"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _walletService.deleteWallet(walletId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("🗑️ Đã xóa ví thành công")),
      );
      await _loadWallets();
    }
  }

  // 🎨 Màu & icon loại ví
  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case "ngân hàng":
        return Colors.blueAccent;
      case "đầu tư":
        return Colors.green;
      case "e-wallet":
        return Colors.purple;
      case "tiết kiệm":
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case "ngân hàng":
        return Icons.account_balance;
      case "đầu tư":
        return Icons.trending_up;
      case "e-wallet":
        return Icons.phone_iphone;
      case "tiết kiệm":
        return Icons.savings;
      default:
        return Icons.wallet;
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatCurrency =
        NumberFormat.currency(locale: "vi_VN", symbol: "đ", decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(title: const Text("Danh sách ví")),
      body: RefreshIndicator(
        onRefresh: _loadWallets,
        child: _wallets.isEmpty
            ? const Center(child: Text("Chưa có ví nào."))
            : ListView.builder(
                itemCount: _wallets.length,
                itemBuilder: (_, i) {
                  final w = _wallets[i];
                  return Card(
                    margin: const EdgeInsets.all(8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            _getTypeColor(w.type).withOpacity(0.2),
                        child: Icon(
                          _getTypeIcon(w.type),
                          color: _getTypeColor(w.type),
                        ),
                      ),
                      title: Text(
                        w.walletName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text("Loại: ${w.type}"),

                      // ✅ Khi bấm vào ví → mở chi tiết ví
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => WalletDetailScreen(wallet: w),
                          ),
                        );
                      },

                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'edit') _editWallet(w);
                          if (value == 'delete') _deleteWallet(w.id!);
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Text("✏️ Sửa"),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text("🗑️ Xóa"),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addWallet,
        child: const Icon(Icons.add),
      ),
    );
  }
}
