import 'package:flutter/material.dart';

class Responsive {
  Responsive._();

  static double width(BuildContext context) => MediaQuery.of(context).size.width;
  static double height(BuildContext context) => MediaQuery.of(context).size.height;

  static bool isSmall(BuildContext context) => width(context) < 360;
  static bool isLarge(BuildContext context) => width(context) >= 414;

  // Horizontal page padding — tighter on small screens
  static double hPad(BuildContext context) => isSmall(context) ? 14.0 : 20.0;

  // Scale a base font size proportionally to screen width
  static double fs(BuildContext context, double base) {
    final w = width(context);
    if (w < 360) return base * 0.88;
    if (w > 430) return base * 1.05;
    return base;
  }

  // Fraction of screen width, clamped between min and max
  static double widthFraction(BuildContext context, double fraction, {double min = 0, double max = double.infinity}) {
    return (width(context) * fraction).clamp(min, max);
  }
}
