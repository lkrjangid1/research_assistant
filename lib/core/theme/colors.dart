import 'package:flutter/material.dart';

class AppColors {
  // Backgrounds
  static const background = Color(0xFFFFFFFF);
  static const backgroundSecondary = Color(0xFFFAFBFC);

  // Gradient Accent Colors (Google AI palette)
  static const gradientBlue = Color(0xFF4285F4);
  static const gradientSlateBlue = Color(0xFF7B68EE);
  static const gradientPurple = Color(0xFF9C6ADE);
  static const gradientFuchsia = Color(0xFFE879F9);
  static const gradientRose = Color(0xFFFB7185);
  static const gradientPink = Color(0xFFF472B6);

  // Animated border colors (full loop)
  static const List<Color> gradientBorderColors = [
    Color(0xFF4285F4),
    Color(0xFF7B68EE),
    Color(0xFF9C6ADE),
    Color(0xFFE879F9),
    Color(0xFFFB7185),
    Color(0xFFF472B6),
    Color(0xFF4285F4),
  ];

  // Text
  static const textPrimary = Color(0xFF1F2937);
  static const textSecondary = Color(0xFF6B7280);
  static const textTertiary = Color(0xFF9CA3AF);
  static const textAccent = Color(0xFF4285F4);

  // Surface / Borders
  static const surface = Color(0xFFFFFFFF);
  static const surfaceBorder = Color(0x0F000000); // rgba(0,0,0,0.06)
  static const cardShadow = Color(0x0A000000); // rgba(0,0,0,0.04)

  // Semantic
  static const error = Color(0xFFEF4444);
  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFFF59E0B);

  // Citation
  static const citationHighlight = Color(0xFFEFF6FF);
  static const citationBorder = Color(0xFFBFDBFE);

  // Legacy aliases kept for backward compat
  static const primary = gradientBlue;
  static const onPrimary = Color(0xFFFFFFFF);
  static const primaryContainer = Color(0xFFDBEAFE);
  static const onPrimaryContainer = Color(0xFF1E3A5F);
  static const secondary = gradientPurple;
  static const onSecondary = Color(0xFFFFFFFF);
  static const secondaryContainer = Color(0xFFEDE9FE);
  static const surfaceVariant = Color(0xFFF3F4F6);
  static const onSurface = textPrimary;
  static const onSurfaceVariant = textSecondary;
}
