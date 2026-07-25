import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../markers/domain/entities/category.dart';
import '../../../markers/domain/entities/marker.dart';
import '../../../markers/presentation/providers/marker_provider.dart';
import '../../domain/entities/place.dart';
import '../providers/map_provider.dart';

class MapView extends ConsumerStatefulWidget {
  const MapView({
    required this.initialLocation,
    required this.tripId,
    required this.markers,
    this.onMarkerTap,
    this.onLongTap,
    this.onSymbolTap,
    this.onCameraIdle,
    this.onCameraGesture,
    this.onSearchMarkerTap,
    this.onMapTap,
    this.keepSelectionOnTap = false,
    this.bottomPeekFraction = 0.0,
    this.selectedMarkerId,
    this.focusTarget,
    this.pendingLocation,
    this.pendingPlace,
    this.searchOverlays = const [],
    super.key,
  });

  final NLatLng initialLocation;
  final String tripId;
  final List<TripMarker> markers;
  final void Function(TripMarker)? onMarkerTap;
  final void Function(NLatLng)? onLongTap;
  final void Function(String name, NLatLng coord)? onSymbolTap;
  // 카메라 정지 시 중심 좌표와 줌을 함께 전달 (줌은 검색 티어 결정에 사용)
  final void Function(NLatLng center, double zoom)? onCameraIdle;
  // 사용자 제스처(드래그·줌 등)로 카메라가 움직이기 시작할 때 호출
  final VoidCallback? onCameraGesture;
  final void Function(Place)? onSearchMarkerTap;
  final VoidCallback? onMapTap;

  final bool keepSelectionOnTap;

  final double bottomPeekFraction;
  final String? selectedMarkerId;
  final NLatLng? focusTarget;
  final NLatLng? pendingLocation;
  final Place? pendingPlace;
  final List<Place> searchOverlays;

  @override
  ConsumerState<MapView> createState() => _MapViewState();
}

class _MapViewState extends ConsumerState<MapView> {
  NaverMapController? _controller;
  String? _selectedMarkerId;
  List<TripMarker> _lastMarkers = [];
  List<Category> _lastCategories = [];
  final Map<String, Size> _assetSizeCache = {};

