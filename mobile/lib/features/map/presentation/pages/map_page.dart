import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/update_error_dialog.dart';
import '../../../markers/domain/entities/category.dart';
import '../../../markers/domain/entities/marker.dart';
import '../../../markers/data/repositories/marker_repository_impl.dart';
import '../../../markers/presentation/providers/marker_provider.dart';
import '../../../trips/domain/entities/trip.dart';
import '../../data/datasources/place_search_datasource.dart';
import '../../data/datasources/naver_reverse_geocode_datasource.dart';
import '../../data/repositories/map_repository_impl.dart';
import '../../domain/entities/place.dart';
import '../../domain/repositories/map_repository.dart';
import '../../../trips/presentation/providers/trip_provider.dart';
import '../utils/geo_distance.dart';
import '../utils/location_consent_gate.dart';
import '../widgets/current_location_fab.dart';
import '../widgets/location_permission_dialog.dart';
import '../widgets/map_chip_bar.dart';
import '../widgets/map_search_bar.dart';
import '../widgets/map_view.dart';
import '../widgets/marker_delete_dialog.dart';
import '../widgets/marker_detail_panel.dart';
import '../widgets/marker_detail_sheet.dart';
import '../providers/map_provider.dart';
import '../widgets/place_list_sheet.dart';
import '../widgets/route_edit_sheet.dart';
import '../widgets/trip_selector_sheet.dart';
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

  // 지도 위에 떠 있는 상세 패널의 대상 마커. null이면 패널 없음
  String? _detailMarkerId;
  // 목록에서 사라진 뒤(삭제 등)에도 한 프레임 그릴 수 있게 두는 마지막 스냅샷
  TripMarker? _detailFallback;
  bool _detailPeeked = false;
  // 상세 패널 보이는 높이만큼의 지도 하단 패딩 비율(0~1). 현위치 버튼 여백용, _sheetPeek와 대칭
  final ValueNotifier<double> _detailPeek = ValueNotifier<double>(0);
  // 열릴 때 1회만 재중심하기 위한 플래그. peek/드래그로 높이가 바뀌어도 무시
  bool _detailCentered = false;
  // 임시 마커(미저장) 패널일 때만 채워지는 상태
  VoidCallback? _detailOnSaved; // 저장 성공 시 임시 핀 정리 콜백
  bool _detailClearPendingOnClose = false; // 닫을 때 임시 핀 제거 여부
  NLatLng? _focusTarget;
  NLatLng? _pendingLocation;
  Place? _pendingPlace;
  String? _searchKeyword; // 사용자가 입력한 검색어 — 표시·현위치 재검색에 함께 사용
  NLatLng _cameraCenter = const NLatLng(37.5665, 126.9780);
  double _cameraZoom = 11; // map_view 초기 카메라 줌과 동일
  List<Place> _searchOverlays = [];
  bool _searchingOverlay = false;
  // v0 제외: 마커 좋아요(찜) 기능 — 좋아요한 마커 id 보관. 추후 복구
  // final Set<String> _likedMarkerIds = {};
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  bool _routeEdit = false;

  static const double _sheetInitial = 0.45;
  static const double _sheetMin = 0.13;
  static const double _sheetMax = 0.88;
  static const String _tempMarkerId = '__new__'; // 미저장 임시 마커의 예약 id

  // 현위치(네이티브) 버튼을 시트 상단에 붙이기 위한 하단 여백 비율(0~1)
  final ValueNotifier<double> _sheetPeek =
      ValueNotifier<double>(_sheetInitial);

  // 목록 시트·상세 패널 두 여백 합성 리스너
  late final Listenable _peekListenable =
      Listenable.merge([_sheetPeek, _detailPeek]);

  @override
  void initState() {
    super.initState();
    _tripId = widget.tripId;
  }

  @override
  void dispose() {
    _sheetController.dispose();
    _sheetPeek.dispose();
    _detailPeek.dispose();
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

  // 새 마커의 방문일 초기값: 시트에서 선택 중인 Day 탭을 사용
  // (미정 탭(0)이면 비워서 기존처럼 '미정'으로 시작)
  List<int> get _initialVisitDays =>
      _selectedDay == 0 ? const <int>[] : <int>[_selectedDay];

  // 바텀 시트를 지정 높이로 애니메이션 (미부착이면 무시)
  void _animateSheetTo(double size) {
    if (_sheetController.isAttached) {
      _sheetController.animateTo(
        size,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  // 지도 제스처 시작 → 시트가 올라와 있으면 최소 높이로 접기
  void _collapseSheetOnMapGesture() {
    _peekDetail(); // 상세 패널도 같이 내림
    if (!_sheetController.isAttached) return;
    // 이미 최소 높이면 무시 (드래그 중 반복 호출되므로 불필요한 애니메이션 방지)
    if (_sheetController.size <= _sheetMin + 0.01) return;
    _animateSheetTo(_sheetMin);
  }

  void _showTripSelector(List<Trip> trips) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => TripSelectorSheet(
        trips: trips,
        currentTripId: _tripId,
        onSelected: (String id) {
          setState(() {
            _tripId = id;
            _selectedDay = 0;
          });
        },
      ),
    );
  }

  // 상세 패널 열기. 모달이 아니라 상태만 변경 — 지도는 계속 조작 가능
  void _showDetailSheet(TripMarker marker) {
    setState(() {
      _selectedMarkerId = marker.id;
      // 카메라 이동은 상세 패널 높이 확정 후 재중심(_onDetailHeight)에서 1회 처리 →
      // 마커가 시트 위 영역 중앙에 오도록. 여기서 전체중심으로 먼저 옮기면 두 번 움직임
      _pendingLocation = null;
      _pendingPlace = null;
      _searchOverlays = [];
      _detailMarkerId = marker.id;
      _detailFallback = marker;
      _detailPeeked = false;
      _detailCentered = false;
      _detailOnSaved = null; // 저장된 마커엔 임시 정리 콜백 없음
      _detailClearPendingOnClose = false;
    });
    _animateSheetTo(_sheetMin); // 뒤쪽 목록 시트는 내려둠
  }

  void _closeDetail() {
    final bool wasTemp = _detailMarkerId == _tempMarkerId; // 임시 마커 여부
    final bool clearPending = _detailClearPendingOnClose;
    setState(() {
      _detailMarkerId = null;
      _detailFallback = null;
      _detailPeeked = false;
      _detailPeek.value = 0; // 버튼 여백 원복
      _detailCentered = false;
      _detailOnSaved = null;
      _detailClearPendingOnClose = false;
      _selectedMarkerId = null; // 마커 하이라이트도 함께 해제
      if (clearPending) _pendingLocation = null; // 심볼 탭 임시 핀 제거
    });
    if (wasTemp) ref.invalidate(markerEntitiesProvider(_tripId)); // 목록 갱신
    _animateSheetTo(_sheetInitial);
  }

  // 지도 탭·제스처 → 패널을 닫지 않고 아래로만 내림
  void _peekDetail() {
    if (_detailMarkerId == null || _detailPeeked) return;
    setState(() => _detailPeeked = true);
  }

  // 상세 패널 높이가 확정되면 그 높이만큼 지도 하단 패딩을 주고 마커를 그 위 영역
  // 중앙으로 1회 재중심. peek/드래그로 높이가 다시 바뀌어도 무시(_detailCentered)
  // 확정 내용 높이 → 버튼 여백 비율 갱신(매번) + 마커 재중심(1회)
  void _onDetailHeight(double panelHeight) {
    if (panelHeight <= 0) return;
    final double screenH = MediaQuery.sizeOf(context).height;
    if (screenH <= 0) return;
    // 엿보기 중엔 _onDetailVisibleHeight가 값의 주인 → 덮어쓰기 제외
    if (!_detailPeeked) {
      _detailPeek.value = (panelHeight / screenH).clamp(0.0, 0.9);
    }
    if (_detailCentered) return; // 재중심 1회
    final TripMarker? m = _detailFallback;
    if (m == null) return;
    _detailCentered = true;
    // 패딩 반영 다음 프레임에 재중심
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(mapControllerProvider.notifier)
          .moveCamera(NLatLng(m.latitude, m.longitude), zoom: 15);
    });
  }

  // 보이는 높이(px) → 버튼 여백 비율. notifier라 지도만 갱신
  void _onDetailVisibleHeight(double px) {
    final double screenH = MediaQuery.sizeOf(context).height;
    if (screenH <= 0) return;
    _detailPeek.value = (px / screenH).clamp(0.0, 0.9);
  }

  // 임시 마커(미저장 신규 장소)를 상세 패널로 띄우기.
  // 저장된 마커와 같은 패널을 써서 지도 탭·팬·줌에 함께 반응(모달 아님).
  void _openTempMarkerSheet(
    TripMarker tempMarker, {
    required VoidCallback onSaved,
    bool clearPendingAfterClose = false,
  }) {
    setState(() {
      _selectedMarkerId = null;
      _detailMarkerId = tempMarker.id; // = _tempMarkerId
      _detailFallback = tempMarker;
      _detailPeeked = false;
      _detailCentered = false;
      _detailOnSaved = onSaved;
      _detailClearPendingOnClose = clearPendingAfterClose;
    });
    _animateSheetTo(_sheetMin);
  }

  Future<void> _showAddSheetFromSearch(
    Place place,
    Trip? trip,
    List<TripMarker> allMarkers,
  ) async {
    final NLatLng coord = NLatLng(place.latitude, place.longitude);
    setState(() {
      _focusTarget = coord;
      _pendingLocation = coord;
      _pendingPlace = place;
      _selectedMarkerId = null;
    });
    _animateSheetTo(_sheetMin);
    final TripMarker tempMarker = TripMarker(
      id: _tempMarkerId,
      tripId: _tripId,
      name: place.title,
      latitude: place.latitude,
      longitude: place.longitude,
      address: place.address,
      source: MarkerSource.search,
      detail: place.toDetail(),
      visitDays: _initialVisitDays, // 선택된 Day 탭 자동 반영
      createdAt: DateTime.now(),
    );
    _openTempMarkerSheet(
      tempMarker,
      onSaved: () {
        if (mounted) {
          setState(() {
            _pendingLocation = null;
            _pendingPlace = null;
          });
        }
      },
    );
  }

  Future<void> _showAddSheet(
    NLatLng coord,
    Trip? trip,
    List<TripMarker> allMarkers,
  ) async {
    setState(() {
      _focusTarget = coord;
      _pendingLocation = coord;
    });
    _animateSheetTo(_sheetMin);
    final (:String? address, :String? area) = await ref
        .read(naverReverseGeocodeDatasourceProvider)
        .reverseGeocodeDetails(coord.latitude, coord.longitude);
    final String name = await _nearbyPlaceName(coord, area) ?? '새 장소';
    if (!mounted) return;
    final TripMarker tempMarker = TripMarker(
      id: _tempMarkerId,
      tripId: _tripId,
      name: name,
      latitude: coord.latitude,
      longitude: coord.longitude,
      address: address,
      source: MarkerSource.longpress,
      detail: const {},
      visitDays: _initialVisitDays, // 선택된 Day 탭 자동 반영
      createdAt: DateTime.now(),
    );
    _openTempMarkerSheet(
      tempMarker,
      onSaved: () {
        if (mounted) setState(() => _pendingLocation = null);
      },
    );
  }

  Future<void> _showAddSheetFromSymbol(
    String name,
    NLatLng coord,
    Trip? trip,
    List<TripMarker> allMarkers,
  ) async {
    setState(() {
      _focusTarget = coord;
      _pendingLocation = coord;
      _selectedMarkerId = null;
      _searchOverlays = [];
    });
    _animateSheetTo(_sheetMin);
    final String? address = await ref
        .read(naverReverseGeocodeDatasourceProvider)
        .reverseGeocode(coord.latitude, coord.longitude);
    if (!mounted) return;
    final TripMarker tempMarker = TripMarker(
      id: _tempMarkerId,
      tripId: _tripId,
      name: name,
      latitude: coord.latitude,
      longitude: coord.longitude,
      address: address,
      source: MarkerSource.search,
      detail: const {},
      visitDays: _initialVisitDays, // 선택된 Day 탭 자동 반영
      createdAt: DateTime.now(),
    );
    _openTempMarkerSheet(
      tempMarker,
      onSaved: () {
        if (mounted) setState(() => _pendingLocation = null);
      },
      clearPendingAfterClose: true, // 심볼 탭은 닫힘과 동시에 임시 핀 제거
    );
  }

  Future<String?> _nearbyPlaceName(NLatLng coord, String? area) async {
    if (area == null) return null;
    try {
      final List<Place> results = await ref
          .read(placeSearchDatasourceProvider)
          .search(area,
              x: coord.longitude.toString(), y: coord.latitude.toString());
      if (results.isEmpty) return null;
      final Place nearest = results.first;
      final double dist = haversineMeters(
        coord.latitude,
        coord.longitude,
        nearest.latitude,
        nearest.longitude,
      );
      return dist <= 50 ? nearest.title : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _handleSearchResult(SearchPageResult? result, Trip? trip) async {
    if (!mounted || result == null) return;
    final (Object? selection, String query) = result;
    // 고른 게 없어도 검색어는 유지 → 지도에서 "현위치에서 검색" 가능
    setState(() => _searchKeyword = query.isEmpty ? null : query);
    if (selection is TripMarker) {
      _showDetailSheet(selection);
    } else if (selection is Place) {
      final List<TripMarker> latest =
          ref.read(markerEntitiesProvider(_tripId)).valueOrNull ?? [];
      await _showAddSheetFromSearch(selection, trip, latest);
    }
  }

  Future<void> _confirmDelete(TripMarker m) async {
    final bool? ok = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '닫기',
      barrierColor: Colors.black26,
      pageBuilder: (ctx, _, __) => Align(
        alignment: const Alignment(0, 0.5),
        child: MarkerDeleteDialog(name: m.name),
      ),
    );
    if (ok == true) {
      try {
        await ref.read(markerRepositoryProvider).deleteMarker(m.tripId, m.id);
        ref.invalidate(markerEntitiesProvider(_tripId));
      } catch (_) {
        if (mounted) showUpdateErrorDialog(context, '삭제에 실패했습니다.');
      }
    }
  }

  // "현위치에서 검색": 지도 중심 좌표 기준으로 검색어 재검색 → 오버레이 표시
  Future<void> _searchHere() async {
    setState(() => _searchingOverlay = true);
    try {
      final List<Place> results =
          await ref.read(placeSearchDatasourceProvider).search(
                _searchKeyword!,
                x: _cameraCenter.longitude.toString(),
                y: _cameraCenter.latitude.toString(),
                zoom: _cameraZoom,
              );
      if (mounted) setState(() => _searchOverlays = results);
    } catch (_) {
      if (mounted) showUpdateErrorDialog(context, '검색에 실패했습니다.');
    } finally {
      if (mounted) setState(() => _searchingOverlay = false);
    }
  }

  Future<void> _openSearchPage(Trip? trip) async {
    final SearchPageResult? result = await Navigator.push<SearchPageResult>(
      context,
      MaterialPageRoute<SearchPageResult>(
        builder: (_) => SearchPage(
          tripId: _tripId,
          trip: trip,
          center: _cameraCenter,
          zoom: _cameraZoom,
          initialQuery: _searchKeyword,
        ),
      ),
    );
    await _handleSearchResult(result, trip);
  }

  // 현위치 FAB 탭 처리. 네이티브 버튼을 대신해 동의 흐름을 직접 제어한다.
  Future<void> _moveToCurrentLocation() async {
    // 1) 앱 자체 동의(우리 약관) 게이트 — 미동의면 위치 사용 안 함
    final bool consented = await ensureLocationConsent(context, ref);
    if (!consented || !mounted) return;
    // 2) OS 위치 권한 — 앱 동의와 별개 층
    final MapRepository repo = ref.read(mapRepositoryProvider);
    final bool granted = await repo.requestLocationPermission();
    if (!mounted) return;
    if (!granted) {
      // 권한 거부 → OS 설정 안내. [설정 열기] 선택 시 앱 설정으로 이동
      final bool? openSettings = await showLocationPermissionDialog(context);
      if (openSettings == true) await repo.openLocationSettings();
      return;
    }
    // 3) 추적 모드 on — 좌표 조회·오버레이·카메라 이동을 SDK가 처리
    ref.read(mapControllerProvider.notifier).startLocationTracking();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<TripMarker>> markersAsync =
        ref.watch(markerEntitiesProvider(_tripId));
    final AsyncValue<List<Category>> categoriesAsync =
        ref.watch(categoriesProvider(_tripId));
    final tripAsync = ref.watch(tripDetailNotifierProvider(_tripId));
    final tripsAsync = ref.watch(tripsProvider);

    final Trip? trip = tripAsync.valueOrNull;
    final List<Category> categories = categoriesAsync.valueOrNull ?? [];
    final Map<String, Category> categoryMap = {
      for (final Category c in categories) c.id: c
    };
    final List<TripMarker> allMarkers = markersAsync.valueOrNull ?? [];
    final List<TripMarker> filteredMarkers =
        _filterByDay(allMarkers, _selectedDay);

    // 패널이 항상 최신 마커를 그리도록 id로 다시 조회 (카테고리·Day 수정 즉시 반영).
    // 목록에서 사라졌으면 마지막 스냅샷으로 대체
    final TripMarker? detailMarker = _detailMarkerId == null
        ? null
        : allMarkers.where((TripMarker m) => m.id == _detailMarkerId).firstOrNull ??
            _detailFallback;

    return PopScope(
      // 상세 패널이 떠 있으면 뒤로가기는 페이지 이탈이 아니라 패널 닫기
      canPop: _detailMarkerId == null,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) return;
        _closeDetail();
      },
      child: Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      // 시트 드래그(높이 변화) 알림을 받아 현위치 버튼 여백에 반영.
      // 초깃값 위로는 올리지 않아(clamp) 시트에 가려지게 둠.
      body: NotificationListener<DraggableScrollableNotification>(
        onNotification: (DraggableScrollableNotification n) {
          _sheetPeek.value =
              n.extent.clamp(_sheetMin, _sheetInitial).toDouble();
          return false; // 알림을 소비하지 않고 그대로 흘려보냄
        },
        child: Stack(
        children: [
          // 지도
          Positioned.fill(
            // 두 여백 변화 시 지도만 다시 그려 버튼 여백 갱신
            child: ListenableBuilder(
              listenable: _peekListenable,
              builder: (_, __) => MapView(
                initialLocation: const NLatLng(37.5665, 126.9780),
                tripId: _tripId,
                markers: filteredMarkers,
                onMarkerTap: _showDetailSheet,
                onLongTap: (coord) => _showAddSheet(coord, trip, allMarkers),
                onSymbolTap: (name, coord) =>
                    _showAddSheetFromSymbol(name, coord, trip, allMarkers),
                onCameraIdle: (NLatLng center, double zoom) {
                  _cameraCenter = center;
                  _cameraZoom = zoom;
                },
                onCameraGesture: _collapseSheetOnMapGesture,
                // 상세 패널·목록 시트 중 큰 여백 적용
                bottomPeekFraction:
                    math.max(_sheetPeek.value, _detailPeek.value),
                selectedMarkerId: _selectedMarkerId,
                focusTarget: _focusTarget,
                pendingLocation: _pendingLocation,
                pendingPlace: _pendingPlace,
                searchOverlays: _searchOverlays,
                onSearchMarkerTap: (place) =>
                    _showAddSheetFromSearch(place, trip, allMarkers),
                keepSelectionOnTap: _detailMarkerId != null,
                onMapTap: () {
                  // 상세 패널이 떠 있음 → 닫지 말고 아래로만 내림
                  if (_detailMarkerId != null) {
                    _peekDetail();
                    return;
                  }
                  setState(() {
                    _selectedMarkerId = null;
                    _pendingLocation = null;
                    _pendingPlace = null;
                    _searchOverlays = [];
                  });
                },
              ),
            ),
          ),

          // 검색바 (탭 → SearchPage)
          SafeArea(
            child: MapSearchBar(
              keyword: _searchKeyword,
              onBack: () => context.go('/trips'),
              onTap: () => _openSearchPage(trip),
              onClear: () => setState(() {
                _searchKeyword = null;
                _searchOverlays = [];
                _pendingLocation = null;
                _pendingPlace = null;
              }),
            ),
          ),

          // 폴더 칩 (Trip 선택) + 현위치에서 검색
          SafeArea(
            child: MapChipBar(
              tripTitle: trip?.title,
              canSearchHere: _searchKeyword != null && !_searchingOverlay,
              onSearchHere: _searchHere,
              onSelectTrip: () =>
                  _showTripSelector(tripsAsync.valueOrNull ?? []),
            ),
          ),

          // 현위치 FAB. 시트 peek 높이 위에 떠 있고, 시트가 커지면 그 아래
          // 레이어라 가려진다(네이티브 버튼이 시트에 가려지던 동작 유지).
          Positioned.fill(
            child: ListenableBuilder(
              listenable: _peekListenable,
              builder: (BuildContext ctx, _) {
                final double screenH = MediaQuery.sizeOf(ctx).height;
                final double peek =
                    math.max(_sheetPeek.value, _detailPeek.value);
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: screenH * peek + 16,
                    right: 16,
                  ),
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: CurrentLocationFab(onTap: _moveToCurrentLocation),
                  ),
                );
              },
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
            builder: (_, ScrollController scrollCtrl) => _routeEdit
                ? RouteEditSheet(
                    scrollController: scrollCtrl,
                    tripId: _tripId,
                    selectedDay: _selectedDay,
                    dayCount: _dayCount(trip),
                    placeCount: allMarkers.length,
                    categoryMap: categoryMap,
                    onDaySelected: (d) => setState(() {
                      _selectedDay = d;
                      if (d == 0) _routeEdit = false;
                    }),
                    onExitEdit: () => setState(() => _routeEdit = false),
                  )
                : PlaceListSheet(
                    scrollController: scrollCtrl,
                    placeCount: allMarkers.length,
                    tripTitle: trip?.title ?? '',
                    dayCount: _dayCount(trip),
                    selectedDay: _selectedDay,
                    onDaySelected: (d) => setState(() => _selectedDay = d),
                    markers: filteredMarkers,
                    categoryMap: categoryMap,
                    // v0 제외: 마커 좋아요(찜) 기능 — 추후 복구
                    // likedIds: _likedMarkerIds,
                    hasError: markersAsync.hasError,
                    canEditRoute: _selectedDay != 0,
                    onEditRoute: () => setState(() => _routeEdit = true),
                    onSearchTap: () => _openSearchPage(trip),
                    onMarkerTap: _showDetailSheet,
                    // v0 제외: 마커 좋아요(찜) 토글 — 추후 복구
                    // onLikeTap: (id) =>
                    //     setState(() => _likedMarkerIds.contains(id)
                    //         ? _likedMarkerIds.remove(id)
                    //         : _likedMarkerIds.add(id)),
                    onDelete: _confirmDelete,
                  ),
          ),

          // 마커 상세 패널
          if (detailMarker != null)
            MarkerDetailPanel(
              key: ValueKey<String>(detailMarker.id),
              peeked: _detailPeeked,
              onPeek: () => setState(() => _detailPeeked = true),
              onExpand: () => setState(() => _detailPeeked = false),
              onClose: _closeDetail,
              onHeightChanged: _onDetailHeight,
              onVisibleHeightChanged: _onDetailVisibleHeight,
              child: MarkerDetailSheet(
                marker: detailMarker,
                tripId: _tripId,
                allMarkers: allMarkers,
                onClose: _closeDetail,
                onMarkerSaved: _detailOnSaved, // 임시 마커 저장 시 임시 핀 정리
                // v0 제외: 마커 좋아요(찜) 기능 — 추후 복구
                // isLiked: _likedMarkerIds.contains(detailMarker.id),
              ),
            ),
        ],
        ),
      ),
      ),
    );
  }
}
