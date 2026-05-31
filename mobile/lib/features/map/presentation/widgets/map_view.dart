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
    super.key,
  });

  final NLatLng initialLocation;
  final String tripId;

  @override
  ConsumerState<MapView> createState() => _MapViewState();
}

class _MapViewState extends ConsumerState<MapView> {
  NaverMapController? _controller;

  void _updateOverlays(List<TripMarker> markers) {
    final ctrl = _controller;
    if (ctrl == null) return;
    ctrl.clearOverlays();
    if (markers.isNotEmpty) {
      ctrl.addOverlayAll(
        markers
            .map((m) => NMarker(id: m.id, position: NLatLng(m.latitude, m.longitude)))
            .toSet(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(markerEntitiesProvider(widget.tripId), (_, next) {
      _updateOverlays(next.valueOrNull ?? []);
    });

    return NaverMap(
      options: NaverMapViewOptions(
        initialCameraPosition: NCameraPosition(
          target: widget.initialLocation,
          zoom: 14,
        ),
        locationButtonEnable: true,
      ),
      onMapReady: (controller) {
        _controller = controller;
        ref.read(mapControllerProvider.notifier).setController(controller);
        final markers =
            ref.read(markerEntitiesProvider(widget.tripId)).valueOrNull ?? [];
        _updateOverlays(markers);
      },
      onMapTapped: (_, __) {},
    );
  }
}
