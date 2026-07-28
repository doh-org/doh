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

  // 지도 위젯이 사라질 때 호출
  void clearController(NaverMapController controller) {
    if (identical(state, controller)) state = null;
  }

  void moveCamera(NLatLng target, {double zoom = 15}) {
    state?.updateCamera(NCameraUpdate.scrollAndZoomTo(target: target, zoom: zoom));
  }

  // 위치 오버레이 표시·좌표 조회·카메라 따라가기
  void startLocationTracking() {
    state?.setLocationTrackingMode(NLocationTrackingMode.follow);
  }
}

