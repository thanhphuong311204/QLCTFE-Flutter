class ReportModel {
  final int? id;
  final String reportType;
  final DateTime startDate;
  final DateTime endDate;
  final double totalIncome;
  final double totalExpense;

  ReportModel({
    this.id,
    required this.reportType,
    required this.startDate,
    required this.endDate,
    required this.totalIncome,
    required this.totalExpense,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      id: json['id'] ?? json['report_id'],
      reportType: json['reportType'] ?? json['report_type'] ?? '',
      startDate: DateTime.tryParse(json['startDate'] ?? json['start_date'] ?? '') ?? DateTime.now(),
      endDate: DateTime.tryParse(json['endDate'] ?? json['end_date'] ?? '') ?? DateTime.now(),
      totalIncome: (json['totalIncome'] ?? json['total_income'] ?? 0).toDouble(),
      totalExpense: (json['totalExpense'] ?? json['total_expense'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "reportType": reportType,
      "startDate": startDate.toIso8601String(),
      "endDate": endDate.toIso8601String(),
      "totalIncome": totalIncome,
      "totalExpense": totalExpense,
    };
  }
}
