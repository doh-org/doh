import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const primary = Color(0xFFFF8830);
  static const primaryDark = Color(0xFFFF6D00);
  static const background = Color(0xFFF1F2F4);
  static const gray = Color(0xFF7E7E7E);
  static const dark = Color(0xFF1F2125);
  static const black = Color(0xFF070707);
  static const blue = Color(0xFF2A6FDB);
  static const yellow = Color(0xFFF6DF0C);
  static const error = Color(0xFFEC2113);
  static const white = Color(0xFFFFFFFF);

  // 폴더 화면 전용
  static const folderOrange = Color(0xFFFE8505);

  // 커버 색상 팔레트 (50% fill)
  static const List<Color> coverColors = [
    Color(0x80D5D5D5), // 회색
    Color(0x80FE8505), // 주황
    Color(0x802A6FDB), // 파랑
    Color(0x8039DA57), // 초록
    Color(0x80F6DF0C), // 노랑
    Color(0x80EC1E13), // 빨강
  ];

  // 커버 색상 hex 문자열 (API 저장용)
  static const List<String> coverColorHexes = [
    '#D5D5D5', '#FE8505', '#2A6FDB', '#39DA57', '#F6DF0C', '#EC1E13',
  ];

  // 카테고리
  static const catFood = Color(0xFFFF6B6B);
  static const catCafe = Color(0xFFFFB347);
  static const catTourism = Color(0xFF4ECDC4);
  static const catLodging = Color(0xFF5DADE2);
  static const catEtc = Color(0xFF95A5A6);
}
