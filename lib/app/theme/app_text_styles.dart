import 'package:flutter/material.dart';

class AppTextStyles {
  AppTextStyles._();

  // Use platform-default font (Roboto on Android, SF Pro on iOS).
  // These fonts have full Arabic/RTL glyph coverage — unlike Poppins
  // which is Latin-only and causes garbled Arabic text in release builds.
  static const TextStyle _baseFont = TextStyle();

  static TextStyle displayLarge = _baseFont.copyWith(
    fontSize: 34,
    fontWeight: FontWeight.w800,
    letterSpacing: 0,
    height: 1.12,
  );

  static TextStyle displayMedium = _baseFont.copyWith(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
    height: 1.18,
  );

  static TextStyle displaySmall = _baseFont.copyWith(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
    height: 1.22,
  );

  static TextStyle headlineLarge = _baseFont.copyWith(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
    height: 1.26,
  );

  static TextStyle headlineMedium = _baseFont.copyWith(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
    height: 1.3,
  );

  static TextStyle headlineSmall = _baseFont.copyWith(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
    height: 1.35,
  );

  static TextStyle titleLarge = _baseFont.copyWith(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
    height: 1.35,
  );

  static TextStyle titleMedium = _baseFont.copyWith(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.4,
  );

  static TextStyle titleSmall = _baseFont.copyWith(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.35,
  );

  static TextStyle bodyLarge = _baseFont.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.5,
  );

  static TextStyle bodyMedium = _baseFont.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.5,
  );

  static TextStyle bodySmall = _baseFont.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.45,
  );

  static TextStyle labelLarge = _baseFont.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
    height: 1.3,
  );

  static TextStyle labelMedium = _baseFont.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.3,
  );

  static TextStyle labelSmall = _baseFont.copyWith(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.25,
  );

  static TextStyle button = _baseFont.copyWith(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
    height: 1.2,
  );

  static TextStyle get largeTitle => displayLarge;
  static TextStyle get screenTitle => displaySmall;
  static TextStyle get sectionTitle => titleMedium;
  static TextStyle get subtitle => bodyLarge;
  static TextStyle get body => bodyMedium;
  static TextStyle get secondaryBody => bodySmall;
  static TextStyle get caption => labelSmall;
  static TextStyle get inputLabel => labelMedium;
  static TextStyle get error => labelSmall;
}
