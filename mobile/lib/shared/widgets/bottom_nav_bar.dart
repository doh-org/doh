import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({required this.currentIndex, super.key});
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Color(0x1A000000), offset: Offset(0, -1), blurRadius: 4),
        ],
      ),
      // #20 justify-center gap-60
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _NavItem(icon: Icons.map_outlined, label: '지도', index: 0, current: currentIndex, onTap: null),
          const SizedBox(width: 60),
          _NavItem(icon: Icons.folder_outlined, label: '폴더', index: 1, current: currentIndex, onTap: null),
          const SizedBox(width: 60),
          _NavItem(icon: Icons.favorite_border, label: '좋아요', index: 2, current: currentIndex, onTap: null),
          const SizedBox(width: 60),
          _NavItem(icon: Icons.person_outline, label: '내 정보', index: 3, current: currentIndex, onTap: null),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.current,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final int index;
  final int current;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final active = index == current;
    final color = active ? AppColors.folderOrange : AppColors.gray;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 25),
          const SizedBox(height: 1), // #22 mt-26 - icon-25 = 1px
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
