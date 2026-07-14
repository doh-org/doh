import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.white,
      body: Align(
        // 정중앙보다 살짝 위(-0.25)에 로고를 배치한 온보딩 화면
        alignment: Alignment(0, -0.25),
        child: Image(
          image: AssetImage('assets/memotrip_logo.png'),
          width: 220, // 가로형 로고라 폭 기준으로 크기 지정
        ),
      ),
    );
  }
}
