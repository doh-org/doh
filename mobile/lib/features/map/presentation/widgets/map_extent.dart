import 'dart:math';
import 'dart:ui' show Size;

import 'package:flutter_naver_map/flutter_naver_map.dart';

/// 카메라 대상 지점을 국내로 묶는 영역 — 네이버 SDK EXTENT_KOREA와 동일
const NLatLngBounds koreaExtent = NLatLngBounds(
  southWest: NLatLng(31.43, 122.37),
  northEast: NLatLng(44.35, 132.0),
);

/// 줌 z에서 월드 한 변의 길이 = 256dp * 2^z
const double _worldTileSizeDp = 256;

/// 위도(도)를 웹 메르카토르 y(북극 0 ~ 남극 1)로 변환
double _mercatorY(double latitude) {
  final double rad = latitude * pi / 180;
  return (1 - log(tan(rad) + 1 / cos(rad)) / pi) / 2;
}

/// bounds가 viewport(dp)를 회전각과 무관하게 덮는 최소 줌 레벨을 반환
/// 회전한 뷰포트를 감싸는 축정렬 사각형의 최대 변 = 대각선 √(w² + h²)
double minZoomToCover(NLatLngBounds bounds, Size viewport) {
  final double diagonal =
      sqrt(viewport.width * viewport.width + viewport.height * viewport.height);
  final double spanX =
      (bounds.northEast.longitude - bounds.southWest.longitude) / 360;
  final double spanY = _mercatorY(bounds.southWest.latitude) -
      _mercatorY(bounds.northEast.latitude);
  if (diagonal <= 0 || spanX <= 0 || spanY <= 0) {
    return NaverMapViewOptions.minimumZoom;
  }
  final double zoomX = log(diagonal / (_worldTileSizeDp * spanX)) / ln2;
  final double zoomY = log(diagonal / (_worldTileSizeDp * spanY)) / ln2;
  return max(zoomX, zoomY).clamp(
    NaverMapViewOptions.minimumZoom,
    NaverMapViewOptions.maximumZoom,
  );
}
