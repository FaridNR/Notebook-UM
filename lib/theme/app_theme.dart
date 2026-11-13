import 'package:flutter/material.dart';

class AppColors {
  // Light Palette
  static const Color lightBg = Color(0xFFF1F3F5);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceStep = Color(0xFFF8F9FA);
  static const Color lightSurfaceStep2 = Color(0xFFE9ECF0);
  static const Color lightSurfacePill = Color(0xFFF4F5F7);

  static const Color lightTextPrimary = Color(0xFF090A0C);
  static const Color lightTextSecondary = Color(0xFF52525B);
  static const Color lightTextTertiary = Color(0xFF71717A);

  // Dark Palette
  static const Color darkBg = Color(0xFF090A0C);
  static const Color darkSurface = Color(0xFF121316);
  static const Color darkSurfaceStep = Color(0xFF18191E);
  static const Color darkSurfaceStep2 = Color(0xFF1A1C22);
  static const Color darkSurfacePill = Color(0xFF20222A);

  static const Color darkTextPrimary = Color(0xFFF4F4F5);
  static const Color darkTextSecondary = Color(0xFFA1A1AA);
  static const Color darkTextTertiary = Color(0xFF71717A);

  // Academic Course Colors (Muted Elegant Slate/Zinc Palette)
  static const Color amberAccent = Color(0xFF78716C);
  static const Color amberLightBg = Color(0xFFF5F5F4);
  static const Color amberDarkBg = Color(0xFF1C1917);
  static const Color amberText = Color(0xFF44403C);
  static const Color amberTextDark = Color(0xFFD6D3D1);

  static const Color blueAccent = Color(0xFF64748B);
  static const Color blueLightBg = Color(0xFFF1F5F9);
  static const Color blueDarkBg = Color(0xFF131722);
  static const Color blueText = Color(0xFF334155);
  static const Color blueTextDark = Color(0xFFCBD5E1);

  static const Color emeraldAccent = Color(0xFF52525B);
  static const Color emeraldLightBg = Color(0xFFF4F4F5);
  static const Color emeraldDarkBg = Color(0xFF18181B);
  static const Color emeraldText = Color(0xFF27272A);
  static const Color emeraldTextDark = Color(0xFFD4D4D8);

  static const Color purpleAccent = Color(0xFF71717A);
  static const Color purpleLightBg = Color(0xFFF4F4F5);
  static const Color purpleDarkBg = Color(0xFF18181B);
  static const Color purpleText = Color(0xFF3F3F46);
  static const Color purpleTextDark = Color(0xFFE4E4E7);

  static const Color roseAccent = Color(0xFFE11D48);
  static const Color roseLightBg = Color(0xFFFFF1F2);
  static const Color roseDarkBg = Color(0xFF201216);
  static const Color roseText = Color(0xFFBE123C);
  static const Color roseTextDark = Color(0xFFFDA4AF);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightBg,
      colorScheme: const ColorScheme.light(
        surface: AppColors.lightSurface,
        onSurface: AppColors.lightTextPrimary,
        primary: Color(0xFF090A0C),
        onPrimary: Colors.white,
      ),
      fontFamily: '-apple-system',
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.lightSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color: AppColors.lightTextPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),
      cardTheme: const CardThemeData(
        color: AppColors.lightSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBg,
      colorScheme: const ColorScheme.dark(
        surface: AppColors.darkSurface,
        onSurface: AppColors.darkTextPrimary,
        primary: Color(0xFFF4F4F5),
        onPrimary: Color(0xFF090A0C),
      ),
      fontFamily: '-apple-system',
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color: AppColors.darkTextPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),
      cardTheme: const CardThemeData(
        color: AppColors.darkSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
    );
  }
}
