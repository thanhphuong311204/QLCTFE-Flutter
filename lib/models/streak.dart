class Streak {
  final int currentStreak;
  final int maxStreak;

  Streak({required this.currentStreak, required this.maxStreak});

  factory Streak.fromJson(Map<String, dynamic> json) {
    return Streak(
      currentStreak: json['currentStreak'],
      maxStreak: json['maxStreak'],
    );
  }
}
