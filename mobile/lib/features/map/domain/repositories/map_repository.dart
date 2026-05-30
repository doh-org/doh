import 'package:flutter_naver_map/flutter_naver_map.dart';

abstract interface class MapRepository {
  Future<NLatLng> getCurrentLocation();
}
