// import 'package:buzzmap/pages/interests_screen.dart';
import 'package:buzzmap/main.dart';
import 'package:buzzmap/pages/interests_screen.dart';
import 'package:flutter/material.dart';

class Interests extends StatelessWidget {
  final IconData? icon;
  final String? graphic;
  final String label;
  final Color color;

  const Interests({
    super.key,
    this.icon,
    this.graphic,
    this.color = primaryColor,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const InterestsScreen(),
              ));
        },
        child: Column(
          children: [
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
              ),
              child: Center(
                child: graphic != null
                    ? Image.asset(graphic!, width: 35, height: 35)
                    : Icon(icon, size: 30, color: Colors.white),
              ),
            ),
            const SizedBox(height: 8),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF245261))),
          ],
        ));
  }
}
