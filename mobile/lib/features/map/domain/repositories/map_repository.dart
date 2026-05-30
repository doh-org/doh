import 'package:google_maps_flutter/google_maps_flutter.dart';

abstract interface class MapRepository {
  Future<LatLng> getCurrentLocation();
}
