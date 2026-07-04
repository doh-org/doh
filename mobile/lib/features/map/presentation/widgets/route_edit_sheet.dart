import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../markers/domain/entities/category.dart';
import '../../../markers/presentation/utils/category_colors.dart';
import '../../../routes/data/repositories/route_repository_impl.dart';
import '../../../routes/domain/entities/route_stop.dart';
import '../../../routes/presentation/providers/route_provider.dart';
import '../../../../shared/widgets/update_error_dialog.dart';
import '../utils/map_navigation.dart';
import 'day_filter_bar.dart';
import 'route_stop_card.dart';
import 'time_picker_modal.dart';

const Color _orange = Color(0xFFFE8505);

/// 경로 편집 모드 바텀 시트. 선택 Day(>=1)의 stop을 페어 카드로 표시하고
/// 이동수단/방문시간 즉시 PATCH, 꾹눌러 드래그 reorder를 지원한다.
class RouteEditSheet extends ConsumerStatefulWidget {
  const RouteEditSheet({
    required this.scrollController,
    required this.tripId,
    required this.selectedDay,
    required this.dayCount,
    required this.placeCount,
    required this.categoryMap,
    required this.onDaySelected,
    required this.onExitEdit,
    super.key,
  });

  final ScrollController scrollController;
  final String tripId;
  final int selectedDay;
  final int dayCount;
  final int placeCount;
  final Map<String, Category> categoryMap;
  final ValueChanged<int> onDaySelected;
  final VoidCallback onExitEdit;

  @override
  ConsumerState<RouteEditSheet> createState() => _RouteEditSheetState();
}

class _RouteEditSheetState extends ConsumerState<RouteEditSheet> {
  String? _selectedMarkerId;

  // 정렬은 항상 order. "시간순 정렬" 버튼이 방문시간 순서를 order로 확정하므로
  // 표시 순서와 서버 order가 일치한다(마지막 stop 판정 불일치 방지).
  RouteSort get _sort => RouteSort.order;

  bool _sorting = false;

  void _invalidate(RouteSort sort) => ref.invalidate(
      dayStopsProvider(widget.tripId, widget.selectedDay, sort));

  void _showError(String msg) {
    if (!mounted) return;
    showUpdateErrorDialog(context, msg);
  }

  Future<void> _selectTransport(RouteStop s, TransportMode m) async {
    final bool clear = s.transportToNext == m; // 같은 값 재선택 = 해제
    setState(() => _selectedMarkerId = null); // 선택 시 접힘
    try {
      await ref.read(routeRepositoryProvider).updateStop(
            widget.tripId,
            widget.selectedDay,
            s.markerId,
            transport: clear ? null : m,
            clearTransport: clear,
          );
    } catch (_) {
      _showError('이동수단 변경에 실패했습니다.');
    }
    _invalidate(_sort);
  }

  // 구간 길안내: origin.transportToNext 기준 외부 지도앱 실행.
  // 차량=티맵, 그 외=네이버지도. 미설치면 웹/설치 모달.
  Future<void> _navigate(RouteStop origin, RouteStop dest) async {
    final TransportMode? mode = origin.transportToNext;
    if (mode == null) return;
    await launchNavigation(
      context: context,
      mode: mode,
      departure:
          NavPoint(name: origin.name, lat: origin.latitude, lng: origin.longitude),
      destination:
          NavPoint(name: dest.name, lat: dest.latitude, lng: dest.longitude),
    );
  }

  Future<void> _editTime(RouteStop s) async {
    final TimeOfDay? picked = await showTimeWheelPicker(
      context,
      initial: _parseTime(s.visitTime) ?? TimeOfDay.now(),
    );
    if (picked == null) return;
    final String hhmm =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    try {
      await ref.read(routeRepositoryProvider).updateStop(
            widget.tripId, widget.selectedDay, s.markerId,
            visitTime: hhmm);
    } catch (_) {
      _showError('방문시간 변경에 실패했습니다.');
    }
    _invalidate(_sort);
  }

