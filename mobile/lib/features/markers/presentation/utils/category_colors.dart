import 'package:flutter/material.dart';

Color categoryColor(String? name) => switch (name) {
      '식당' => const Color(0xFFFE8505),
      '카페' => const Color(0xFFFFCC00),
      '관광' => const Color(0xFF2A6FDB),
      '숙소' => const Color(0xFF34C759),
      _ => const Color(0xFF8A847B),
    };

/// 카테고리 칩 배경색. 마커/경로 시트 전반에서 공통 사용.
Color categoryChipColor(String? name) =>
    categoryColor(name).withValues(alpha: 0.5);
