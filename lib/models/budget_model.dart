class Budget {
  final int id;
  final String? categoryName;
  final String? walletName;
  final double amountLimit;
  final double spentAmount;
  final DateTime? startDate;
  final DateTime? endDate;

  Budget({
    required this.id,
    this.categoryName,
    this.walletName,
    required this.amountLimit,
    required this.spentAmount,
    this.startDate,
    this.endDate,
  });

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      id: json['id'] ?? json['budget_id'] ?? 0,
      categoryName: json['category']?['categoryName'] ?? json['categoryName'],
      walletName: json['wallet']?['walletName'] ?? json['walletName'],
      amountLimit: (json['amountLimit'] ?? 0).toDouble(),
      spentAmount: (json['spentAmount'] ?? 0).toDouble(),
      startDate: json['startDate'] != null ? DateTime.parse(json['startDate']) : null,
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
    );
  }
}
