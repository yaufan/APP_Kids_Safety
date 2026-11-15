import 'package:flutter/material.dart';

/// The app's colours (docs/design.md 「畫風：漫畫網點風」): flat signal colours,
/// a dark-blue ink for outlines and words, a pale page.
abstract final class Comic {
  static const ink = Color(0xFF1E3A6E);
  static const inkSoft = Color(0xFF5F6E8A);
  static const page = Color(0xFFEEF3F7);
  static const yellow = Color(0xFFFFC400);
  static const yellowSoft = Color(0xFFFFE27A);
  static const red = Color(0xFFE8392F);
  static const green = Color(0xFF1FA64A);
  static const blue = Color(0xFF1F6FD6);
  static const orange = Color(0xFFFF8A1E);
  static const pink = Color(0xFFF27AA0);
  static const grey = Color(0xFFD5DBE0);
  static const card = Colors.white;

  // Parent mode is a plain, light page.
  static const parentBg = Color(0xFFF3F5F8);
  static const parentInk = Color(0xFF26324A);
  static const parentSoft = Color(0xFF6B7690);
}

abstract final class ComicTheme {
  /// jf open 粉圓 (OFL): a rounded typeface made in Taiwan.
  static const font = 'Huninn';

  static ThemeData light() {
    final base = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Comic.blue, surface: Colors.white),
      scaffoldBackgroundColor: Comic.page,
      fontFamily: font,
    );
    return base.copyWith(textTheme: base.textTheme.apply(bodyColor: Comic.ink, displayColor: Comic.ink, fontFamily: font));
  }
}
