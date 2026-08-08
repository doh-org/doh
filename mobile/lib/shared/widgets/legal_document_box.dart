import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// 약관 원문을 담는 고정 높이 스크롤 박스.
/// text를 그대로 표시하고 height로 박스 높이를 정한다(기본 180).
class LegalDocumentBox extends StatelessWidget {
  const LegalDocumentBox({
    required this.text,
    this.height = 180,
    super.key,
  });

  final String text;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(17),
      ),
      child: Scrollbar(
        child: SingleChildScrollView(
          child: Text(
            text,
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: AppColors.dark,
              height: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}
