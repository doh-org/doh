import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../markers/domain/entities/category.dart';
import '../../../markers/domain/entities/marker.dart';
import '../../../markers/presentation/pages/marker_detail_page.dart';
import '../../../markers/presentation/providers/marker_provider.dart';
import '../../../markers/presentation/widgets/marker_bottom_sheet.dart';
import '../../../trips/domain/entities/trip.dart';
import '../../../trips/presentation/providers/trip_provider.dart';
import '../providers/map_provider.dart';
import '../widgets/day_filter_bar.dart';
import '../widgets/map_view.dart';
import '../widgets/place_card.dart';
import 'search_page.dart';

class MapPage extends ConsumerStatefulWidget {
  const MapPage({required this.tripId, super.key});
  final String tripId;

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage> {
  int _selectedDay = 0;
  late String _selectedTripId;

  @override
  void initState() {
    super.initState();
    _selectedTripId = widget.tripId;
  }

  List<TripMarker> _filterByDay(
    List<TripMarker> markers,
    DateTime? startDate,
    int day,
  ) {
    if (day == 0 || startDate == null) return markers;
    return markers.where((m) {
      if (m.visitTime == null) return false;
      final d = m.visitTime!.difference(startDate).inDays + 1;
      return d == day;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final locationAsync = ref.watch(currentLocationProvider);
    final entityMarkersAsync = ref.watch(markerEntitiesProvider(_selectedTripId));
    final categoriesAsync = ref.watch(categoriesProvider(_selectedTripId));
    final tripAsync = ref.watch(tripDetailNotifierProvider(_selectedTripId));

    final trip = tripAsync.valueOrNull;
    final categories = categoriesAsync.valueOrNull ?? [];
    final categoryMap = {for (final c in categories) c.id: c};

    final allMarkers = entityMarkersAsync.valueOrNull ?? [];
    final dayCount = (trip?.startDate != null && trip?.endDate != null)
        ? trip!.endDate!.difference(trip.startDate!).inDays + 1
        : 0;
    final filteredMarkers =
        _filterByDay(allMarkers, trip?.startDate, _selectedDay);

    const defaultLat = 37.5665;
    const defaultLng = 126.9780;
    final location =
        locationAsync.valueOrNull ?? (lat: defaultLat, lng: defaultLng);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: Stack(
        children: [
          // ── 지도 ──────────────────────────────────────
          Positioned.fill(
            child: MapView(
              initialLat: location.lat,
              initialLng: location.lng,
              markers: allMarkers,
              tripId: _selectedTripId,
              onLongTap: (lat, lng) {
                showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => MarkerBottomSheet(
                    tripId: _selectedTripId,
                    latitude: lat,
                    longitude: lng,
                  ),
                );
              },
            ),
          ),

          // ── 상단 버튼 (뒤로 / 옵션) ──────────────────
          SafeArea(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, size: 22),
                  onPressed: () => Navigator.pop(context),
                ),
                IconButton(
                  icon: const Icon(Icons.more_horiz, size: 24),
                  onPressed: () {},
                ),
              ],
            ),
          ),

          // ── 검색바 ────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 52, left: 16, right: 16),
              child: _SearchBar(
                onTap: () {
                  Navigator.push<void>(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => SearchPage(tripId: _selectedTripId),
                    ),
                  );
                },
              ),
            ),
          ),

          // ── 여행 폴더 선택 pill ───────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 112, left: 16),
              child: _TripSelectorPill(
                title: trip?.title ?? '여행 선택',
                onTap: () async {
                  final selected = await showModalBottomSheet<Trip>(
                    context: context,
                    builder: (_) => const _TripSelectorSheet(),
                  );
                  if (selected != null) {
                    setState(() {
                      _selectedTripId = selected.id;
                      _selectedDay = 0;
                    });
                  }
                },
              ),
            ),
          ),

          // ── 현위치 FAB ────────────────────────────────
          Positioned(
            right: 16,
            bottom: MediaQuery.of(context).size.height * 0.45 + 16,
            child: FloatingActionButton.small(
              backgroundColor: Colors.white,
              elevation: 4,
              onPressed: () async {
                final loc = ref.read(currentLocationProvider).valueOrNull;
                if (loc == null) return;
                await ref
                    .read(mapControllerProvider.notifier)
                    .moveCamera(loc.lat, loc.lng);
              },
              child: const Icon(
                Icons.my_location,
                color: Color(0xFFFE8505),
              ),
            ),
          ),

          // ── 바텀 시트 ────────────────────────────────
          DraggableScrollableSheet(
            initialChildSize: 0.45,
            minChildSize: 0.45,
            maxChildSize: 0.88,
            builder: (_, scrollController) => _PlaceListSheet(
              scrollController: scrollController,
              placeCount: allMarkers.length,
              tripTitle: trip?.title ?? '',
              dayCount: dayCount,
              selectedDay: _selectedDay,
              onDaySelected: (d) => setState(() => _selectedDay = d),
              markers: filteredMarkers,
              categoryMap: categoryMap,
              onMarkerTap: (m) async {
                final deleted = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute<bool>(
                    builder: (_) => MarkerDetailPage(marker: m),
                  ),
                );
                if (deleted == true) {
                  ref.invalidate(markerEntitiesProvider(_selectedTripId));
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── 검색바 ─────────────────────────────────────────────────────────────────
class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: const Row(
          children: [
            Icon(Icons.search, color: Color(0xFF8A847B), size: 20),
            SizedBox(width: 8),
            Text(
              '지하철역, 카페, 식당 ....',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF8A847B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 여행 폴더 선택 pill ─────────────────────────────────────────────────────
class _TripSelectorPill extends StatelessWidget {
  const _TripSelectorPill({required this.title, required this.onTap});
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
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
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 160),
              child: Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1F2125),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down,
                size: 16, color: Color(0xFF1F2125)),
          ],
        ),
      ),
    );
  }
}

