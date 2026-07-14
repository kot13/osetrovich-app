import 'package:flutter/material.dart';
import 'package:osetrovich/core/theme/app_colors.dart';

abstract final class AppTheme {
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.background,
        onPrimary: Colors.white,
        onSurface: AppColors.dark,
      ),
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.dark,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
      ),
      chipTheme: ChipThemeData(
        selectedColor: AppColors.accent,
        labelStyle: const TextStyle(color: AppColors.dark),
        secondaryLabelStyle: const TextStyle(color: AppColors.dark),
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.dark,
        ),
      ),
    );
  }
}
