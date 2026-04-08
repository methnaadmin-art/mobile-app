import 'package:flutter/material.dart';
import 'package:methna_app/core/utils/google_fonts_stub.dart';

class AppTextStyles {
  AppTextStyles._();

  static TextStyle get _displayFont => GoogleFonts.sora();
  static TextStyle get _sansFont => GoogleFonts.dmSans();

  static TextStyle displayLarge = _displayFont.copyWith(
    fontSize: 36,
    fontWeight: FontWeight.w800,
    letterSpacing: -1.2,
    height: 1.08,
  );

  static TextStyle displayMedium = _displayFont.copyWith(
    fontSize: 30,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.8,
    height: 1.12,
  );

  static TextStyle displaySmall = _displayFont.copyWith(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.6,
    height: 1.18,
  );

  static TextStyle headlineLarge = _displayFont.copyWith(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    height: 1.2,
  );

  static TextStyle headlineMedium = _displayFont.copyWith(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    height: 1.24,
  );

  static TextStyle headlineSmall = _displayFont.copyWith(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
    height: 1.3,
  );

  static TextStyle titleLarge = _sansFont.copyWith(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
    height: 1.3,
  );

  static TextStyle titleMedium = _sansFont.copyWith(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    height: 1.35,
  );

  static TextStyle titleSmall = _sansFont.copyWith(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    height: 1.35,
  );

  static TextStyle bodyLarge = _sansFont.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.55,
  );

  static TextStyle bodyMedium = _sansFont.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.55,
  );

  static TextStyle bodySmall = _sansFont.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.5,
  );

  static TextStyle labelLarge = _sansFont.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.2,
    height: 1.3,
  );

  static TextStyle labelMedium = _sansFont.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.15,
    height: 1.3,
  );

  static TextStyle labelSmall = _sansFont.copyWith(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.1,
    height: 1.25,
  );

  static TextStyle button = _sansFont.copyWith(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.15,
    height: 1.2,
  );
}
