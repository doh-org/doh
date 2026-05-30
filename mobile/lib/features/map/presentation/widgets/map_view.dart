import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../providers/map_provider.dart';

class MapView extends ConsumerWidget {
  const MapView({
    required this.initialLocation,
    required this.markers,
    required this.tripId,
    super.key,
  });

  final LatLng initialLocation;
  final Set<Marker> markers;
  final String tripId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: initialLocation,
        zoom: 14,
      ),
      markers: markers,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      onMapCreated: (controller) =>
          ref.read(mapControllerProvider.notifier).setController(controller),
      onLongPress: (latLng) {
        // TODO: 롱프레스 마커 생성
      },
    );
  }
}
