import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Brand Primary (#6E3DFB) ──────────────────────────────────────
  static const Color primary = Color(0xFF6E3DFB);
  static const Color primaryLight = Color(0xFFA78BFA);
  static const Color primaryDark = Color(0xFF4F26D9);
  static const Color secondary = Color(0xFF8B5CF6);
  static const Color secondaryLight = Color(0xFFA78BFA);
  static const Color secondaryDark = Color(0xFF4F26D9);
  static const Color primarySurface = Color(0xFFF4F0FF);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6E3DFB), Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient brandGradient = primaryGradient;
  static const LinearGradient accentGradient = primaryGradient;
  static const LinearGradient darkGradient = primaryGradient;
  static const LinearGradient goldGradient = primaryGradient;
  static const LinearGradient goldButtonGradient = primaryGradient;
  static const LinearGradient softGoldGradient = primaryGradient;
  static const LinearGradient emeraldGradient = primaryGradient;
  static const LinearGradient premiumGradient = primaryGradient;
  static const LinearGradient islamicGradient = primaryGradient;
  static const LinearGradient goldPremiumGradient = primaryGradient;

  // ── Semantic Colors ───────────────────────────────────────────────
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFDC2626);
  static const Color info = Color(0xFF3B82F6);

  static const Color smoothBeige = Color(0xFFFFFFFF);

  // ── Light Theme Surfaces ──────────────────────────────────────────
  static const Color canvasLight = Color(0xFFF4F0FF);
  static const Color backgroundLight = Color(0xFFF4F0FF);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceMutedLight = Color(0xFFF4F0FF);
  static const Color surfaceGlassLight = Color(0xF4FFFFFF);
  static const Color chipLight = Color(0xFFF4F0FF);
  static const Color textPrimaryLight = Color(0xFF1A1626);
  static const Color textSecondaryLight = Color(0xFF6A6780);
  static const Color textHintLight = Color(0xFF9592AB);
  static const Color borderLight = Color(0xFFDDD6FE);
  static const Color dividerLight = Color(0xFFEDE9FE);
  static const Color handleLight = Color(0xFFC4B5FD);

  // ── Dark Theme Surfaces ───────────────────────────────────────────
  static const Color canvasDark = Color(0xFF0D0A12);
  static const Color backgroundDark = Color(0xFF110E18);
  static const Color surfaceDark = Color(0xFF191525);
  static const Color cardDark = Color(0xFF231D30);
  static const Color surfaceMutedDark = Color(0xFF241E32);
  static const Color surfaceGlassDark = Color(0xF0221D30);
  static const Color chipDark = Color(0xFF2B243C);
  static const Color textPrimaryDark = Color(0xFFF8F7FC);
  static const Color textSecondaryDark = Color(0xFFB7B1CA);
  static const Color textHintDark = Color(0xFF827C97);
  static const Color borderDark = Color(0xFF342D44);
  static const Color dividerDark = Color(0xFF241F32);
  static const Color handleDark = Color(0xFF443B58);

  // ── Action / Status Colors ───────────────────────────────────────
  static const Color like = primary;
  static const Color superLike = primaryDark;
  static const Color boost = primaryLight;
  static const Color pass = primaryDark;
  static const Color online = Color(0xFF22C55E);
  static const Color verified = Color(0xFF45B7FF);
  static const Color premium = primaryDark;

  static const Color emerald = primary;
  static const Color emeraldLight = primaryLight;
  static const Color gold = primary;
  static const Color goldLight = primaryLight;
  static const Color parchment = backgroundLight;
}
