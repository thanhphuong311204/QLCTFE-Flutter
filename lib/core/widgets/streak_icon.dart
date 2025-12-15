import 'package:flutter/material.dart';

class StreakIcon extends StatelessWidget {
  final int streak;

  const StreakIcon({super.key, required this.streak});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.local_fire_department, 
            color: Colors.orange, size: 32),
        SizedBox(width: 6),
        Text(
          "$streak",
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.orange[700],
          ),
        ),
      ],
    );
  }
}
