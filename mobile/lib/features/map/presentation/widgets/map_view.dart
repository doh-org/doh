import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../markers/domain/entities/marker.dart';
import '../providers/map_provider.dart';

class MapView extends ConsumerStatefulWidget {
  const MapView({
    required this.initialLat,
    required this.initialLng,
    required this.markers,
    required this.tripId,
    this.onLongTap,
    super.key,
  });

  final double initialLat;
  final double initialLng;
  final List<TripMarker> markers;
  final String tripId;
  final void Function(double lat, double lng)? onLongTap;

  @override
  ConsumerState<MapView> createState() => _MapViewState();
}

class _MapViewState extends ConsumerState<MapView> {
  NaverMapController? _controller;

  @override
  void didUpdateWidget(MapView old) {
    super.didUpdateWidget(old);
    if (_controller != null && !listEquals(old.markers, widget.markers)) {
      _syncMarkers(widget.markers);
    }
  }

  void _syncMarkers(List<TripMarker> markers) {
    _controller?.clearOverlays();
    for (final m in markers) {
      _controller?.addOverlay(NMarker(id: m.id, position: NLatLng(m.latitude, m.longitude)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return NaverMap(
      options: NaverMapViewOptions(
        initialCameraPosition: NCameraPosition(
          target: NLatLng(widget.initialLat, widget.initialLng),
          zoom: 14,
        ),
      ),
      onMapReady: (controller) {
        _controller = controller;
        ref.read(mapControllerProvider.notifier).setController(controller);
        _syncMarkers(widget.markers);
      },
      onMapLongTapped: (point, latLng) {
        widget.onLongTap?.call(latLng.latitude, latLng.longitude);
      },
    );
  }
}
