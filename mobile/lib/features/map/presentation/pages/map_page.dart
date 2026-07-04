import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../markers/domain/entities/category.dart';
import '../../../markers/domain/entities/marker.dart';
import '../../../markers/data/repositories/marker_repository_impl.dart';
import '../../../markers/presentation/providers/marker_provider.dart';
import '../../../trips/domain/entities/trip.dart';
import '../../data/datasources/naver_local_search_datasource.dart';
import '../../data/datasources/naver_reverse_geocode_datasource.dart';
import '../../domain/entities/naver_place.dart';
import '../../../trips/presentation/providers/trip_provider.dart';
import '../utils/geo_distance.dart';
import '../widgets/map_chip_bar.dart';
import '../widgets/map_search_bar.dart';
import '../widgets/map_view.dart';
import '../widgets/marker_delete_dialog.dart';
import '../widgets/marker_detail_sheet.dart';
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
  NLatLng? _focusTarget;
  NLatLng? _pendingLocation;
  NaverPlace? _pendingPlace;
  String? _searchedPlaceName;
  NLatLng _cameraCenter = const NLatLng(37.5665, 126.9780);
  List<NaverPlace> _searchOverlays = [];
  bool _searchingOverlay = false;
  // v0 제외: 마커 좋아요(찜) 기능 — 좋아요한 마커 id 보관. 추후 복구
  // final Set<String> _likedMarkerIds = {};
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  bool _routeEdit = false;

  static const double _sheetInitial = 0.45;
  static const double _sheetMin = 0.13;
  static const double _sheetMax = 0.88;

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

  Future<void> _showDetailSheet(
      TripMarker marker, List<TripMarker> allMarkers) async {
    setState(() {
      _selectedMarkerId = marker.id;
      _focusTarget = NLatLng(marker.latitude, marker.longitude);
      _pendingLocation = null;
      _pendingPlace = null;
      _searchOverlays = [];
    });
    _animateSheetTo(_sheetMin);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MarkerDetailSheet(
        marker: marker,
        tripId: _tripId,
        allMarkers: allMarkers,
        // v0 제외: 마커 좋아요(찜) 기능 — 추후 복구
        // isLiked: _likedMarkerIds.contains(marker.id),
      ),
    );
    if (mounted) _animateSheetTo(_sheetInitial);
  }

  // 임시 마커(미저장 신규 장소) 상세 시트 공통 흐름:
  // 시트 축소 → 상세 시트 표시 → 닫히면 목록 갱신·시트 복원
  Future<void> _openTempMarkerSheet(
    TripMarker tempMarker,
    List<TripMarker> allMarkers, {
    required VoidCallback onSaved,
    bool clearPendingAfterClose = false,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (_, __) => MarkerDetailSheet(
          marker: tempMarker,
          tripId: _tripId,
          allMarkers: allMarkers,
          onMarkerSaved: onSaved,
        ),
      ),
    );
    if (mounted) {
      ref.invalidate(markerEntitiesProvider(_tripId));
      if (clearPendingAfterClose) {
        setState(() => _pendingLocation = null);
      }
      _animateSheetTo(_sheetInitial);
    }
  }

  Future<void> _showAddSheetFromSearch(
    NaverPlace place,
    Trip? trip,
    List<TripMarker> allMarkers,
  ) async {
    final NLatLng coord = NLatLng(place.latitude, place.longitude);
    setState(() {
      _focusTarget = coord;
      _pendingLocation = coord;
      _pendingPlace = place;
      _searchedPlaceName = place.title;
      _selectedMarkerId = null;
    });
    _animateSheetTo(_sheetMin);
    final TripMarker tempMarker = TripMarker(
      id: '__new__',
      tripId: _tripId,
      name: place.title,
      latitude: place.latitude,
      longitude: place.longitude,
      address: place.address,
      source: MarkerSource.search,
      detail: place.toDetail(),
      createdAt: DateTime.now(),
    );
    await _openTempMarkerSheet(
      tempMarker,
      allMarkers,
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
      id: '__new__',
      tripId: _tripId,
      name: name,
      latitude: coord.latitude,
      longitude: coord.longitude,
      address: address,
      source: MarkerSource.longpress,
      detail: const {},
      createdAt: DateTime.now(),
    );
    await _openTempMarkerSheet(
      tempMarker,
      allMarkers,
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
      id: '__new__',
      tripId: _tripId,
      name: name,
      latitude: coord.latitude,
      longitude: coord.longitude,
      address: address,
      source: MarkerSource.search,
      detail: const {},
      createdAt: DateTime.now(),
    );
    await _openTempMarkerSheet(
      tempMarker,
      allMarkers,
      onSaved: () {
        if (mounted) setState(() => _pendingLocation = null);
      },
      clearPendingAfterClose: true, // 심볼 탭은 닫힘과 동시에 임시 핀 제거
    );
  }

  Future<String?> _nearbyPlaceName(NLatLng coord, String? area) async {
    if (area == null) return null;
    try {
      final List<NaverPlace> results = await ref
          .read(naverLocalSearchDatasourceProvider)
          .search(area, coordinate: '${coord.longitude},${coord.latitude}');
      if (results.isEmpty) return null;
      final NaverPlace nearest = results.first;
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

  Future<void> _handleSearchResult(Object? result, Trip? trip) async {
    if (!mounted) return;
    if (result is TripMarker) {
      final List<TripMarker> latest =
          ref.read(markerEntitiesProvider(_tripId)).valueOrNull ?? [];
      _showDetailSheet(result, latest);
    } else if (result is NaverPlace) {
      final List<TripMarker> latest =
          ref.read(markerEntitiesProvider(_tripId)).valueOrNull ?? [];
      await _showAddSheetFromSearch(result, trip, latest);
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
      await ref.read(markerRepositoryProvider).deleteMarker(m.tripId, m.id);
      ref.invalidate(markerEntitiesProvider(_tripId));
    }
  }

  // "현위치에서 검색": 지도 중심 좌표 기준으로 검색어 재검색 → 오버레이 표시
  Future<void> _searchHere() async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    setState(() => _searchingOverlay = true);
    try {
      final List<NaverPlace> results =
          await ref.read(naverLocalSearchDatasourceProvider).search(
                _searchedPlaceName!,
                coordinate:
                    '${_cameraCenter.longitude},${_cameraCenter.latitude}',
              );
      if (mounted) setState(() => _searchOverlays = results);
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('검색에 실패했습니다.')),
      );
    } finally {
      if (mounted) setState(() => _searchingOverlay = false);
    }
  }

  Future<void> _openSearchPage(Trip? trip) async {
    final Object? result = await Navigator.push<Object?>(
      context,
      MaterialPageRoute<Object?>(
        builder: (_) => SearchPage(
          tripId: _tripId,
          trip: trip,
          center: _cameraCenter,
          initialQuery: _searchedPlaceName,
        ),
      ),
    );
    await _handleSearchResult(result, trip);
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

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: Stack(
        children: [
          // 지도
          Positioned.fill(
            child: MapView(
              initialLocation: const NLatLng(37.5665, 126.9780),
              tripId: _tripId,
              markers: filteredMarkers,
              onMarkerTap: (m) => _showDetailSheet(m, allMarkers),
              onLongTap: (coord) => _showAddSheet(coord, trip, allMarkers),
              onSymbolTap: (name, coord) =>
                  _showAddSheetFromSymbol(name, coord, trip, allMarkers),
              onCameraIdle: (center) {
                _cameraCenter = center;
              },
              bottomPeekFraction: _sheetInitial,
              selectedMarkerId: _selectedMarkerId,
              focusTarget: _focusTarget,
              pendingLocation: _pendingLocation,
              pendingPlace: _pendingPlace,
              searchOverlays: _searchOverlays,
              onSearchMarkerTap: (place) =>
                  _showAddSheetFromSearch(place, trip, allMarkers),
              onMapTap: () => setState(() {
                _selectedMarkerId = null;
                _pendingLocation = null;
                _pendingPlace = null;
                _searchOverlays = [];
              }),
            ),
          ),

          // 검색바 (탭 → SearchPage)
          SafeArea(
            child: MapSearchBar(
              searchedPlaceName: _searchedPlaceName,
              onBack: () => context.go('/trips'),
              onTap: () => _openSearchPage(trip),
              onClear: () => setState(() {
                _searchedPlaceName = null;
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
              canSearchHere: _searchedPlaceName != null && !_searchingOverlay,
              onSearchHere: _searchHere,
              onSelectTrip: () =>
                  _showTripSelector(tripsAsync.valueOrNull ?? []),
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
                    onMarkerTap: (m) => _showDetailSheet(m, allMarkers),
                    // v0 제외: 마커 좋아요(찜) 토글 — 추후 복구
                    // onLikeTap: (id) =>
                    //     setState(() => _likedMarkerIds.contains(id)
                    //         ? _likedMarkerIds.remove(id)
                    //         : _likedMarkerIds.add(id)),
                    onDelete: _confirmDelete,
                  ),
          ),
        ],
      ),
    );
  }
}
