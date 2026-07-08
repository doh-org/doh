import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../trips/domain/entities/trip.dart';

// ── 날짜 표기 헬퍼 (테스트를 위해 최상위 함수로 공개) ─────────────────────────

// yyyy.MM.dd. null이면 빈 문자열.
String formatTripDate(DateTime? d) {
  if (d == null) return '';
  return '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';
}

// "시작 ~ 종료". 한쪽만 있으면 그쪽만, 둘 다 없으면 빈 문자열.
String tripDateRange(Trip t) {
  final String s = formatTripDate(t.startDate);
  final String e = formatTripDate(t.endDate);
  if (s.isEmpty && e.isEmpty) return '';
  if (s.isEmpty) return e;
  if (e.isEmpty) return s;
  return '$s ~ $e';
}

// "#RRGGBB" → Color. 파싱 실패·null이면 기본 회색.
// 커버 팔레트(AppColors.coverColors)와 동일하게 50% 알파(0x80)로 채운다.
Color tripCoverColor(Trip t) {
  if (t.coverColor == null) return AppColors.coverColors[0];
  try {
    return Color(int.parse(t.coverColor!.replaceFirst('#', '80'), radix: 16));
  } catch (_) {
    return AppColors.coverColors[0];
  }
}

// Trip 선택 바텀 시트. 항목 탭 → onSelected(tripId) 후 닫힘.
class TripSelectorSheet extends StatelessWidget {
  const TripSelectorSheet({
    required this.trips,
    required this.currentTripId,
    required this.onSelected,
    super.key,
  });
  final List<Trip> trips;
  final String currentTripId;
  final void Function(String) onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 9),
          width: 82,
          height: 5,
          decoration: BoxDecoration(
            color: const Color(0xFFECEBE7),
            borderRadius: BorderRadius.circular(2.5),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(38, 10, 23, 10),
          child: Row(
            children: [
              const Text(
                '폴더 선택',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF070707),
                ),
              ),
              const SizedBox(width: 5),
              Text(
                '${trips.length}개',
                style: const TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFFB2B2B2),
                ),
              ),
            ],
          ),
        ),
        // 폴더가 많아 시트 최대 높이를 넘으면 목록만 스크롤 (오버플로우 방지)
        Flexible(
          child: ListView(
            shrinkWrap: true, // 폴더가 적으면 내용 높이만큼만 차지
            padding: EdgeInsets.zero,
            children: [
              for (int i = 0; i < trips.length; i++) ...[
                if (i > 0) const SizedBox(height: 5),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      onSelected(trips[i].id);
                    },
                    child: Container(
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: trips[i].id == currentTripId
                            ? Border.all(color: const Color(0xFFFE8505))
                            : null,
                        borderRadius: BorderRadius.circular(17),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0D000000),
                            blurRadius: 5,
                            offset: Offset(0, 4),
                          ),
                          BoxShadow(
                            color: Color(0x0D000000),
                            blurRadius: 5,
                            offset: Offset(4, 0),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(15),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: tripCoverColor(trips[i]),
                              borderRadius: BorderRadius.circular(17),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  trips[i].title,
                                  style: const TextStyle(
                                    fontFamily: 'Pretendard',
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF070707),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  tripDateRange(trips[i]),
                                  style: const TextStyle(
                                    fontFamily: 'Pretendard',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFFB2B2B2),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