// ── 여행 선택 시트 ──────────────────────────────────────────────────────────
class _TripSelectorSheet extends ConsumerWidget {
  const _TripSelectorSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripsAsync = ref.watch(tripsProvider);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Text(
              '여행 선택',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF070707),
              ),
            ),
          ),
          tripsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(24),
              child: Text('오류: $e'),
            ),
            data: (trips) => ListView.builder(
              shrinkWrap: true,
              itemCount: trips.length,
              itemBuilder: (context, i) {
                final t = trips[i];
                return ListTile(
                  leading: const Icon(
                    Icons.folder_outlined,
                    color: Color(0xFFFE8505),
                  ),
                  title: Text(
                    t.title,
                    style: const TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: t.description != null
                      ? Text(
                          t.description!,
                          style: const TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 12,
                            color: Color(0xFFB2B2B2),
                          ),
                        )
                      : null,
                  onTap: () => Navigator.pop(context, t),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── 바텀 시트 내용 ──────────────────────────────────────────────────────────
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
    this.onMarkerTap,
  });

  final ScrollController scrollController;
  final int placeCount;
  final String tripTitle;
  final int dayCount;
  final int selectedDay;
  final ValueChanged<int> onDaySelected;
  final List<TripMarker> markers;
  final Map<String, Category> categoryMap;
  final void Function(TripMarker marker)? onMarkerTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(50)),
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 10,
            offset: Offset(4, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 드래그 핸들
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 16),
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFECEBE7),
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
            ),
          ),

          // 헤더
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '저장한 장소 $placeCount곳',
                        style: const TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF070707),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tripTitle,
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
                    '자세히 →',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFEC2113),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Day 필터
          DayFilterBar(
            selectedDay: selectedDay,
            dayCount: dayCount,
            onDaySelected: onDaySelected,
          ),

          const SizedBox(height: 12),

          // 장소 리스트
          Expanded(
            child: markers.isEmpty
                ? const Center(
                    child: Text(
                      '저장된 장소가 없습니다',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 14,
                        color: Color(0xFFB2B2B2),
                      ),
                    ),
                  )
                : ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                    itemCount: markers.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) {
                      final m = markers[i];
                      final cat = m.categoryId != null
                          ? categoryMap[m.categoryId]
                          : null;
                      return PlaceCard(
                        name: m.name,
                        address: m.address,
                        category: cat?.name ?? '기타',
                        categoryColor: _parseCategoryColor(cat?.color),
                        categoryIcon: _categoryIcon(cat?.name),
                        likeCount: 0,
                        onTap: () => onMarkerTap?.call(m),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Color _parseCategoryColor(String? hex) {
    if (hex == null) return const Color(0x8095A5A6);
    try {
      final val = int.parse(hex.replaceFirst('#', ''), radix: 16);
      return Color(val).withAlpha(128);
    } catch (_) {
      return const Color(0x8095A5A6);
    }
  }

  IconData _categoryIcon(String? name) => switch (name) {
        '카페' => Icons.coffee,
        '음식' || '식당' => Icons.restaurant,
        '관광' => Icons.photo_camera_outlined,
        '숙소' => Icons.hotel_outlined,
        _ => Icons.place_outlined,
      };
}
