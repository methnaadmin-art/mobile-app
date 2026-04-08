import 'package:flutter/widgets.dart';

class AppSpacing {
  AppSpacing._();

  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 28;
  static const double xxxl = 32;
  static const double section = 40;

  static const double buttonHeight = 58;
  static const double inputHeight = 56;
  static const double bottomBarHeight = 74;

  static const EdgeInsets page = EdgeInsets.symmetric(horizontal: xl);
  static const EdgeInsets pageWithTop = EdgeInsets.fromLTRB(xl, md, xl, xl);
  static const EdgeInsets card = EdgeInsets.all(lg);
  static const EdgeInsets sheet = EdgeInsets.fromLTRB(xl, sm, xl, xl);
  static const EdgeInsets chip = EdgeInsets.symmetric(
    horizontal: md,
    vertical: sm,
  );
}
