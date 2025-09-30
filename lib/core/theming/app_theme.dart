import 'package:flutter/material.dart';
import 'package:moochat/core/theming/colors.dart';

class AppTheme {
  // Private constructor to prevent instantiation
  AppTheme._();

  /// Modern Dark Theme Configuration
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      // Color Scheme
      colorScheme: const ColorScheme.dark(
        primary: ColorsManager.primary,
        secondary: ColorsManager.secondary,
        surface: ColorsManager.surface,
        surfaceVariant: ColorsManager.surfaceVariant,
        background: ColorsManager.backgroundColor,
        onSurface: ColorsManager.onSurface,
        onSurfaceVariant: ColorsManager.onSurfaceVariant,
        outline: ColorsManager.outline,
        error: ColorsManager.error,
      ),

      // Scaffold Background
      scaffoldBackgroundColor: ColorsManager.backgroundColor,

      // App Bar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: ColorsManager.backgroundColor,
        foregroundColor: ColorsManager.onSurface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: ColorsManager.onSurface,
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: ColorsManager.surface,
        elevation: 2,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorsManager.primary,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: Colors.black26,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ColorsManager.primary,
          side: const BorderSide(color: ColorsManager.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: ColorsManager.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ColorsManager.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ColorsManager.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ColorsManager.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ColorsManager.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ColorsManager.error),
        ),
        labelStyle: const TextStyle(color: ColorsManager.onSurfaceVariant),
        hintStyle: const TextStyle(color: ColorsManager.onSurfaceVariant),
      ),

      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: ColorsManager.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: ColorsManager.onSurface,
        ),
        contentTextStyle: const TextStyle(
          fontSize: 16,
          color: ColorsManager.onSurfaceVariant,
        ),
      ),

      // Bottom Sheet Theme
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: ColorsManager.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),

      // Icon Theme
      iconTheme: const IconThemeData(
        color: ColorsManager.onSurfaceVariant,
        size: 24,
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: ColorsManager.outline,
        thickness: 1,
      ),
    );
  }

  /// Light Theme (Optional - for future use)
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      // For now, return dark theme as the app is designed for dark mode
      // You can implement light theme later if needed
    );
  }
}
