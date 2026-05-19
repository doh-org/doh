abstract interface class MapRepository {
  Future<({double lat, double lng})> getCurrentLocation();
}
