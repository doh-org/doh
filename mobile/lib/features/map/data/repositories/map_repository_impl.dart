import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/repositories/map_repository.dart';

part 'map_repository_impl.g.dart';

@riverpod
MapRepository mapRepository(Ref ref) => MapRepositoryImpl();

class MapRepositoryImpl implements MapRepository {
  @override
  Future<LatLng> getCurrentLocation() async {
    final permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return const LatLng(37.5665, 126.9780); // 서울 기본값
    }

    final pos = await Geolocator.getCurrentPosition();
    return LatLng(pos.latitude, pos.longitude);
  }
}
