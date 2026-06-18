import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../features/trips/presentation/providers/trip_provider.dart';

class BottomNavBar extends ConsumerWidget {
  const BottomNavBar({required this.currentIndex, super.key});
  final int currentIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    void onMapTap() {
      final trips = ref.read(tripsProvider).valueOrNull ?? [];
      if (trips.isEmpty) return;
      context.push('/trips/${trips.first.id}/map');
    }

    return ColoredBox(
      color: Colors.white,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(17),
            topRight: Radius.circular(17),
          ),
          boxShadow: [
            BoxShadow(color: Color(0x1A000000), offset: Offset(0, -1), blurRadius: 4),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 64,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _NavItem(icon: Icons.map_outlined, label: '지도', index: 0, current: currentIndex, onTap: onMapTap),
                  const SizedBox(width: 80),
                  _NavItem(icon: Icons.folder_outlined, label: '폴더', index: 1, current: currentIndex, onTap: null),
                  const SizedBox(width: 80),
                  _NavItem(icon: Icons.person_outline, label: '내 정보', index: 2, current: currentIndex, onTap: null),
                ],
              ),
            ),
            SizedBox(height: bottomInset),
          ],
        ),
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
          const SizedBox(height: 1),
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
