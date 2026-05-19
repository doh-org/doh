import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/repositories/map_repository_impl.dart';

part 'map_provider.g.dart';

@riverpod
Future<({double lat, double lng})> currentLocation(Ref ref) =>
    ref.watch(mapRepositoryProvider).getCurrentLocation();

@riverpod
class MapController extends _$MapController {
  @override
  NaverMapController? build() => null;

  void setController(NaverMapController controller) {
    state = controller;
  }

  Future<void> moveCamera(double lat, double lng, {double zoom = 14}) async {
    await state?.updateCamera(
      NCameraUpdate.withParams(
        target: NLatLng(lat, lng),
        zoom: zoom,
      ),
    );
  }
}
