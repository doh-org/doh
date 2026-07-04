import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// 앱 전역 공용 뒤로가기 버튼.
/// 아이콘·크기·색은 고정, 동작(onTap)과 위치 여백(padding)만 주입한다.
class AppBackButton extends StatelessWidget {
  const AppBackButton({
    required this.onTap,
    this.padding = EdgeInsets.zero,
    super.key,
  });

  final VoidCallback onTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: padding,
        child: const Icon(
          Icons.arrow_back_ios_new,
          size: 20,
          color: AppColors.dark,
        ),
      ),
    );
  }
}
