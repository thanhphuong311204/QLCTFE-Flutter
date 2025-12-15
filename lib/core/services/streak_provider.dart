import 'package:flutter/material.dart';
import 'package:qlctfe/models/streak.dart';
import 'streak_service.dart';

class StreakProvider with ChangeNotifier {
  final StreakService _service = StreakService();

  int currentStreak = 0;
  int maxStreak = 0;

  Future<void> loadStreak(String token) async {
    Streak streak = await _service.getStreak(token);
    currentStreak = streak.currentStreak;
    maxStreak = streak.maxStreak;
    notifyListeners();
  }
}
