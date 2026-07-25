import 'package:flutter_naver_map/flutter_naver_map.dart';

abstract interface class MapRepository {
  /// 현위치 조회
  /// OS 권한 거부 시 서울 좌표로 폴백(길찾기 트리거 B)
  Future<NLatLng> getCurrentLocation();

  /// OS 위치 권한 요청하여 허용(항상/사용중)이면 true, 거부면 false.
  /// 권한 거부와 성공을 구별해야 하는 트리거 A(커스텀 현위치 버튼)에서 사용
  Future<bool> requestLocationPermission();

  /// 실제 단말기 좌표
  /// 권한이 이미 허용된 상태를 가정
  Future<NLatLng> getCurrentPosition();

  /// OS 앱 설정 화면을 연다(위치 권한 재허용 유도)
  Future<void> openLocationSettings();
}
