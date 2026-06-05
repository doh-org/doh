import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../markers/domain/entities/category.dart';
import '../../../markers/domain/entities/marker.dart';
import '../../../markers/data/repositories/marker_repository_impl.dart';
import '../../../markers/presentation/providers/marker_provider.dart';
import '../../../trips/domain/entities/trip.dart';
import '../../domain/entities/naver_place.dart';
import '../../../trips/presentation/providers/trip_provider.dart';
import '../widgets/day_filter_bar.dart';
import '../widgets/map_view.dart';
import '../widgets/marker_detail_sheet.dart';
import '../widgets/place_add_sheet.dart';
import '../widgets/place_card.dart';
import 'search_page.dart';

class MapPage extends ConsumerStatefulWidget {
  const MapPage({required this.tripId, super.key});
  final String tripId;

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage> {
  late String _tripId;
  int _selectedDay = 0;
  String? _selectedMarkerId;
  NLatLng? _focusTarget;
  NLatLng? _pendingLocation;
  final Set<String> _likedMarkerIds = {};
  final _sheetController = DraggableScrollableController();

  static const _sheetInitial = 0.45;
  static const _sheetMin = 0.13;
  static const _sheetMax = 0.88;

  @override
  void initState() {
    super.initState();
    _tripId = widget.tripId;
  }

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
  }

  List<TripMarker> _filterByDay(List<TripMarker> markers, int day) {
    if (day == 0) return markers.where((m) => m.visitDays.isEmpty).toList();
    return markers.where((m) => m.visitDays.contains(day)).toList();
  }

  int _dayCount(Trip? trip) {
    if (trip?.startDate == null || trip?.endDate == null) return 0;
    return trip!.endDate!.difference(trip.startDate!).inDays + 1;
  }

