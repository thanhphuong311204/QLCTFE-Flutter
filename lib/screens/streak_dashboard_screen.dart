import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/services/streak_provider.dart';

class StreakDashboardScreen extends StatefulWidget {
  const StreakDashboardScreen({super.key});

  @override
  State<StreakDashboardScreen> createState() => _StreakDashboardScreenState();
}

class _StreakDashboardScreenState extends State<StreakDashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _glow;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _scale = Tween<double>(begin: 0.8, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _glow = Tween<double>(begin: 0.1, end: 0.6).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => _controller.forward());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final streakProvider = Provider.of<StreakProvider>(context);
    final streak = streakProvider.currentStreak;
    final maxStreak = streakProvider.maxStreak;

    String nextBadgeName;
    int nextTarget;

    if (streak < 7) {
      nextBadgeName = "Bronze Badge";
      nextTarget = 7;
    } else if (streak < 30) {
      nextBadgeName = "Silver Badge";
      nextTarget = 30;
    } else {
      nextBadgeName = "Gold Badge";
      nextTarget = 100;
    }

    double progress = streak / nextTarget;

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.orange.shade400,
              Colors.orange.shade100,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ---- HEADER ----
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Text(
                        "🔥 Streak Dashboard",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // ---- FIRE ICON + ANIMATION ----
              AnimatedBuilder(
                animation: _controller,
                builder: (_, child) {
                  return Transform.scale(
                    scale: _scale.value,
                    child: Container(
                      padding: const EdgeInsets.all(30),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withOpacity(_glow.value),
                            blurRadius: 40,
                            spreadRadius: 10,
                          )
                        ],
                      ),
                      child: Icon(
                        Icons.local_fire_department,
                        size: 120,
                        color: Colors.red.shade600,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 12),

              Text(
                "$streak Days 🔥",
                style: const TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  shadows: [
                    Shadow(offset: Offset(0, 3), blurRadius: 6, color: Colors.black26)
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // ---- NEXT BADGE CARD ----
              Container(
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Next: $nextBadgeName",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "$streak / $nextTarget",
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 12,
                        backgroundColor: Colors.orange.shade100,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 35),

              // ---- BADGES ----
              Text(
                "Badges",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade900,
                ),
              ),

              const SizedBox(height: 15),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  buildBadge("7 Days", "🥉", streak >= 7),
                  buildBadge("30 Days", "🥈", streak >= 30),
                  buildBadge("100 Days", "🥇", streak >= 100),
                ],
              ),

              const Spacer(),

              // ---- LONGEST STREAK ----
              Padding(
                padding: const EdgeInsets.only(bottom: 30),
                child: Text(
                  "🔥 Longest streak: $maxStreak days",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // BADGE WIDGET
  Widget buildBadge(String label, String emoji, bool unlocked) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 400),
      opacity: unlocked ? 1 : 0.3,
      child: Column(
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 48),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: unlocked ? Colors.black87 : Colors.grey,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
