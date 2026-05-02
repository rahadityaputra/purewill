import 'package:flutter/material.dart';

class BestStreakWidget extends StatelessWidget {
  final int streak;

  const BestStreakWidget({super.key, required this.streak});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        // Menggunakan gradasi linear untuk efek logam emas
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFD700), // Gold
            Color(0xFFFDB931), // Golden Yellow
            Color(0xFFB8860B), // Dark Goldenrod (untuk dimensi)
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFB8860B).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: const Color(0xFFFFE082),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Gunakan Icon Trophy atau mahkota jika GIF tidak mendukung warna emas
              const Icon(
                Icons.emoji_events_rounded, // Icon Trophy
                color: Color(0xFF5D4037),   // Cokelat tua agar kontras dengan emas
                size: 36,
              ),
              const SizedBox(width: 12),
              Text(
                streak.toString(),
                style: const TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF5D4037),
                  letterSpacing: -1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            "ALL-TIME BEST STREAK",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Color(0xFF795548), // Warna cokelat elegan
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}