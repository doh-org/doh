import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static final light = ThemeData(
    useMaterial3: true,
    fontFamily: 'Pretendard',
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      surface: AppColors.white,
    ),
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.white,
      foregroundColor: AppColors.dark,
      elevation: 0,
      centerTitle: true,
    ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: AppColors.folderOrange,
      selectionHandleColor: AppColors.folderOrange,
      selectionColor: Color(0x33FE8505),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.black),
      displayMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.dark),
      displaySmall: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.dark),
      bodyLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: AppColors.dark),
      bodyMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: AppColors.dark),
      labelLarge: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.dark),
      bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.gray),
    ),
  );
}