  void _showTripSelector(List<Trip> trips) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _TripSelectorSheet(
        trips: trips,
        currentTripId: _tripId,
        onSelected: (id) {
          setState(() {
            _tripId = id;
            _selectedDay = 0;
          });
        },
      ),
    );
  }

  Future<void> _showDetailSheet(
      TripMarker marker, List<TripMarker> allMarkers) async {
    setState(() {
      _selectedMarkerId = marker.id;
      _focusTarget = NLatLng(marker.latitude, marker.longitude);
    });
    if (_sheetController.isAttached) {
      _sheetController.animateTo(
        _sheetMin,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (_, scroll) => MarkerDetailSheet(
          marker: marker,
          tripId: _tripId,
          allMarkers: allMarkers,
          isLiked: _likedMarkerIds.contains(marker.id),
        ),
      ),
    );
    if (mounted && _sheetController.isAttached) {
      _sheetController.animateTo(
        _sheetInitial,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _showAddSheetFromSearch(NaverPlace place, Trip? trip) async {
    final NLatLng coord = NLatLng(place.latitude, place.longitude);
    setState(() {
      _focusTarget = coord;
      _pendingLocation = coord;
    });
    if (_sheetController.isAttached) {
      _sheetController.animateTo(
        _sheetMin,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PlaceAddSheet(
        tripId: _tripId,
        latitude: place.latitude,
        longitude: place.longitude,
        dayCount: _dayCount(trip),
        naverPlace: place,
        source: MarkerSource.search,
      ),
    );
    if (mounted) {
      ref.invalidate(markerEntitiesProvider(_tripId));
      setState(() => _pendingLocation = null);
      if (_sheetController.isAttached) {
        _sheetController.animateTo(
          _sheetInitial,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    }
  }

  Future<void> _showAddSheet(NLatLng coord, Trip? trip) async {
    // 목록 탭을 최소 크기로 내림
    if (_sheetController.isAttached) {
      _sheetController.animateTo(
        _sheetMin,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PlaceAddSheet(
        tripId: _tripId,
        latitude: coord.latitude,
        longitude: coord.longitude,
        dayCount: _dayCount(trip),
        source: MarkerSource.longpress,
      ),
    );
    // 닫히면 목록 탭 원래 크기로 복원
    if (mounted) {
      ref.invalidate(markerEntitiesProvider(_tripId));
      if (_sheetController.isAttached) {
        _sheetController.animateTo(
          _sheetInitial,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    }
  }

  Future<void> _confirmDelete(TripMarker m) async {
    final ok = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '닫기',
      barrierColor: Colors.black26,
      pageBuilder: (ctx, _, __) => Align(
        alignment: const Alignment(0, 0.5),
        child: _DeleteDialog(name: m.name),
      ),
    );
    if (ok == true) {
      await ref.read(markerRepositoryProvider).deleteMarker(m.tripId, m.id);
      ref.invalidate(markerEntitiesProvider(_tripId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final markersAsync = ref.watch(markerEntitiesProvider(_tripId));
    final categoriesAsync = ref.watch(categoriesProvider(_tripId));
    final tripAsync = ref.watch(tripDetailNotifierProvider(_tripId));
    final tripsAsync = ref.watch(tripsProvider);

    final trip = tripAsync.valueOrNull;
    final categories = categoriesAsync.valueOrNull ?? [];
    final categoryMap = {for (final c in categories) c.id: c};
    final allMarkers = markersAsync.valueOrNull ?? [];
    final filteredMarkers = _filterByDay(allMarkers, _selectedDay);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: Stack(
        children: [
          // 지도
          Positioned.fill(
            child: MapView(
              initialLocation: const NLatLng(37.5665, 126.9780),
              tripId: _tripId,
              onMarkerTap: (m) => _showDetailSheet(m, allMarkers),
              onLongTap: (coord) => _showAddSheet(coord, trip),
              bottomPeekFraction: _sheetInitial,
              selectedMarkerId: _selectedMarkerId,
              focusTarget: _focusTarget,
              pendingLocation: _pendingLocation,
            ),
            ),

            // 뒤로가기 / 더보기
            SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_horiz, size: 24),
                    onPressed: () {},
                  ),
                ],
              ),
            ),

            // 검색바 (탭 → SearchPage)
            SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.only(top: 52, left: 15, right: 15),
                child: GestureDetector(
                  onTap: () async {
                    final Object? result = await Navigator.push<Object?>(
                      context,
                      MaterialPageRoute<Object?>(
                        builder: (_) =>
                            SearchPage(tripId: _tripId, trip: trip),
                      ),
                    );
                    if (!mounted) return;
                    if (result is TripMarker) {
                      final List<TripMarker> latest = ref
                              .read(markerEntitiesProvider(_tripId))
                              .valueOrNull ??
                          [];
                      _showDetailSheet(result, latest);
                    } else if (result is NaverPlace) {
                      await _showAddSheetFromSearch(result, trip);
                    }
                  },
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x1A000000),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20),
                    child: const Row(
                      children: [
                        Icon(Icons.search,
                            color: Color(0xFF8A847B), size: 20),
                        SizedBox(width: 8),
                        Text(
                          '지하철역, 카페, 식당 ....',
                          style: TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFFB2B2B2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // 폴더 칩 (Trip 선택)
            SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.only(top: 112, left: 20),
                child: GestureDetector(
                  onTap: () => _showTripSelector(
                      tripsAsync.valueOrNull ?? []),
                  child: Container(
                    height: 30,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x1A000000),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.folder_outlined,
                            size: 20, color: Color(0xFFFE8505)),
                        const SizedBox(width: 3),
                        ConstrainedBox(
                          constraints:
                              const BoxConstraints(maxWidth: 100),
                          child: Text(
                            trip?.title ?? '여행 선택',
                            style: const TextStyle(
                              fontFamily: 'Pretendard',
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF1F2125),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 3),
                        const Icon(Icons.keyboard_arrow_down,
                            size: 15, color: Color(0xFF1F2125)),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // 바텀 시트
            DraggableScrollableSheet(
              controller: _sheetController,
              initialChildSize: _sheetInitial,
              minChildSize: _sheetMin,
              maxChildSize: _sheetMax,
              snap: true,
              snapSizes: const [_sheetMin, _sheetInitial, _sheetMax],
              builder: (_, scrollCtrl) => _PlaceListSheet(
                scrollController: scrollCtrl,
                placeCount: allMarkers.length,
                tripTitle: trip?.title ?? '',
                dayCount: _dayCount(trip),
                selectedDay: _selectedDay,
                onDaySelected: (d) => setState(() => _selectedDay = d),
                markers: filteredMarkers,
                categoryMap: categoryMap,
                likedIds: _likedMarkerIds,
                hasError: markersAsync.hasError,
                onMarkerTap: (m) => _showDetailSheet(m, allMarkers),
                onLikeTap: (id) =>
                    setState(() => _likedMarkerIds.contains(id)
                        ? _likedMarkerIds.remove(id)
                        : _likedMarkerIds.add(id)),
                onDelete: _confirmDelete,
              ),
            ),
          ],
        ),
    );
  }
}

// ── 바텀 시트 ────────────────────────────────────────────────────────────────
class _PlaceListSheet extends StatelessWidget {
  const _PlaceListSheet({
    required this.scrollController,
    required this.placeCount,
    required this.tripTitle,
    required this.dayCount,
    required this.selectedDay,
    required this.onDaySelected,
    required this.markers,
    required this.categoryMap,
    required this.likedIds,
    required this.hasError,
    required this.onMarkerTap,
    required this.onLikeTap,
    required this.onDelete,
  });

  final ScrollController scrollController;
  final int placeCount;
  final String tripTitle;
  final int dayCount;
  final int selectedDay;
  final ValueChanged<int> onDaySelected;
  final List<TripMarker> markers;
  final Map<String, Category> categoryMap;
  final Set<String> likedIds;
  final bool hasError;
  final void Function(TripMarker) onMarkerTap;
  final void Function(String) onLikeTap;
  final void Function(TripMarker) onDelete;

  Color _categoryColor(Category? cat) {
    if (cat == null) return const Color(0x808A847B);
    try {
      final v = int.parse(cat.color.replaceFirst('#', ''), radix: 16);
      return Color(v).withAlpha(128);
    } catch (_) {
      return const Color(0x808A847B);
    }
  }

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
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.bookmark,
                          size: 22, color: Color(0xFFFE8505)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RichText(
                              text: TextSpan(
                                style:
                                    const TextStyle(fontFamily: 'Pretendard'),
                                children: [
                                  const TextSpan(
                                    text: '저장한 장소 ',
                                    style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF070707)),
                                  ),
                                  TextSpan(
                                    text: '$placeCount',
                                    style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFFFE8505)),
                                  ),
                                  const TextSpan(
                                    text: '곳',
                                    style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF070707)),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              dayCount == 0
                                  ? tripTitle
                                  : dayCount == 1
                                      ? '$tripTitle  |  당일'
                                      : '$tripTitle  |  ${dayCount - 1}박 $dayCount일',
                              style: const TextStyle(
                                fontFamily: 'Pretendard',
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFFB2B2B2),
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          '경로 편집',
                          style: TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF2A6FDB),
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
                            '장소 목록을 불러오지 못했습니다',
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
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFB2B2B2),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '검색 또는 지도를 꾹 눌러 장소를 추가해보세요.',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 12,
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
                itemBuilder: (_, i) {
                  final m = markers[i];
                  final cat =
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
                      isLiked: likedIds.contains(m.id),
                      likeCount: 0,
                      onTap: () => onMarkerTap(m),
                      onLikeTap: () => onLikeTap(m.id),
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

// ── Trip 선택 바텀 시트 ──────────────────────────────────────────────────────
class _TripSelectorSheet extends StatelessWidget {
  const _TripSelectorSheet({
    required this.trips,
    required this.currentTripId,
    required this.onSelected,
  });
  final List<Trip> trips;
  final String currentTripId;
  final void Function(String) onSelected;

  String _formatDate(DateTime? d) {
    if (d == null) return '';
    return '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';
  }

  String _dateRange(Trip t) {
    final s = _formatDate(t.startDate);
    final e = _formatDate(t.endDate);
    if (s.isEmpty && e.isEmpty) return '';
    if (s.isEmpty) return e;
    if (e.isEmpty) return s;
    return '$s ~ $e';
  }

  Color _coverColor(Trip t) {
    if (t.coverColor == null) return const Color(0xFFD5D5D5);
    try {
      return Color(int.parse(t.coverColor!.replaceFirst('#', '0xFF')));
    } catch (_) {
      return const Color(0xFFD5D5D5);
    }
  }

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
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF070707),
                ),
              ),
              const SizedBox(width: 5),
              Text(
                '${trips.length}개',
                style: const TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFFB2B2B2),
                ),
              ),
            ],
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
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
                            color: _coverColor(trips[i]),
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
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF070707),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _dateRange(trips[i]),
                                style: const TextStyle(
                                  fontFamily: 'Pretendard',
                                  fontSize: 12,
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
        const SizedBox(height: 16),
      ],
    );
  }
}

// ── 삭제 확인 다이얼로그 ────────────────────────────────────────────────────────
class _DeleteDialog extends StatelessWidget {
  const _DeleteDialog({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 300,
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(17),
        ),
        child: Column(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.delete_outline, size: 30, color: Color(0xFFEC2113)),
                  const SizedBox(height: 20),
                  const Text(
                    '삭제하시겠습니까?',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF070707),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    name,
                    style: const TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xCCEC2113),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context, false),
                    child: Container(
                      width: 120,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD5D5D5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        '취소',
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF070707),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  GestureDetector(
                    onTap: () => Navigator.pop(context, true),
                    child: Container(
                      width: 120,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xCCEC2113),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        '삭제',
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
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
