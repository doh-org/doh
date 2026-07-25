import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../markers/data/repositories/marker_repository_impl.dart';
import '../../../markers/domain/entities/category.dart';
import '../../../markers/domain/entities/marker.dart';
import '../../../markers/presentation/providers/marker_provider.dart';
import '../../../markers/presentation/utils/category_colors.dart';
import '../../../routes/domain/entities/route_stop.dart';
import '../../../trips/presentation/providers/trip_provider.dart';
import '../../../../core/storage/map_app_store.dart';
import '../../../../shared/widgets/update_error_dialog.dart';
import '../../../../shared/widgets/bookmark_saved_dialog.dart';
import '../../data/repositories/map_repository_impl.dart';
import '../utils/location_consent_gate.dart';
import '../utils/map_navigation.dart';
import 'marker_delete_dialog.dart';
import 'marker_edit_chips_sheet.dart';
import 'route_section.dart';

class MarkerDetailSheet extends ConsumerStatefulWidget {
  const MarkerDetailSheet({
    required this.marker,
    required this.tripId,
    required this.allMarkers,
    // v0 제외: 마커 좋아요(찜) 기능 — 추후 복구
    // this.isLiked = false,
    this.onMarkerSaved,
    this.onClose,
    super.key,
  });

  final TripMarker marker;
  final String tripId;
  final List<TripMarker> allMarkers;
  // v0 제외: 마커 좋아요(찜) 기능 — 추후 복구
  // final bool isLiked;
  final VoidCallback? onMarkerSaved;

  /// 시트를 닫는 방법. 모달로 띄우면 Navigator.pop, 지도 위 패널이면 상태 해제.
  /// 이 위젯이 자기가 어떻게 떠 있는지 몰라도 되게 호출자가 주입
  final VoidCallback? onClose;

  @override
  ConsumerState<MarkerDetailSheet> createState() => _MarkerDetailSheetState();
}

class _MarkerDetailSheetState extends ConsumerState<MarkerDetailSheet> {
  int _transportIndex = 0;
  String? _departureId; // null = 현위치
  String? _destinationId; // null = 현위치
  late TripMarker _marker;
  bool _saved = true;
  bool _bookmarkLoading = false;
  // v0 제외: 마커 좋아요(찜) 기능 — 추후 복구
  // late bool _isLiked;

  static const _transportLabels = ['차량', '대중교통', '자전거', '도보'];
  static const _transportIcons = [
    Icons.directions_car,
    Icons.subway,
    Icons.directions_bike,
    Icons.directions_walk,
  ];

  @override
  void initState() {
    super.initState();
    _marker = widget.marker;
    _destinationId = widget.marker.id;
    // v0 제외: 마커 좋아요(찜) 기능 — 추후 복구
    // _isLiked = widget.isLiked;
    _saved = widget.allMarkers.any((m) => m.id == widget.marker.id);
  }

  // 미저장 마커를 서버에 생성. 성공 여부 반환 (실패 시 에러 모달 표시)
  Future<bool> _createMarker() async {
    setState(() => _bookmarkLoading = true);
    try {
      final TripMarker created = await ref.read(markerRepositoryProvider).createMarker(
            tripId: widget.tripId,
            name: _marker.name,
            latitude: _marker.latitude,
            longitude: _marker.longitude,
            categoryId: _marker.categoryId,
            address: _marker.address,
            detail: _marker.detail,
            source: _marker.source,
            visitDays: _marker.visitDays,
          );
      if (!mounted) return false;
      setState(() {
        // 임시 id로 잡혀 있던 출발지/목적지를 서버가 발급한 새 id로 갱신
        final String oldId = _marker.id;
        if (_departureId == oldId) _departureId = created.id;
        if (_destinationId == oldId) _destinationId = created.id;
        _marker = created;
        _saved = true;
      });
      ref.invalidate(markerEntitiesProvider(widget.tripId));
      widget.onMarkerSaved?.call();
      return true;
    } catch (_) {
      if (mounted) showUpdateErrorDialog(context, '저장에 실패했습니다.');
      return false;
    } finally {
      if (mounted) setState(() => _bookmarkLoading = false);
    }
  }

