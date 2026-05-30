import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/repositories/map_repository.dart';

part 'map_repository_impl.g.dart';

@riverpod
MapRepository mapRepository(Ref ref) => MapRepositoryImpl();

class MapRepositoryImpl implements MapRepository {
  @override
  Future<NLatLng> getCurrentLocation() async {
    final permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return const NLatLng(37.5665, 126.9780);
    }
    final pos = await Geolocator.getCurrentPosition();
    return NLatLng(pos.latitude, pos.longitude);
  }
}
