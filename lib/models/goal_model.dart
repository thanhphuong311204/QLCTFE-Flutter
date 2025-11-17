class GoalModel {
  final int goalId;
  final String goalName;
  final double targetAmount;
  final double currentAmount;
  final DateTime? deadline;

  GoalModel({
    required this.goalId,
    required this.goalName,
    required this.targetAmount,
    required this.currentAmount,
    this.deadline,
  });

  factory GoalModel.fromJson(Map<String, dynamic> json) => GoalModel(
        goalId: json['goalId'],
        goalName: json['goalName'],
        targetAmount: (json['targetAmount'] ?? 0).toDouble(),
        currentAmount: (json['currentAmount'] ?? 0).toDouble(),
        deadline:
            json['deadline'] != null ? DateTime.parse(json['deadline']) : null,
      );
}
