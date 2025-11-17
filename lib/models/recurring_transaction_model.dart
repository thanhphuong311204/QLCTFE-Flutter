class RecurringTransactionModel {
  final int id;
  final double amount;
  final String note;
  final String frequency;
  final DateTime nextDate;
  final DateTime createdAt;
  final int categoryId;
  final String categoryName;
  final int walletId;
  final String walletName;

  RecurringTransactionModel({
    required this.id,
    required this.amount,
    required this.note,
    required this.frequency,
    required this.nextDate,
    required this.createdAt,
    required this.categoryId,
    required this.categoryName,
    required this.walletId,
    required this.walletName,
  });

  factory RecurringTransactionModel.fromJson(Map<String, dynamic> json) {
    return RecurringTransactionModel(
      id: json["id"],
      amount: (json["amount"] as num).toDouble(),
      note: json["note"] ?? "",
      frequency: json["frequency"],
      nextDate: DateTime.parse(json["nextDate"]),
      createdAt: DateTime.parse(json["createdAt"]),
      categoryId: json["category"]["categoryId"],
      categoryName: json["category"]["categoryName"],
      walletId: json["wallet"]["id"],
      walletName: json["wallet"]["walletName"],
    );
  }
}
