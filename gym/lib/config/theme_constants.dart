import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFF171717); // Dark Grey 1
  static const Color surface = Color(0xFF1B1C19); // Dark Grey 2 (Cards)
  static const Color surfaceVariant = Color(0xFF2F302E); // Dark Grey 3
  static const Color primary = Color(0xFFBCFF31); // Lime Green
  static const Color secondary = Color(0xFF2563EB); // Blue
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFF94978F); // Grey
  static const Color error = Color(0xFFEF4444); // Red
}

class AppTheme {
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.background,
    primaryColor: AppColors.primary,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      surface: AppColors.surface,
      error: AppColors.error,
      onPrimary: Color(0xFF0F172A), // Text on primary button should be dark
      onSurface: AppColors.textPrimary,
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.bold,
        fontSize: 32,
      ),
      headlineMedium: TextStyle(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.bold,
        fontSize: 24,
      ),
      bodyLarge: TextStyle(color: AppColors.textPrimary),
      bodyMedium: TextStyle(color: AppColors.textSecondary),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      hintStyle: const TextStyle(color: AppColors.textSecondary),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.background, // Text color
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        // Remove textStyle here to use default or let it be styled by text theme if needed
        // to avoid interpolation issues. We can set it directly on the button text if really needed
        // but default labelLarge is usually fine.
      ),
    ),
  );
}
