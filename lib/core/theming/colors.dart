import 'package:flutter/material.dart';

class ColorsManager {
  // === Modern Dark Theme Palette ===

  // Primary Colors
  static const Color primary = Color(
    0xFFFABAC7,
  ); // Pink Rose - Custom vibrant accent
  static const Color secondary = Color(0xFF10B981); // Emerald-500 - Fresh green

  // Background & Surface Colors
  static const Color backgroundColor = Color(
    0xFF121212,
  ); // Deep neutral background
  static const Color surface = Color(0xFF1F2937); // Gray-800 - Cards, inputs
  static const Color surfaceVariant = Color(
    0xFF111827,
  ); // Gray-900 - Darker variant

  // Text Colors
  static const Color onSurface = Color(0xFFF9FAFB); // Gray-50 - Primary text
  static const Color onSurfaceVariant = Color(
    0xFFD1D5DB,
  ); // Gray-300 - Secondary text

  // Utility Colors
  static const Color outline = Color(
    0xFF374151,
  ); // Gray-700 - Borders, dividers
  static const Color whiteColor = Color(0xFFFFFFFF); // Pure white (preserved)
  static const Color error = Color(0xFFEF4444); // Red-500 - Error states
  static const Color success = Color(
    0xFF10B981,
  ); // Emerald-500 - Success states
  static const Color warning = Color(0xFFF59E0B); // Amber-500 - Warning states

  // Legacy Colors (for backward compatibility during transition)
  @deprecated
  static const Color mainColor = primary; // Use 'primary' instead
  @deprecated
  static const Color grayColor = onSurfaceVariant; // Use 'onSurfaceVariant' instead
  @deprecated
  static const Color customGray = surface; // Use 'surface' instead
  @deprecated
  static const Color customRed = error; // Use 'error' instead
  @deprecated
  static const Color customOrange = warning; // Use 'warning' instead
  @deprecated
  static const Color customBlue = Color(0xFF06B6D4); // Old cyan color for legacy compatibility
  @deprecated
  static const Color customGreen = secondary; // Use 'secondary' instead
}
