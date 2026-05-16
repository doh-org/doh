import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/repositories/map_repository_impl.dart';
import '../../domain/repositories/map_repository.dart';

part 'map_provider.g.dart';

@riverpod
Future<LatLng> currentLocation(Ref ref) =>
    ref.watch(mapRepositoryProvider).getCurrentLocation();

@riverpod
class MapController extends _$MapController {
  @override
  GoogleMapController? build() => null;

  void setController(GoogleMapController controller) {
    state = controller;
  }

  void moveCamera(LatLng target, {double zoom = 15}) {
    state?.animateCamera(CameraUpdate.newLatLngZoom(target, zoom));
  }
}
