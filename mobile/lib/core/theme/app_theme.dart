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
    // 색 지정 없는 로딩 인디케이터의 기본색. 버튼 위 흰색 스피너는 각자 명시라 영향 없음.
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.folderOrange,
    ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: AppColors.folderOrange,
      selectionHandleColor: AppColors.folderOrange,
      selectionColor: Color(0x33FE8505),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.black),
      displayMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.dark),
      displaySmall: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.dark),
      bodyLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: AppColors.dark),
      bodyMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.dark),
      labelLarge: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.dark),
      bodySmall: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.gray),
    ),
  );
}
