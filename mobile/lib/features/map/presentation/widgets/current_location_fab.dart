import 'package:flutter/material.dart';

/// 현위치 이동 버튼(네이티브 버튼 대체)
/// 탭 시 호출부가 동의 게이트 → OS 권한 → 카메라 이동을 처리
/// 위치 표시 자체는 presentational, 로직은 map_page가
class CurrentLocationFab extends StatelessWidget {
  const CurrentLocationFab({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const ValueKey<String>('current_location_fab'),
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color(0x29000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          Icons.my_location,
          size: 22,
          color: Color(0xFFFE8505), // 현위치 아이콘 오렌지
        ),
      ),
    );
  }
}
