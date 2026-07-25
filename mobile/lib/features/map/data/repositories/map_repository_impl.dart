import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/repositories/map_repository.dart';

part 'map_repository_impl.g.dart';

@riverpod
MapRepository mapRepository(Ref ref) => MapRepositoryImpl();

class MapRepositoryImpl implements MapRepository {
  // OS 권한 거부 시 폴백 좌표(서울 시청). 기존 트리거 B 동작 유지용.
  static const NLatLng _seoulFallback = NLatLng(37.5665, 126.9780);

  @override
  Future<NLatLng> getCurrentLocation() async {
    // 권한 요청 → 거부면 서울 폴백, 허용이면 실제 좌표
    if (!await requestLocationPermission()) return _seoulFallback;
    return getCurrentPosition();
  }

  @override
  Future<bool> requestLocationPermission() async {
    final LocationPermission permission = await Geolocator.requestPermission();
    // 항상/사용중 허용만 true, denied·deniedForever는 false
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  @override
  Future<NLatLng> getCurrentPosition() async {
    final Position pos = await Geolocator.getCurrentPosition();
    return NLatLng(pos.latitude, pos.longitude);
  }

  @override
  Future<void> openLocationSettings() => Geolocator.openAppSettings();
}
