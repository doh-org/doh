import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../markers/domain/entities/category.dart';
import '../../../markers/domain/entities/marker.dart';
import '../../../markers/presentation/providers/marker_provider.dart';
import '../../../trips/domain/entities/trip.dart';
import '../../domain/entities/naver_place.dart';
import '../providers/search_provider.dart';

// naver 카테고리 경로 → DB 카테고리명
String _naverToDbCategory(String path) {
  final String c = path.toLowerCase();
  if (c.contains('카페') || c.contains('디저트')) return '카페';
  if (c.contains('숙박') || c.contains('호텔') || c.contains('펜션')) return '숙소';
  if (c.contains('관광')) return '관광';
  if (c.contains('음식점') || c.contains('식당')) return '식당';
  return '기타';
}

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({
    required this.tripId,
    required this.trip,
    this.center,
    this.initialQuery,
    super.key,
  });
  final String tripId;
  final Trip? trip;
  final NLatLng? center;
  final String? initialQuery;

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _ctrl = TextEditingController();
  String _query = '';
  bool _localExpanded = false;

  @override
  void initState() {
    super.initState();
    final String? q = widget.initialQuery;
    if (q != null && q.isNotEmpty) {
      _ctrl.text = q;
      _query = q;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _onQueryChanged(q);
      });
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onQueryChanged(String v) {
    setState(() {
      _query = v;
      _localExpanded = false;
    });
    if (v.trim().isNotEmpty) {
      final NLatLng? c = widget.center;
      final String? coordinate = c != null ? '${c.longitude},${c.latitude}' : null;
      ref.read(naverSearchNotifierProvider.notifier).search(v.trim(), coordinate: coordinate);
    } else {
      ref.read(naverSearchNotifierProvider.notifier).clear();
    }
  }

  List<TripMarker> _filterLocal(List<TripMarker> all) {
    if (_query.trim().isEmpty) return [];
    final q = _query.toLowerCase();
    return all
        .where((m) =>
            m.name.toLowerCase().contains(q) ||
            (m.address?.toLowerCase().contains(q) ?? false))
        .toList();
  }

  // DB 카테고리명 → 색상
  Color _categoryColor(String name) => switch (name) {
        '카페' => const Color(0x80FFB347),
        '숙소' => const Color(0x805DADE2),
        '관광' => const Color(0x804ECDC4),
        '식당' => const Color(0x80FF6B6B),
        _ => const Color(0x8095A5A6),
      };

  // DB 카테고리명 → 아이콘
  IconData _categoryIcon(String name) => switch (name) {
        '카페' => Icons.coffee,
        '숙소' => Icons.hotel_outlined,
        '관광' => Icons.photo_camera_outlined,
        '식당' => Icons.restaurant,
        _ => Icons.place_outlined,
      };

  void _selectLocalMarker(TripMarker marker) {
    Navigator.pop(context, marker);
  }


  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<TripMarker>> markersAsync = ref.watch(markerEntitiesProvider(widget.tripId));
    final AsyncValue<List<NaverPlace>> naverAsync = ref.watch(naverSearchNotifierProvider);
    final Map<String, Category> categoryMap = {
      for (final Category c in ref.watch(categoriesProvider(widget.tripId)).valueOrNull ?? [])
        c.id: c
    };
    final List<TripMarker> localAll = markersAsync.valueOrNull ?? [];
    final List<TripMarker> localFiltered = _filterLocal(localAll);
    final List<NaverPlace> naverResults = naverAsync.valueOrNull ?? [];
    final List<TripMarker> localShown =
        _localExpanded ? localFiltered : localFiltered.take(5).toList();
    final int totalCount = localFiltered.length + naverResults.length;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── 헤더 ─────────────────────────────────────────
            SizedBox(
              height: 52,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      '장소 검색',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F1D1A),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // ── 검색바 ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: _SearchBar(
                controller: _ctrl,
                onChanged: _onQueryChanged,
                onClear: () {
                  _ctrl.clear();
                  _onQueryChanged('');
                },
              ),
            ),
            const SizedBox(height: 10),

            // ── 본문 ──────────────────────────────────────────
            Expanded(
              child: _query.trim().isEmpty
                  ? Align(
                      alignment: Alignment.topLeft,
                      child: _EmptyState(),
                    )
                  : _ResultList(
                      localShown: localShown,
                      localTotal: localFiltered.length,
                      localExpanded: _localExpanded,
                      naverResults: naverResults,
                      naverLoading: naverAsync.isLoading,
                      totalCount: totalCount,
                      categoryMap: categoryMap,
                      categoryColor: _categoryColor,
                      categoryIcon: _categoryIcon,
                      onLocalTap: _selectLocalMarker,
                      onNaverTap: (p) => Navigator.pop(context, p),
                      onExpand: () =>
                          setState(() => _localExpanded = true),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 검색바 ──────────────────────────────────────────────────────────────────
class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: const [
          BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 2,
              offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              autofocus: true,
              cursorColor: const Color(0xFFFE8505),
              onChanged: onChanged,
              style: const TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1F2125),
              ),
              decoration: const InputDecoration(
                hintText: '지하철역, 카페, 식당 ....',
                hintStyle: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 14,
                  color: Color(0xFFB2B2B2),
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.fromLTRB(20, 15, 10, 15),
                isDense: true,
              ),
            ),
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (_, val, __) => val.text.isEmpty
                ? const SizedBox(width: 20)
                : GestureDetector(
                    onTap: onClear,
                    child: const Padding(
                      padding: EdgeInsets.only(right: 16),
                      child: Icon(Icons.close,
                          size: 20, color: Color(0xFF8A847B)),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── 빈 상태 ──────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 0),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: const Color(0x80FEC181),
          borderRadius: BorderRadius.circular(17),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
        child: Row(
          children: [
            const Icon(Icons.info_outline, size: 20, color: Color(0xFFFE8505)),
            const SizedBox(width: 10),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '지도와',
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1F2125),
                    height: 1.2,
                  ),
                ),
                RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      height: 1.2,
                    ),
                    children: [
                      TextSpan(
                        text: '내가 저장한 장소',
                        style: TextStyle(color: Color(0xFFFE8505)),
                      ),
                      TextSpan(
                        text: '를 한 번에 검색해요.',
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
    );
  }
}

