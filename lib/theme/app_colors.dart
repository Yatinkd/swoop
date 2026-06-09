import 'package:flutter/material.dart';

/// Swoop — warm beige + navy, Hinge-inspired premium tokens
class AppColors {
  AppColors._();

  // Warm beige — clearly visible sand/tan (not off-white)
  static const Color bg = Color(0xFFDCD0B8);
  static const Color bgSecondary = Color(0xFFD0C4AA);
  static const Color card = Color(0xFFE9E2D4);

  // Navy typography
  static const Color navy = Color(0xFF1E2B4A);
  static const Color navyMid = Color(0xFF3D4F6F);
  static const Color navyLight = Color(0xFF5C6B85);

  // Body text — softer black
  static const Color text = navy;
  static const Color textBody = Color(0xFF3D4451);
  static const Color textSecondary = Color(0xFF6E7583);

  static const Color border = Color(0xFFC4B8A4);
  static const Color accent = navy;
  static const Color success = Color(0xFF2D6A4F);
  static const Color warning = Color(0xFFB8860B);
  static const Color danger = Color(0xFFB83B3B);

  // Legacy aliases
  static const Color primary = navy;
  static const Color secondary = bgSecondary;
  static const Color subtle = textSecondary;
  static const Color divider = border;
  static const Color inputFill = card;
  static const Color chipBg = bgSecondary;
  static const Color pinkSubtle = Color(0xFFE5DDD0);

  static Color vibeBg(String? vibe) => chipBg;
  static Color vibeFg(String? vibe) => navy;

  static const double radiusLg = 20;
  static const double radiusMd = 16;
  static const double radiusSm = 12;

  static List<BoxShadow> softShadow([double opacity = 0.05]) => [
        BoxShadow(
          color: navy.withValues(alpha: opacity),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];
}