  // 저장 완료 안내 모달 (1.5초 후 자동 닫힘)
  Future<void> _showSavedDialog() {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '닫기',
      barrierColor: Colors.black26,
      pageBuilder: (ctx, _, __) => const Align(
        alignment: Alignment.center,
        child: BookmarkSavedDialog(),
      ),
    );
  }

  // 미저장 마커: 북마크 탭만으로 바로 저장 (임시 마커의 유일한 저장 경로)
  Future<void> _saveViaBookmark() async {
    final bool ok = await _createMarker();
    if (ok && mounted) await _showSavedDialog();
  }

  // 쓰레기통 탭 → 삭제 확인 모달 → 확인 시 삭제 후 시트 닫기
  Future<void> _confirmDelete() async {
    final bool? ok = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '닫기',
      barrierColor: Colors.black26,
      pageBuilder: (ctx, _, __) => Align(
        alignment: const Alignment(0, 0.5),
        child: MarkerDeleteDialog(name: _marker.name),
      ),
    );
    if (ok == true && mounted) {
      await ref.read(markerRepositoryProvider).deleteMarker(widget.tripId, _marker.id);
      ref.invalidate(markerEntitiesProvider(widget.tripId));
      if (mounted) widget.onClose?.call();
    }
  }

  // 스위치 아이콘 탭 → 고정된(또는 선택한) 지도 앱에서 이 장소를 검색
  Future<void> _openMapSearch() async {
    // 검색·심볼 마커 → 장소명(역 이름 등)으로 검색해야 장소 상세가 뜸
    // 롱프레스 마커 → 이름이 '새 장소'일 수 있어 주소로 검색
    final String query = resolveMapSearchQuery(
      preferAddress: _marker.source == MarkerSource.longpress,
      name: _marker.name,
      // 신 키(address) 우선, 구버전 저장분은 naver_ 접두 키로 fallback
      address: _detail('address') ?? _detail('naver_address') ?? _marker.address,
    );
    if (query.isEmpty) return; // 검색어 없으면 딥링크 무의미
    final MapApp? app = await ref.read(preferredMapAppProvider.future);
    if (!mounted) return;
    await launchPlaceSearch(context: context, query: query, preferredApp: app);
  }

  String? _detail(String key) {
    final v = _marker.detail[key];
    if (v == null || v.toString().isEmpty) return null;
    return v.toString();
  }

  Future<void> _showEditSheet(
    BuildContext context,
    List<Category> categories,
    int dayCount,
  ) async {
    // true = 저장 탭으로 닫힘, null = 그냥 내려서 닫힘
    final bool? savedTap = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MarkerEditChipsSheet(
        marker: _marker,
        tripId: widget.tripId,
        categories: categories,
        dayCount: dayCount,
        isUnsaved: !_saved,
        onSaved: (updated) {
          if (!mounted) return;
          setState(() => _marker = updated);
        },
      ),
    );
    if (savedTap != true || !mounted) return;
    if (!_saved) {
      // 미저장 마커 → 카테고리·날짜 저장이 곧 장소 저장(북마크와 동일)
      final bool ok = await _createMarker();
      if (ok && mounted) await _showSavedDialog();
    } else {
      // 저장된 마커 → 칩 시트가 이미 서버 반영, 완료 모달만 표시
      await _showSavedDialog();
    }
  }

  // 이동수단 탭 인덱스 → TransportMode. 0=차량,1=대중교통,2=자전거,3=도보.
  static const List<TransportMode> _transportModes = [
    TransportMode.car,
    TransportMode.publictransit,
    TransportMode.bicycle,
    TransportMode.foot,
  ];

  // id로 마커 찾기. 미저장 임시 마커는 allMarkers에 없어서 현재 마커를 먼저 확인
  TripMarker? _findMarker(String id) {
    if (id == _marker.id) return _marker;
    return widget.allMarkers.where((m) => m.id == id).firstOrNull;
  }

  // 현위치 좌표 조회. 앱 동의 게이트를 먼저 통과시키고, 미동의면 서울 폴백을
  // 유지한다(기존 동작 — 결정: 미해결질문 1 유지). 동의 시 getCurrentLocation이
  // OS 권한 거부까지 서울 폴백으로 처리한다.
  static const NLatLng _seoulFallback = NLatLng(37.5665, 126.9780);

  Future<NLatLng> _resolveCurrentLocation() async {
    final bool consented = await ensureLocationConsent(context, ref);
    if (!consented || !mounted) return _seoulFallback;
    return ref.read(mapRepositoryProvider).getCurrentLocation();
  }

  Future<void> _openNavigation() async {
    final NavPoint destination;
    if (_destinationId == null) {
      // 목적지가 현위치(스왑 결과) → 동의 게이트 후 기기 좌표 조회
      final NLatLng pos = await _resolveCurrentLocation();
      if (!mounted) return;
      destination =
          NavPoint(name: '현위치', lat: pos.latitude, lng: pos.longitude);
    } else {
      final TripMarker? dest = _findMarker(_destinationId!);
      destination = NavPoint(
        name: dest?.name ?? _marker.name,
        lat: dest?.latitude ?? _marker.latitude,
        lng: dest?.longitude ?? _marker.longitude,
      );
    }
    // 스왑으로 출발지가 임시 마커일 수도 있어 같은 조회를 사용
    final TripMarker? dep =
        _departureId == null ? null : _findMarker(_departureId!);

    final MapApp? app = await ref.read(preferredMapAppProvider.future);
    if (!mounted) return; // 위치·설정 조회 await 동안 시트가 닫혔을 수 있음
    await launchNavigation(
      context: context,
      mode: _transportModes[_transportIndex],
      destination: destination,
      preferredApp: app,
      departure: dep == null
          ? null
          : NavPoint(name: dep.name, lat: dep.latitude, lng: dep.longitude),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider(widget.tripId));
    final tripAsync = ref.watch(tripDetailNotifierProvider(widget.tripId));
    final categories = categoriesAsync.valueOrNull ?? [];
    final trip = tripAsync.valueOrNull;

    final category = _marker.categoryId != null
        ? categories.where((c) => c.id == _marker.categoryId).firstOrNull
        : null;

    final dayCount = (trip?.startDate != null && trip?.endDate != null)
        ? trip!.endDate!.difference(trip.startDate!).inDays + 1
        : 0;

    // 신 키(address·phone) 우선, 구버전 저장분은 naver_ 접두 키로 fallback
    final String address = _detail('address') ??
        _detail('naver_address') ??
        _marker.address ??
        '정보 없음';
    final String? phone = _detail('phone') ?? _detail('naver_phone');

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        // 좌·우·하 여백을 두고 뜨는 카드라 하단 모서리도 둥글게
        borderRadius: BorderRadius.all(Radius.circular(50)),
        boxShadow: [
          BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 10,
              offset: Offset(4, 0)),
        ],
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: SingleChildScrollView(
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

            // 카테고리 + Day 배지
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: GestureDetector(
                onTap: () => _showEditSheet(context, categories, dayCount),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _InfoChip(
                      label: category?.name ?? '없음',
                      color: categoryChipColor(category?.name),
                    ),
                    if (dayCount > 0) ...[
                      if (_marker.visitDays.isEmpty) ...[
                        const SizedBox(width: 6),
                        const _InfoChip(
                          label: '미정',
                          color: Color(0x808A847B),
                        ),
                      ] else
                        for (final d in _marker.visitDays) ...[
                          const SizedBox(width: 6),
                          _InfoChip(
                            label: 'Day$d',
                            color: const Color(0xCCFE8505),
                          ),
                        ],
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // 장소명 + 삭제(쓰레기통)/네이버지도 전환(스위치)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 헤더의 장소명은 표시 전용 — 편집은 칩 시트(카테고리/날짜와 함께)에서
                  Expanded(
                    child: Text(
                      _marker.name,
                      style: const TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF070707),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 미저장 → 북마크(저장) / 저장됨 → 쓰레기통(삭제 모달)
                  if (!_saved)
                    GestureDetector(
                      onTap: _bookmarkLoading ? null : _saveViaBookmark,
                      child: _bookmarkLoading
                          ? const SizedBox.square(
                              dimension: 25,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFFFE8505),
                              ),
                            )
                          : const Icon(
                              Icons.bookmark_border,
                              size: 25,
                              color: Color(0xFFD5D5D5),
                            ),
                    )
                  else
                    GestureDetector(
                      onTap: _confirmDelete,
                      child: const Icon(
                        Icons.delete_outline,
                        size: 25,
                        color: Color(0xFFB2B2B2),
                      ),
                    ),
                  const SizedBox(width: 10),
                  // 지도 앱으로 전환 — 이 장소 검색 딥링크
                  GestureDetector(
                    onTap: _openMapSearch,
                    child: const Icon(
                      Icons.swap_horiz,
                      size: 25,
                      color: Color(0xFFFE8505),
                    ),
                  ),
                  // v0 제외: 마커 좋아요(찜) 버튼 — 하트 토글. 추후 복구
                  // const SizedBox(width: 10),
                  // GestureDetector(
                  //   onTap: () => setState(() => _isLiked = !_isLiked),
                  //   child: Icon(
                  //     _isLiked ? Icons.favorite : Icons.favorite_border,
                  //     size: 25,
                  //     color: _isLiked
                  //         ? const Color(0xFFFE8505)
                  //         : const Color(0xFFD5D5D5),
                  //   ),
                  // ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 상세정보 (주소, 연락처)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Column(
                children: [
                  _InfoRow(icon: Icons.location_on_outlined, label: '주소', value: address),
                  if (phone != null) ...[
                    const SizedBox(height: 12),
                    _InfoRow(
                      icon: Icons.phone_outlined,
                      label: '연락처',
                      value: phone,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 출발지/목적지
            RouteSection(
              currentMarker: _marker,
              allMarkers: widget.allMarkers,
              departureId: _departureId,
              destinationId: _destinationId,
              onDepartureChanged: (id) => setState(() {
                _departureId = id;
                // 둘 다 현위치가 되면 안내가 무의미 → 목적지를 이 마커로 되돌림
                if (id == null && _destinationId == null) {
                  _destinationId = _marker.id;
                }
              }),
              onDestinationChanged: (id) => setState(() {
                _destinationId = id;
                // 둘 다 현위치가 되면 안내가 무의미 → 출발지를 이 마커로 되돌림
                if (id == null && _departureId == null) {
                  _departureId = _marker.id;
                }
              }),
              onSwap: () => setState(() {
                // 현위치(null)도 그대로 목적지로 넘어감
                final swapped = swapRoutePoints(
                  departureId: _departureId,
                  destinationId: _destinationId,
                );
                _departureId = swapped.departureId;
                _destinationId = swapped.destinationId;
              }),
            ),
            const SizedBox(height: 16),

            // 이동수단 탭
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                children: List.generate(4, (i) {
                  final active = _transportIndex == i;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: i < 3 ? 6 : 0),
                      child: GestureDetector(
                        onTap: () => setState(() => _transportIndex = i),
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: active
                                ? const Color(0xFFFE8505)
                                : const Color(0xFFF1F2F4),
                            borderRadius: BorderRadius.circular(17),
                            boxShadow: active
                                ? const [
                                    BoxShadow(
                                      color: Color(0x4D000000),
                                      blurRadius: 4,
                                      offset: Offset(1, 1),
                                    )
                                  ]
                                : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _transportIcons[i],
                                size: 15,
                                color: active
                                    ? const Color(0xFFFDFDFD)
                                    : const Color(0xFF1F2125),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _transportLabels[i],
                                style: TextStyle(
                                  fontFamily: 'Pretendard',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: active
                                      ? const Color(0xFFFDFDFD)
                                      : const Color(0xFF1F2125),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 16),

            // 길찾기 버튼
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: GestureDetector(
                onTap: _openNavigation,
                child: Container(
                  height: 48,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xCC2A6FDB),
                    borderRadius: BorderRadius.circular(17),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x4D000000),
                        blurRadius: 4,
                        offset: Offset(1, 1),
                      )
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.directions, size: 20, color: Color(0xFFFDFDFD)),
                      SizedBox(width: 8),
                      Text(
                        '길찾기',
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFFDFDFD),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 9 + MediaQuery.of(context).padding.bottom),
          ],
        ),
        ),
      ),
    );
  }
}

// 상세정보 행 위젯
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 20, color: const Color(0xFFB2B2B2)),
        const SizedBox(width: 5),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFB2B2B2),
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                style: const TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1F2125),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// 카테고리/Day 배지 칩
class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 20,
      constraints: const BoxConstraints(minWidth: 50),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}
