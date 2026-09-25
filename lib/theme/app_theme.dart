import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static const ColorScheme _scheme = ColorScheme.dark(
    primary: AppColors.primary,
    onPrimary: Colors.white,
    secondary: AppColors.info,
    onSecondary: Colors.black,
    surface: AppColors.surface,
    onSurface: AppColors.textPrimary,
    error: AppColors.critical,
    onError: Colors.white,
    outline: AppColors.border,
  );

  static ThemeData get dark {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: _scheme,
    );

    final text = base.textTheme
        .apply(
          bodyColor: AppColors.textPrimary,
          displayColor: AppColors.textPrimary,
        )
        .copyWith(
          headlineLarge: const TextStyle(
            fontSize: 28,
            height: 1.2,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
          headlineMedium: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
          titleLarge: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
          titleMedium: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          bodyLarge: const TextStyle(
            fontSize: 15,
            height: 1.4,
            color: AppColors.textPrimary,
          ),
          bodyMedium: const TextStyle(
            fontSize: 13,
            height: 1.4,
            color: AppColors.textSecondary,
          ),
          labelLarge: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.bg,
      textTheme: text,
      dividerColor: AppColors.border,
      iconTheme: const IconThemeData(color: AppColors.textPrimary, size: 22),
      splashFactory: InkSparkle.splashFactory,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        hintStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
        prefixIconColor: AppColors.textSecondary,
        suffixIconColor: AppColors.textSecondary,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.primary,
        selectionColor: Color(0x33FF3B5C),
      ),
    );
  }
}