  TimeOfDay? _parseTime(String? t) {
    if (t == null || t.length < 5) return null;
    final parts = t.split(':');
    final int? h = int.tryParse(parts[0]);
    final int? m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  Future<void> _onReorder(List<RouteStop> stops, int oldI, int newI) async {
    if (newI > oldI) newI -= 1;
    final ids = stops.map((s) => s.markerId).toList();
    ids.insert(newI, ids.removeAt(oldI));
    try {
      await ref
          .read(routeRepositoryProvider)
          .reorder(widget.tripId, widget.selectedDay, ids);
    } catch (_) {
      _showError('순서 변경에 실패했습니다.');
    }
    _invalidate(RouteSort.order);
  }

  // 현재 Day stop을 방문시간 순으로 정렬·확정(reorder PATCH).
  // 백엔드가 successor 바뀐 구간의 이동수단을 해제한다. 되돌리기는 없다(재정렬은 가능).
  Future<void> _sortByTime() async {
    if (_sorting) return;
    final List<RouteStop>? stops = ref
        .read(dayStopsProvider(widget.tripId, widget.selectedDay, RouteSort.order))
        .valueOrNull;
    if (stops == null || stops.length < 2) return;
    final List<RouteStop> sorted = [...stops]..sort(_byVisitTime);
    final List<String> ids = sorted.map((s) => s.markerId).toList();
    // sorted는 stops의 재배열이라 길이 동일. 순서 변화 없으면 skip.
    final bool unchanged = () {
      for (int i = 0; i < ids.length; i++) {
        if (ids[i] != stops[i].markerId) return false;
      }
      return true;
    }();
    if (unchanged) return;
    setState(() {
      _sorting = true;
      _selectedMarkerId = null;
    });
    try {
      await ref
          .read(routeRepositoryProvider)
          .reorder(widget.tripId, widget.selectedDay, ids);
    } catch (_) {
      _showError('정렬에 실패했습니다.');
    }
    if (mounted) setState(() => _sorting = false);
    _invalidate(RouteSort.order);
  }

  // 방문시간 asc(미정=null은 하단), 동률은 현재 order 유지.
  int _byVisitTime(RouteStop a, RouteStop b) {
    final String? ta = a.visitTime;
    final String? tb = b.visitTime;
    if (ta == null && tb == null) return a.order.compareTo(b.order);
    if (ta == null) return 1;
    if (tb == null) return -1;
    final int c = ta.compareTo(tb);
    return c != 0 ? c : a.order.compareTo(b.order);
  }

  @override
  Widget build(BuildContext context) {
    final stopsAsync =
        ref.watch(dayStopsProvider(widget.tripId, widget.selectedDay, _sort));
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(50)),
        boxShadow: [
          BoxShadow(
              color: Color(0x1A000000), blurRadius: 10, offset: Offset(4, 0)),
        ],
      ),
      child: CustomScrollView(
        controller: widget.scrollController,
        slivers: [
          SliverToBoxAdapter(child: _header()),
          stopsAsync.when(
            loading: () => const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (_, __) => const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: Text('경로를 불러오지 못했습니다.')),
              ),
            ),
            data: _bodySliver,
          ),
        ],
      ),
    );
  }

  Widget _header() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: Row(
            children: [
              const Icon(Icons.bookmark, size: 22, color: _orange),
              const SizedBox(width: 6),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(fontFamily: 'Pretendard'),
                    children: [
                      const TextSpan(
                          text: '저장한 장소 ',
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF070707))),
                      TextSpan(
                          text: '${widget.placeCount}',
                          style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: _orange)),
                      const TextSpan(
                          text: '곳',
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF070707))),
                    ],
                  ),
                ),
              ),
              TextButton(
                onPressed: widget.onExitEdit,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  '카드 탭',
                  style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF7E7E7E)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          child: DayFilterBar(
            selectedDay: widget.selectedDay,
            dayCount: widget.dayCount,
            onDaySelected: widget.onDaySelected,
          ),
        ),
        _sortButton(),
      ],
    );
  }

  // 1회성 "시간순 정렬" 버튼. 누르면 방문시간 순으로 재배치·확정(되돌리기 없음).
  Widget _sortButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 4, 20, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: GestureDetector(
          onTap: _sorting ? null : _sortByTime,
          behavior: HitTestBehavior.opaque,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.schedule, size: 18, color: _orange),
              const SizedBox(width: 5),
              Text(
                _sorting ? '정렬 중…' : '시간순 정렬',
                style: const TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _orange),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bodySliver(List<RouteStop> stops) {
    if (stops.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Center(
            child: Text(
              '장소가 없습니다',
              style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFB2B2B2)),
            ),
          ),
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      sliver: SliverReorderableList(
        itemCount: stops.length,
        onReorder: (o, n) => _onReorder(stops, o, n),
        itemBuilder: (ctx, i) {
          final RouteStop s = stops[i];
          final bool isLast = i == stops.length - 1;
          final RouteStop? next = isLast ? null : stops[i + 1];
          final bool selected = _selectedMarkerId == s.markerId;
          final Category? cat =
              s.categoryId != null ? widget.categoryMap[s.categoryId] : null;
          return ReorderableDelayedDragStartListener(
            key: ValueKey(s.markerId),
            index: i,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: RouteStopCard(
                stop: s,
                selected: selected,
                showTransport: !isLast && stops.length > 1,
                categoryName: cat?.name,
                categoryColor: categoryChipColor(cat?.name),
                onSelectToggle: () => setState(
                    () => _selectedMarkerId = selected ? null : s.markerId),
                onTimeTap: () => _editTime(s),
                onTransportSelected: (m) => _selectTransport(s, m),
                onNavigate: (next != null && s.transportToNext != null)
                    ? () => _navigate(s, next)
                    : null,
              ),
            ),
          );
        },
      ),
    );
  }
}
