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
    if (s == null) return '';
    final sStr = '${s.year}.${_p(s.month)}.${_p(s.day)}';
    if (e == null || (s.year == e.year && s.month == e.month && s.day == e.day)) return sStr;
    return '$sStr ~ ${e.year}.${_p(e.month)}.${_p(e.day)}';
  }

  String _p(int v) => v.toString().padLeft(2, '0');

  Color _coverColor() {
    final hex = trip.coverColor;
    if (hex == null) return AppColors.coverColors[0];
    try {
      return Color(int.parse(hex.replaceFirst('#', '80'), radix: 16));
    } catch (_) {
      return AppColors.coverColors[0];
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(17),
          boxShadow: const [
            BoxShadow(color: Color(0x1A000000), offset: Offset(-4, -4), blurRadius: 4),
            BoxShadow(color: Color(0x1A000000), offset: Offset(4, 4), blurRadius: 4),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 15),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 90,
                        decoration: BoxDecoration(
                          color: _coverColor(),
                          borderRadius: BorderRadius.circular(17),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        trip.title,
                        style: const TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.black,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _dateRange(),
                        style: const TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: AppColors.gray,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.fromLTRB(15, 0, 15, 10),
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(fontFamily: 'Pretendard'),
                      children: [
                        const TextSpan(
                          text: 'Total ',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.gray,
                          ),
                        ),
                        TextSpan(
                          text: '${trip.markerNum}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.folderOrange,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              right: 0,
              bottom: 0, // 40px 아이콘이 카드(높이 200) 아래로 잘리지 않게 하단 기준 배치
              child: GestureDetector(
                onTap: onEditTap,
                child: const Padding(
                  padding: EdgeInsets.fromLTRB(15, 13, 15, 13),
                  child: Icon(Icons.edit_outlined, size: 30, color: AppColors.gray),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
