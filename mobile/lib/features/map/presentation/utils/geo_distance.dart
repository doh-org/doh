import 'dart:math';

// 두 좌표 사이 거리(m). 하버사인 공식 — 지구를 구로 근사.
double haversineMeters(double lat1, double lon1, double lat2, double lon2) {
  const double r = 6371000; // 지구 반지름(m)
  final double dLat = (lat2 - lat1) * pi / 180;
  final double dLon = (lon2 - lon1) * pi / 180;
  final double a = sin(dLat / 2) * sin(dLat / 2) +
      cos(lat1 * pi / 180) *
          cos(lat2 * pi / 180) *
          sin(dLon / 2) *
          sin(dLon / 2);
  return r * 2 * atan2(sqrt(a), sqrt(1 - a));
}
