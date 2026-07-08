import 'package:flutter/material.dart';

import '../../../markers/domain/entities/category.dart';
import '../../../markers/domain/entities/marker.dart';
import '../../../markers/presentation/utils/category_colors.dart';
import 'day_filter_bar.dart';
import 'place_card.dart';

// 지도 하단 "저장한 장소" 시트. DraggableScrollableSheet 안에서 쓰이며
// scrollController를 공유해 헤더·목록 전체가 시트 드래그에 반응한다.
class PlaceListSheet extends StatelessWidget {
  const PlaceListSheet({
    required this.scrollController,
    required this.placeCount,
    required this.tripTitle,
    required this.dayCount,
    required this.selectedDay,
    required this.onDaySelected,
    required this.markers,
    required this.categoryMap,
    // v0 제외: 마커 좋아요(찜) 기능 — 추후 복구
    // required this.likedIds,
    required this.hasError,
    required this.canEditRoute,
    required this.onEditRoute,
    required this.onMarkerTap,
    // required this.onLikeTap,
    required this.onDelete,
    super.key,
  });

  final ScrollController scrollController;
  final int placeCount;
  final String tripTitle;
  final int dayCount;
  final int selectedDay;
  final ValueChanged<int> onDaySelected;
  final List<TripMarker> markers;
  final Map<String, Category> categoryMap;
  // v0 제외: 마커 좋아요(찜) 기능 — 추후 복구
  // final Set<String> likedIds;
  final bool hasError;
  final bool canEditRoute;
  final VoidCallback onEditRoute;
  final void Function(TripMarker) onMarkerTap;
  // final void Function(String) onLikeTap;
  final void Function(TripMarker) onDelete;

  Color _categoryColor(Category? cat) => categoryChipColor(cat?.name);

  IconData _categoryIcon(String? name) => switch (name) {
        '카페' => Icons.coffee,
        '식당' => Icons.restaurant,
        '관광' => Icons.photo_camera_outlined,
        '숙소' => Icons.hotel_outlined,
        _ => Icons.place_outlined,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(50)),
        boxShadow: [
          BoxShadow(
              color: Color(0x1A000000), blurRadius: 10, offset: Offset(4, 0)),
        ],
      ),
      // CustomScrollView: scrollController를 공유해 헤더/핸들/목록 전체가
      // DraggableScrollableSheet 드래그에 반응
      child: CustomScrollView(
        controller: scrollController,
        slivers: [
          // ── 드래그 핸들 + 헤더 + Day 필터 ──
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 드래그 핸들
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 9),
                    width: 82,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFECEBE7),
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // 헤더
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 제목 줄: 경로편집탭과 동일하게 아이콘·제목·버튼 중앙 정렬
                      Row(
                        children: [
                          const Icon(Icons.bookmark,
                              size: 22, color: Color(0xFFFE8505)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style:
                                    const TextStyle(fontFamily: 'Pretendard'),
                                children: [
                                  const TextSpan(
                                    text: '저장한 장소 ',
                                    style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF070707)),
                                  ),
                                  TextSpan(
                                    text: '$placeCount',
                                    style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFFFE8505)),
                                  ),
                                  const TextSpan(
                                    text: '곳',
                                    style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF070707)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (canEditRoute)
                            TextButton(
                              onPressed: onEditRoute,
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                '경로 편집',
                                style: TextStyle(
                                  fontFamily: 'Pretendard',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF2A6FDB),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // 부제(여행일)는 제목 텍스트 아래에 동일 들여쓰기 유지
                      Padding(
                        padding: const EdgeInsets.only(left: 28),
                        child: Text(
                          dayCount == 0
                              ? tripTitle
                              : dayCount == 1
                                  ? '$tripTitle  |  당일'
                                  : '$tripTitle  |  ${dayCount - 1}박 $dayCount일',
                          style: const TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFFB2B2B2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),

                // Day 필터
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 14),
                  child: DayFilterBar(
                    selectedDay: selectedDay,
                    dayCount: dayCount,
                    onDaySelected: onDaySelected,
                  ),
                ),
              ],
            ),
          ),

          // ── 에러 배너 ──
          if (hasError)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 0),
                // 높이 고정 금지: 시스템 글꼴 배율이 커지면 텍스트가 커져
                // 고정 50에 안 들어가 오버플로우 남 → 내용이 높이를 결정
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0x80FEC181),
                    borderRadius: BorderRadius.circular(17),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline,
                          size: 20, color: Color(0xFFFE8505)),
                      const SizedBox(width: 10),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '장소 목록을 불러오지 못했습니다',
                            style: TextStyle(
                              fontFamily: 'Pretendard',
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF1F2125),
                              height: 1.2,
                            ),
                          ),
                          RichText(
                            text: const TextSpan(
                              style: TextStyle(
                                fontFamily: 'Pretendard',
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                height: 1.2,
                              ),
                              children: [
                                TextSpan(
                                  text: '잠시 후 ',
                                  style: TextStyle(color: Color(0xFF1F2125)),
                                ),
                                TextSpan(
                                  text: '다시 시도',
                                  style: TextStyle(color: Color(0xFFFE8505)),
                                ),
                                TextSpan(
                                  text: '해보세요.',
                                  style: TextStyle(color: Color(0xFF1F2125)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ── 장소 목록 ──
          if (markers.isEmpty && !hasError)
            const SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '저장된 장소가 없습니다',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFB2B2B2),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '검색 또는 지도를 꾹 눌러 장소를 추가해보세요.',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 13,
                        color: Color(0xFFFE8505),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (!hasError)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              sliver: SliverList.separated(
                itemCount: markers.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, int i) {
                  final TripMarker m = markers[i];
                  final Category? cat =
                      m.categoryId != null ? categoryMap[m.categoryId] : null;
                  return Dismissible(
                    key: ValueKey(m.id),
                    direction: DismissDirection.endToStart,
                    confirmDismiss: (_) async {
                      onDelete(m);
                      return false;
                    },
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEC2113),
                        borderRadius: BorderRadius.circular(17),
                      ),
                      child: const Icon(Icons.delete,
                          color: Colors.white, size: 24),
                    ),
                    child: PlaceCard(
                      name: m.name,
                      address: m.address,
                      category: cat?.name ?? '기타',
                      categoryColor: _categoryColor(cat),
                      categoryIcon: _categoryIcon(cat?.name),
                      // v0 제외: 마커 좋아요(찜) 기능 — 추후 복구
                      // isLiked: likedIds.contains(m.id),
                      // likeCount: 0,
                      onTap: () => onMarkerTap(m),
                      // onLikeTap: () => onLikeTap(m.id),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
