class TransactionModel {
  final int id;
  final double amount;
  final String note;
  final String createdAt;
  final String type;
  final String categoryName;
  final int categoryId;
  final String? iconUrl;
  final int walletId;
  final String walletName;

  TransactionModel({
    required this.id,
    required this.amount,
    required this.note,
    required this.createdAt,
    required this.type,
    required this.categoryName,
    this.iconUrl,
    required this.walletId,
    required this.walletName,
    required this.categoryId,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    final category = json['category'] ?? {};
    final wallet = json['wallet'] ?? {};

    // 🧩 Xử lý ngày tháng an toàn
    String rawDate = json['createdAt'] ?? json['createAt'] ?? '';
    String formattedDate = rawDate;

    try {
      if (rawDate.isNotEmpty) {
        // Nếu backend trả "2025-11-09 00:00:00" → đổi thành "2025-11-09T00:00:00"
        formattedDate = rawDate.replaceAll(' ', 'T');

        // Nếu parse được thì giữ lại dạng ISO
        DateTime parsed = DateTime.parse(formattedDate);
        formattedDate = parsed.toIso8601String();
      } else {
        // Nếu null → gán hiện tại
        formattedDate = DateTime.now().toIso8601String();
      }
    } catch (e) {
      // Nếu lỗi format → fallback sang hiện tại
      formattedDate = DateTime.now().toIso8601String();
    }

    return TransactionModel(
      id: json['id'] ?? json['expenseId'] ?? json['incomeId'] ?? 0,
      amount: (json['amount'] ?? 0).toDouble(),
      note: json['note'] ?? '',
      createdAt: formattedDate, // ✅ đã format đúng chuẩn ISO
      type: category['type'] ?? 'expense',
      categoryName: category['categoryName'] ?? 'Không rõ',
      iconUrl: category['iconUrl'],
      walletId: wallet['id'] ?? wallet['walletId'] ?? 0,
      walletName: wallet['walletName'] ?? '',
      categoryId: json['categoryId'] ?? category['categoryId'] ?? 0,
    );
  }
}
