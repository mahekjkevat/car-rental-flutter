// app_theme.dart
import 'package:flutter/material.dart';

// --- Consistent Color Definitions ---
const Color primaryOrange = Color(0xFFE65100);
const Color brownColor = Color(0xFF795548);
const Color grayText = Color(0xFF757575);
const Color darkGrayText = Color(0xFF5A5A5A);
const Color lightBackground = Colors.white;

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: primaryOrange,
      scaffoldBackgroundColor: lightBackground,
      appBarTheme: AppBarTheme(
        backgroundColor: primaryOrange,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryOrange,
        foregroundColor: Colors.white,
      ),
    );
  }
}