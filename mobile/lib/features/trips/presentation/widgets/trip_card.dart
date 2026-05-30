import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/trip.dart';

class TripCard extends StatelessWidget {
  const TripCard({
    required this.trip,
    required this.onTap,
    required this.onEditTap,
    super.key,
  });

  final Trip trip;
  final VoidCallback onTap;
  final VoidCallback onEditTap;

  String _dateRange() {
    final s = trip.startDate;
    final e = trip.endDate;
    if (s == null || e == null) return '';
    return '${s.year}.${_p(s.month)}.${_p(s.day)} ~ ${e.year}.${_p(e.month)}.${_p(e.day)}';
  }

  String _p(int v) => v.toString().padLeft(2, '0');

  Color _coverColor() {
    final hex = trip.coverColor;
    if (hex == null) return AppColors.coverColors[0];
    try {
      return Color(int.parse(hex.replaceFirst('#', 'FF'), radix: 16));
    } catch (_) {
      return AppColors.coverColors[0];
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(17),
          boxShadow: const [
            BoxShadow(color: Color(0x1A000000), offset: Offset(-4, -4), blurRadius: 4),
            BoxShadow(color: Color(0x1A000000), offset: Offset(4, 4), blurRadius: 4),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 90, color: _coverColor()),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trip.title,
                    style: const TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _dateRange(),
                    style: const TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.gray,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text(
                        'Total 12',
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: AppColors.gray,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: onEditTap,
                        child: const Icon(
                          Icons.edit_outlined,
                          size: 18,
                          color: AppColors.gray,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
