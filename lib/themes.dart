import 'package:flutter/material.dart';

class AppTheme {
  // Light Mode Colors
  static const Color primaryRed = Color(0xFFE53E3E);
  static const Color redLight = Color(0xFFFED7D7);
  static const Color redDark = Color(0xFFC53030);
  static const Color gold = Color(0xFFD69E2E);
  static const Color goldLight = Color(0xFFFAF3E3);

  // Light Mode
  static const Color lightBackground = Color(0xFFF7FAFC);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightText = Color(0xFF2D3748);
  static const Color lightTextSecondary = Color(0xFF4A5568);

  // Dark Mode Colors
  static const Color darkBackground = Color(0xFF1A202C);
  static const Color darkCard = Color(0xFF2D3748);
  static const Color darkText = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFE2E8F0);

  // Gradients
  static Gradient get primaryGradient {
    return const LinearGradient(
      colors: [primaryRed, redDark],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  static Gradient get goldGradient {
    return const LinearGradient(
      colors: [gold, Color(0xFFB7791F)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  // Helper methods
  static Color backgroundColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkBackground
        : lightBackground;
  }

  static Color cardColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkCard
        : lightCard;
  }

  static Color textColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkText
        : lightText;
  }

  static Color textSecondaryColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkTextSecondary
        : lightTextSecondary;
  }

  // Responsive Helpers
  static double responsiveFontSize(BuildContext context, double baseFontSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 360) {
      return baseFontSize * 0.8;
    } else if (screenWidth < 400) {
      return baseFontSize * 0.9;
    }
    return baseFontSize;
  }

  static EdgeInsets responsivePadding(BuildContext context, {double horizontal = 24.0, double vertical = 0.0}) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 360) {
      return EdgeInsets.symmetric(horizontal: horizontal * 0.8, vertical: vertical);
    } else if (screenWidth < 400) {
      return EdgeInsets.symmetric(horizontal: horizontal * 0.9, vertical: vertical);
    }
    return EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical);
  }

  // Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: primaryRed,
      scaffoldBackgroundColor: lightBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: lightCard,
        foregroundColor: lightText,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: lightCard,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      useMaterial3: true,
    );
  }

  // Dark Theme
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryRed,
      scaffoldBackgroundColor: darkBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: darkCard,
        foregroundColor: darkText,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: darkCard,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      useMaterial3: true,
    );
  }
}