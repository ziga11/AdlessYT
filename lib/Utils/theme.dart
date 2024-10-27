// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';

class YTTheme {
  static Color orange = Color(0xFFFF6F00);
  static Color blue = Color(0xFF007BFF);
  static Color white = Color(0xFFFFFFFF);
  static Color darkGray = Color(0xFF1E1E1E);
  static Color lightGray = Color(0xFF6C757D);

  ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: Colors.orange,
    scaffoldBackgroundColor: const Color(0xFF121212),
    cardColor: const Color(0xFF1E1E1E),
    dividerColor: const Color(0xFF383838),
    colorScheme: const ColorScheme.dark(
      primary: Colors.orange,
      secondary: Colors.blue,
      surface: Color(0xFF1E1E1E),
      onPrimary: Color(0xFFFFFFFF),
      onSecondary: Color(0xFFFFFFFF),
      onError: Color(0xFFFFFFFF),
      onSurface: Color(0xFFE0E0E0),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFFE0E0E0)),
      bodyMedium: TextStyle(color: Color(0xFFE0E0E0)),
      titleLarge: TextStyle(color: Color(0xFFFFFFFF)),
    ),
  );
}
