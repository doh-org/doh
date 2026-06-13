import 'package:flutter/material.dart';

Color categoryColor(String? name) => switch (name) {
      '식당' => const Color(0xFFFE8505),
      '카페' => const Color(0xFFFFCC00),
      '관광' => const Color(0xFF2A6FDB),
      '숙소' => const Color(0xFF34C759),
      _ => const Color(0xFF8A847B),
    };