  @override
  void didUpdateWidget(MapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedMarkerId != widget.selectedMarkerId &&
        widget.selectedMarkerId != _selectedMarkerId) {
      _selectedMarkerId = widget.selectedMarkerId;
      _updateOverlays(_lastMarkers, _lastCategories);
    }
    if (oldWidget.focusTarget != widget.focusTarget &&
        widget.focusTarget != null) {
      _controller?.updateCamera(
        NCameraUpdate.scrollAndZoomTo(target: widget.focusTarget!, zoom: 15),
      );
    }
    if (!identical(oldWidget.markers, widget.markers)) {
      _updateOverlays(widget.markers, _lastCategories);
    }
    if (oldWidget.pendingLocation != widget.pendingLocation) {
      _updateOverlays(_lastMarkers, _lastCategories);
    }
    if (!identical(oldWidget.searchOverlays, widget.searchOverlays)) {
      _updateOverlays(_lastMarkers, _lastCategories);
    }
  }

  Future<Size> _assetSize(String assetPath) async {
    if (_assetSizeCache.containsKey(assetPath)) {
      return _assetSizeCache[assetPath]!;
    }
    final ByteData data = await rootBundle.load(assetPath);
    final ui.Codec codec =
        await ui.instantiateImageCodec(data.buffer.asUint8List());
    final ui.FrameInfo frame = await codec.getNextFrame();
    final Size size = Size(
      frame.image.width.toDouble(),
      frame.image.height.toDouble(),
    );
    frame.image.dispose();
    _assetSizeCache[assetPath] = size;
    return size;
  }

  String _markerAsset(TripMarker m, List<Category> categories) {
    if (m.id == _selectedMarkerId) return 'assets/marker/red-marker.png';
    final Iterable<Category> matches =
        categories.where((Category c) => c.id == m.categoryId);
    final String? catName = matches.isEmpty ? null : matches.first.name;
    return switch (catName) {
      '카페' => 'assets/marker/yellow-marker.png',
      '식당' => 'assets/marker/orange-marker.png',
      '관광' => 'assets/marker/blue-marker.png',
      '숙소' => 'assets/marker/green-marker.png',
      _ => 'assets/marker/gray-marker.png',
    };
  }

  Future<void> _updateOverlays(
      List<TripMarker> markers, List<Category> categories) async {
    final NaverMapController? ctrl = _controller;
    if (ctrl == null) return;
    _lastMarkers = markers;
    _lastCategories = categories;
    ctrl.clearOverlays();
    final List<Future<void>> futures = [
      ...markers.map((TripMarker m) async {
      final String assetPath = _markerAsset(m, categories);
      final Size natural = await _assetSize(assetPath);
      const double redH = 44, defaultH = 40;
      final double targetH = assetPath == 'assets/marker/red-marker.png' ? redH : defaultH;
      final Size size = Size(natural.width * targetH / natural.height, targetH);
      final NOverlayImage icon = NOverlayImage.fromAssetImage(assetPath);
      final NMarker nMarker = NMarker(
        id: m.id,
        position: NLatLng(m.latitude, m.longitude),
      )
        ..setIcon(icon)
        ..setSize(size)
        ..setCaption(NOverlayCaption(
          text: m.name,
          textSize: 11,
          color: const Color(0xFF1F2125),
          haloColor: Colors.white,
        ));
      nMarker.setOnTapListener((_) {
        setState(() => _selectedMarkerId = m.id);
        _updateOverlays(_lastMarkers, _lastCategories);
        widget.onMarkerTap?.call(m);
        return true;
      });
      await ctrl.addOverlay(nMarker);
    }),
    if (widget.pendingLocation != null)
      () async {
        const String redAsset = 'assets/marker/red-marker.png';
        final Size natural = await _assetSize(redAsset);
        const double targetH = 44;
        final Size size = Size(natural.width * targetH / natural.height, targetH);
        final NMarker pending = NMarker(
          id: '__pending__',
          position: widget.pendingLocation!,
        )
          ..setIcon(const NOverlayImage.fromAssetImage(redAsset))
          ..setSize(size);
        if (widget.pendingPlace != null) {
          pending.setOnTapListener((_) {
            widget.onSearchMarkerTap?.call(widget.pendingPlace!);
            return true;
          });
        }
        await ctrl.addOverlay(pending);
      }(),
    ...widget.searchOverlays.asMap().entries.map((MapEntry<int, Place> e) async {
      const String redAsset = 'assets/marker/red-marker.png';
      final Size natural = await _assetSize(redAsset);
      const double targetH = 40;
      final Size size = Size(natural.width * targetH / natural.height, targetH);
      final NMarker marker = NMarker(
        id: '__search__${e.key}',
        position: NLatLng(e.value.latitude, e.value.longitude),
      )
        ..setIcon(const NOverlayImage.fromAssetImage(redAsset))
        ..setSize(size)
        ..setCaption(NOverlayCaption(
          text: e.value.title,
          textSize: 11,
          color: const Color(0xFF1F2125),
          haloColor: Colors.white,
        ))
        ..setOnTapListener((_) {
          widget.onSearchMarkerTap?.call(e.value);
          return true;
        });
      await ctrl.addOverlay(marker);
    }),
    ];
    await Future.wait(futures);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(categoriesProvider(widget.tripId),
        (_, AsyncValue<List<Category>> next) {
      _updateOverlays(_lastMarkers, next.valueOrNull ?? []);
    });

    final double screenHeight = MediaQuery.sizeOf(context).height;
    return NaverMap(
      options: NaverMapViewOptions(
        initialCameraPosition: NCameraPosition(
          target: widget.initialLocation,
          zoom: 11,
        ),
        // 네이티브 현위치 버튼은 탭을 가로챌 수 없어 동의 게이트를 못 건다.
        // → 끄고 map_page가 커스텀 FAB로 게이트→권한→카메라 이동을 제어(대안1).
        locationButtonEnable: false,
        contentPadding: EdgeInsets.only(
          bottom: screenHeight * widget.bottomPeekFraction,
        ),
      ),
      onMapReady: (NaverMapController controller) async {
        _controller = controller;
        ref.read(mapControllerProvider.notifier).setController(controller);
        final List<Category> categories =
            ref.read(categoriesProvider(widget.tripId)).valueOrNull ?? [];
        await _updateOverlays(widget.markers, categories);
      },
      onMapLongTapped: (NPoint point, NLatLng coord) =>
          widget.onLongTap?.call(coord),
      onSymbolTapped: (NSymbolInfo info) =>
          widget.onSymbolTap?.call(info.caption, info.position),
      onMapTapped: (_, __) {
        if (!widget.keepSelectionOnTap && _selectedMarkerId != null) {
          setState(() => _selectedMarkerId = null);
          _updateOverlays(_lastMarkers, _lastCategories);
        }
        widget.onMapTap?.call();
      },
      onCameraChange: (NCameraUpdateReason reason, bool animated) {
        // 제스처 → 사용자가 지도를 직접 조작 중 (코드로 옮긴 카메라는 제외)
        if (reason == NCameraUpdateReason.gesture) {
          widget.onCameraGesture?.call();
        }
      },
      onCameraIdle: () async {
        if (widget.onCameraIdle == null) return;
        final NCameraPosition? pos = await _controller?.getCameraPosition();
        if (pos != null) widget.onCameraIdle?.call(pos.target, pos.zoom);
      },
    );
  }
}
