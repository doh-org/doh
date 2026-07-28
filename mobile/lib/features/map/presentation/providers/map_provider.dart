import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/repositories/map_repository_impl.dart';

part 'map_provider.g.dart';

@riverpod
Future<NLatLng> currentLocation(Ref ref) =>
    ref.watch(mapRepositoryProvider).getCurrentLocation();

@Riverpod(keepAlive: true)
class MapController extends _$MapController {
  @override
  NaverMapController? build() => null;

  void setController(NaverMapController controller) {
    state = controller;
  }

  void moveCamera(NLatLng target, {double zoom = 15}) {
    state?.updateCamera(NCameraUpdate.scrollAndZoomTo(target: target, zoom: zoom));
  }
}