// ── 결과 목록 ────────────────────────────────────────────────────────────────
class _ResultList extends StatelessWidget {
  const _ResultList({
    required this.localShown,
    required this.localTotal,
    required this.localExpanded,
    required this.naverResults,
    required this.naverLoading,
    required this.totalCount,
    required this.categoryMap,
    required this.categoryColor,
    required this.categoryIcon,
    required this.onLocalTap,
    required this.onNaverTap,
    required this.onExpand,
  });

  final List<TripMarker> localShown;
  final int localTotal;
  final bool localExpanded;
  final List<NaverPlace> naverResults;
  final bool naverLoading;
  final int totalCount;
  final Map<String, Category> categoryMap;
  final Color Function(String) categoryColor;
  final IconData Function(String) categoryIcon;
  final void Function(TripMarker) onLocalTap;
  final void Function(NaverPlace) onNaverTap;
  final VoidCallback onExpand;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // 결과 헤더
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
            child: Row(
              children: [
                const Icon(Icons.bookmark,
                    size: 18, color: Color(0xFFFE8505)),
                const SizedBox(width: 5),
                const Text(
                  '검색 결과',
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1F2125),
                  ),
                ),
                const SizedBox(width: 5),
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: const Color(0xFFECEBE7),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$totalCount',
                    style: const TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF7E7E7E),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // 로컬 마커 목록
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (_, i) => _LocalItem(
              marker: localShown[i],
              categoryMap: categoryMap,
              categoryColor: categoryColor,
              categoryIcon: categoryIcon,
              onTap: () => onLocalTap(localShown[i]),
            ),
            childCount: localShown.length,
          ),
        ),

        // 더보기 버튼
        if (!localExpanded && localTotal > 5)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: GestureDetector(
                onTap: onExpand,
                child: Row(
                  children: [
                    Text(
                      '저장된 장소 ${localTotal - 5}개 더보기',
                      style: const TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFFFE8505),
                      ),
                    ),
                    const Icon(Icons.add,
                        size: 14, color: Color(0xFFFE8505)),
                  ],
                ),
              ),
            ),
          ),

        // 네이버 검색 결과 (+ 버튼 없음, 탭 → PlaceAddSheet)
        if (naverLoading)
          const SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(color: Color(0xFFFE8505)),
              ),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) => _NaverItem(
                place: naverResults[i],
                categoryColor: categoryColor,
                categoryIcon: categoryIcon,
                onTap: () => onNaverTap(naverResults[i]),
              ),
              childCount: naverResults.length,
            ),
          ),

        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}

