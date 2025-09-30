import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:moochat/core/helpers/logger_debug.dart';
import 'package:moochat/core/theming/colors.dart';
import 'package:moochat/core/theming/font_weight_helper.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomTextStyles {
  // Static variable to store current locale - set this in your main app
  static String _currentLocale = 'ar';

  // Method to update locale - call this when locale changes
  static void updateLocale(String locale) {
    _currentLocale = locale;
    LoggerDebug.logger.t('Locale updated to: $_currentLocale');
  }

  static TextStyle get font24WhiteBold => TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: ColorsManager.whiteColor,
  );

  static TextStyle get font18WhiteMedium => const TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: ColorsManager.whiteColor,
  );

  static TextStyle get font14WhiteMedium => const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: ColorsManager.whiteColor,
  );

  static TextStyle get font14WhiteRegular => const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: ColorsManager.whiteColor,
  );

  // Helper method to get the appropriate font based on current locale
  static TextStyle _getTextStyle({
    required double fontSize,
    required FontWeight fontWeight,
    required Color color,
  }) {
    // Use Noto Sans Thai font for optimal Thai text rendering
    return GoogleFonts.notoSansThai(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }

  static TextStyle font16GrayRegular = _getTextStyle(
    fontSize: 16.sp,
    fontWeight: FontWeightHelper.regular,
    color: ColorsManager.onSurfaceVariant,
  );

  static TextStyle font32WhiteBold = _getTextStyle(
    fontSize: 32.sp,
    fontWeight: FontWeightHelper.bold,
    color: ColorsManager.onSurface,
  );

  static TextStyle font16WhiteRegular = _getTextStyle(
    fontSize: 16.sp,
    fontWeight: FontWeightHelper.regular,
    color: ColorsManager.onSurface,
  );

  static TextStyle font20WhiteRegular = _getTextStyle(
    fontSize: 20.sp,
    fontWeight: FontWeightHelper.regular,
    color: ColorsManager.onSurface,
  );

  static TextStyle font16RedRegular = _getTextStyle(
    fontSize: 16.sp,
    fontWeight: FontWeightHelper.regular,
    color: ColorsManager.error,
  );

  static TextStyle font14GrayRegular = _getTextStyle(
    fontSize: 14.sp,
    fontWeight: FontWeightHelper.regular,
    color: ColorsManager.onSurfaceVariant,
  );

  static TextStyle font12WhiteRegular = _getTextStyle(
    fontSize: 12.sp,
    fontWeight: FontWeightHelper.regular,
    color: ColorsManager.onSurface,
  );

  static TextStyle font20WhiteBold = _getTextStyle(
    fontSize: 20.sp,
    fontWeight: FontWeightHelper.bold,
    color: ColorsManager.onSurface,
  );

  // Getter methods that rebuild styles when locale changes
  static TextStyle get font16GrayRegularDynamic => _getTextStyle(
    fontSize: 16.sp,
    fontWeight: FontWeightHelper.regular,
    color: ColorsManager.onSurfaceVariant,
  );

  static TextStyle get font32WhiteBoldDynamic => _getTextStyle(
    fontSize: 32.sp,
    fontWeight: FontWeightHelper.bold,
    color: ColorsManager.onSurface,
  );

  static TextStyle get font16WhiteRegularDynamic => _getTextStyle(
    fontSize: 16.sp,
    fontWeight: FontWeightHelper.regular,
    color: ColorsManager.onSurface,
  );

  static TextStyle get font20WhiteRegularDynamic => _getTextStyle(
    fontSize: 20.sp,
    fontWeight: FontWeightHelper.regular,
    color: ColorsManager.onSurface,
  );

  static TextStyle get font16RedRegularDynamic => _getTextStyle(
    fontSize: 16.sp,
    fontWeight: FontWeightHelper.regular,
    color: ColorsManager.error,
  );

  static TextStyle get font14GrayRegularDynamic => _getTextStyle(
    fontSize: 14.sp,
    fontWeight: FontWeightHelper.regular,
    color: ColorsManager.onSurfaceVariant,
  );

  static TextStyle get font12WhiteRegularDynamic => _getTextStyle(
    fontSize: 12.sp,
    fontWeight: FontWeightHelper.regular,
    color: ColorsManager.onSurface,
  );

  static TextStyle get font20WhiteBoldDynamic => _getTextStyle(
    fontSize: 20.sp,
    fontWeight: FontWeightHelper.bold,
    color: ColorsManager.onSurface,
  );
}
