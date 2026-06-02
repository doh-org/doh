import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../markers/domain/entities/marker.dart';
import '../../../markers/presentation/providers/marker_provider.dart';
import '../providers/map_provider.dart';

class MapView extends ConsumerStatefulWidget {
  const MapView({
    required this.initialLocation,
    required this.tripId,
    this.onMarkerTap,
    this.onLongTap,
    this.bottomPeekFraction = 0.0,
    super.key,
  });

  final NLatLng initialLocation;
  final String tripId;
  final void Function(TripMarker)? onMarkerTap;
  final void Function(NLatLng)? onLongTap;
  final double bottomPeekFraction;

  @override
  ConsumerState<MapView> createState() => _MapViewState();
}

class _MapViewState extends ConsumerState<MapView> {
  NaverMapController? _controller;

  Color _categoryColor(TripMarker m) {
    final cat = (m.detail['naver_category'] as String? ?? '').toLowerCase();
    if (cat.contains('카페') || cat.contains('cafe')) {
      return const Color(0x80FE8505);
    }
    if (cat.contains('식당') || cat.contains('음식') || cat.contains('한식') ||
        cat.contains('일식') || cat.contains('양식')) {
      return const Color(0x802A6FDB);
    }
    if (cat.contains('관광') || cat.contains('명소')) {
      return const Color(0x804CAF50);
    }
    if (cat.contains('숙소') || cat.contains('호텔') || cat.contains('펜션')) {
      return const Color(0x809C27B0);
    }
    return const Color(0x808A847B);
  }

  Future<NOverlayImage> _markerIcon(TripMarker m) async {
    final color = _categoryColor(m);
    return NOverlayImage.fromWidget(
      widget: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: const Icon(Icons.place, size: 18, color: Colors.white),
      ),
      size: const Size(36, 36),
      context: context,
    );
  }

  Future<void> _updateOverlays(List<TripMarker> markers) async {
    final ctrl = _controller;
    if (ctrl == null) return;
    ctrl.clearOverlays();
    await Future.wait(markers.map((m) async {
      final icon = await _markerIcon(m);
      final nMarker = NMarker(
        id: m.id,
        position: NLatLng(m.latitude, m.longitude),
      )
        ..setIcon(icon)
        ..setCaption(NOverlayCaption(
          text: m.name,
          textSize: 11,
          color: const Color(0xFF1F2125),
          haloColor: Colors.white,
        ));
      nMarker.setOnTapListener((_) {
        widget.onMarkerTap?.call(m);
        return true;
      });
      await ctrl.addOverlay(nMarker);
    }));
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(markerEntitiesProvider(widget.tripId), (_, next) {
      _updateOverlays(next.valueOrNull ?? []);
    });

    final screenHeight = MediaQuery.sizeOf(context).height;
    return NaverMap(
      options: NaverMapViewOptions(
        initialCameraPosition: NCameraPosition(
          target: widget.initialLocation,
          zoom: 14,
        ),
        locationButtonEnable: true,
        contentPadding: EdgeInsets.only(
          bottom: screenHeight * widget.bottomPeekFraction,
        ),
      ),
      onMapReady: (controller) async {
        _controller = controller;
        ref.read(mapControllerProvider.notifier).setController(controller);
        final markers =
            ref.read(markerEntitiesProvider(widget.tripId)).valueOrNull ?? [];
        await _updateOverlays(markers);
      },
      onMapLongTapped: (point, coord) => widget.onLongTap?.call(coord),
      onMapTapped: (_, __) {},
    );
  }
}
