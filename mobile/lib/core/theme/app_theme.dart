import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static final light = ThemeData(
    useMaterial3: true,
    fontFamily: 'Pretendard',
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      surface: AppColors.surface,
    ),
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.onBackground,
      elevation: 0,
      centerTitle: true,
    ),
  );
}
