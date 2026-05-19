import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/repositories/map_repository.dart';

part 'map_repository_impl.g.dart';

@riverpod
MapRepository mapRepository(Ref ref) => MapRepositoryImpl();

class MapRepositoryImpl implements MapRepository {
  @override
  Future<({double lat, double lng})> getCurrentLocation() async {
    final permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return (lat: 37.5665, lng: 126.9780);
    }

    final pos = await Geolocator.getCurrentPosition().timeout(
      const Duration(seconds: 5),
      onTimeout: () => Position(
        latitude: 37.5665,
        longitude: 126.9780,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      ),
    );
    return (lat: pos.latitude, lng: pos.longitude);
  }
}
