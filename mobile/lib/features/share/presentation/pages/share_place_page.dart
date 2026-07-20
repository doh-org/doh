import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/update_error_dialog.dart';
import '../../../map/data/datasources/place_search_datasource.dart';
import '../../../map/domain/entities/place.dart';
import '../../../map/presentation/widgets/place_add_sheet.dart';
import '../../../map/presentation/widgets/trip_selector_sheet.dart'
    show tripCoverColor, tripDateRange;
import '../../../markers/domain/entities/marker.dart';
import '../../../trips/domain/entities/trip.dart';
import '../../../trips/presentation/providers/trip_provider.dart';
import '../../data/share_intent_provider.dart';

/// 다른 앱에서 "공유"로 넘어온 장소를 어느 여행에 담을지 고르는 화면.
///
/// 흐름: 여행 선택 → 장소명 검색(/places/search) → 첫 결과로 PlaceAddSheet →
/// 저장되면 대기 공유를 비우고 그 여행 지도로 이동.
class SharePlacePage extends ConsumerStatefulWidget {
  const SharePlacePage({super.key});

  @override
  ConsumerState<SharePlacePage> createState() => _SharePlacePageState();
}

class _SharePlacePageState extends ConsumerState<SharePlacePage> {
  bool _resolving = false;

  @override
  void initState() {
    super.initState();
    // 대기 공유가 없는데 직접 진입한 경우 → 목록으로 되돌린다
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(pendingSharedPlaceProvider) == null && mounted) {
        context.go('/trips');
      }
    });
  }

  @override
  void dispose() {
    // 저장 없이 나가도 대기 공유가 남지 않도록 비운다
    ref.read(pendingSharedPlaceProvider.notifier).consume();
    super.dispose();
  }

  // 여행 기간(시작~종료) → Day 수. 날짜 미설정이면 0(미정만).
  int _dayCount(Trip t) {
    if (t.startDate == null || t.endDate == null) return 0;
    return t.endDate!.difference(t.startDate!).inDays + 1;
  }

  Future<void> _onTripPicked(Trip trip) async {
    final String? name = ref.read(pendingSharedPlaceProvider);
    if (name == null || _resolving) return;

    setState(() => _resolving = true);
    List<Place> results;
    try {
      results = await ref.read(placeSearchDatasourceProvider).search(name);
    } catch (_) {
      if (mounted) showUpdateErrorDialog(context, '장소 검색에 실패했습니다.');
      return;
    } finally {
      if (mounted) setState(() => _resolving = false);
    }

    if (results.isEmpty) {
      if (mounted) showUpdateErrorDialog(context, "'$name' 장소를 찾지 못했습니다.");
      return;
    }
    if (!mounted) return;

    final Place place = results.first;
    final bool? saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PlaceAddSheet(
        tripId: trip.id,
        latitude: place.latitude,
        longitude: place.longitude,
        dayCount: _dayCount(trip),
        place: place,
        source: MarkerSource.share,
      ),
    );

    if (saved == true && mounted) {
      ref.read(pendingSharedPlaceProvider.notifier).consume();
      context.go('/trips/${trip.id}/map');
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? name = ref.watch(pendingSharedPlaceProvider);
    final AsyncValue<List<Trip>> tripsAsync = ref.watch(tripsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF070707),
        title: const Text(
          '여행 선택',
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF070707),
          ),
        ),
      ),
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Text(
                  "'${name ?? ''}'을(를) 담을 여행을 선택하세요.",
                  style: const TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFB2B2B2),
                  ),
                ),
              ),
              Expanded(
                child: tripsAsync.when(
                  data: (trips) => trips.isEmpty
                      ? const _EmptyTrips()
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(15, 0, 15, 20),
                          itemCount: trips.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 5),
                          itemBuilder: (_, i) => _TripTile(
                            trip: trips[i],
                            onTap: () => _onTripPicked(trips[i]),
                          ),
                        ),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const Center(
                    child: Text(
                      '여행 목록을 불러오지 못했습니다.',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 14,
                        color: Color(0xFFB2B2B2),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_resolving)
            const ColoredBox(
              color: Color(0x33000000),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}

class _EmptyTrips extends StatelessWidget {
  const _EmptyTrips();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        '먼저 여행을 만들어주세요.',
        style: TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 14,
          color: Color(0xFFB2B2B2),
        ),
      ),
    );
  }
}

// TripSelectorSheet 카드와 동일한 표기(색상·기간 헬퍼 재사용).
class _TripTile extends StatelessWidget {
  const _TripTile({required this.trip, required this.onTap});
  final Trip trip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: Colors.white,
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
                color: tripCoverColor(trip),
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
                    trip.title,
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
                    tripDateRange(trip),
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
    );
  }
}