// ── 로컬 마커 아이템 ─────────────────────────────────────────────────────────
class _LocalItem extends StatelessWidget {
  const _LocalItem({
    required this.marker,
    required this.categoryMap,
    required this.categoryColor,
    required this.categoryIcon,
    required this.onTap,
  });
  final TripMarker marker;
  final Map<String, Category> categoryMap;
  final Color Function(String) categoryColor;
  final IconData Function(String) categoryIcon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final String catName = categoryMap[marker.categoryId]?.name ?? '기타';
    final Color color = categoryColor(catName);
    final IconData icon = categoryIcon(catName);

    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            children: [
              // 카테고리 원 (size-40)
              _CategoryCircle(color: color, icon: icon),
              const SizedBox(width: 10),
              // 텍스트
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          marker.name,
                          style: const TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2125),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          catName,
                          style: const TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 12,
                            color: Color(0xFFB2B2B2),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Text(
                          '저장됨',
                          style: TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFFE8505),
                          ),
                        ),
                        const SizedBox(width: 5),
                        if (marker.address != null)
                          Flexible(
                            child: Text(
                              marker.address!,
                              style: const TextStyle(
                                fontFamily: 'Pretendard',
                                fontSize: 12,
                                color: Color(0xFFB2B2B2),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
        ),
        const Divider(height: 1, indent: 20, endIndent: 20,
            color: Color(0xFFF1F2F4)),
      ],
    );
  }
}

// ── 네이버 장소 아이템 ───────────────────────────────────────────────────────
class _NaverItem extends StatelessWidget {
  const _NaverItem({
    required this.place,
    required this.categoryColor,
    required this.categoryIcon,
    required this.onTap,
  });
  final NaverPlace place;
  final Color Function(String) categoryColor;
  final IconData Function(String) categoryIcon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final String dbCat = _naverToDbCategory(place.categoryPath.isNotEmpty ? place.categoryPath : place.category);
    final Color color = categoryColor(dbCat);
    final IconData icon = categoryIcon(dbCat);

    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                _CategoryCircle(color: color, icon: icon),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            place.title,
                            style: const TextStyle(
                              fontFamily: 'Pretendard',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1F2125),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            place.category,
                            style: const TextStyle(
                              fontFamily: 'Pretendard',
                              fontSize: 12,
                              color: Color(0xFFB2B2B2),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        place.address,
                        style: const TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 12,
                          color: Color(0xFFB2B2B2),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1, indent: 20, endIndent: 20,
            color: Color(0xFFF1F2F4)),
      ],
    );
  }
}

class _CategoryCircle extends StatelessWidget {
  const _CategoryCircle({required this.color, required this.icon});
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Icon(icon, size: 15, color: Colors.white),
    );
  }
}
