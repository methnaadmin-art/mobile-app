import 'package:flutter/widgets.dart';

class AppSpacing {
  AppSpacing._();

  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 40;
  static const double section = 32;

  static const double buttonHeight = 52;
  static const double buttonCompactHeight = 44;
  static const double inputHeight = 54;
  static const double bottomBarHeight = 74;

  static const EdgeInsets page = EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets pageWithTop = EdgeInsets.fromLTRB(lg, md, lg, xl);
  static const EdgeInsets card = EdgeInsets.all(md);
  static const EdgeInsets sheet = EdgeInsets.fromLTRB(lg, sm, lg, xl);
  static const EdgeInsets chip = EdgeInsets.symmetric(
    horizontal: sm,
    vertical: xs,
  );
}
