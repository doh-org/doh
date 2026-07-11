import 'package:flutter_test/flutter_test.dart';
import 'package:doh/features/map/presentation/utils/map_navigation.dart';
import 'package:doh/features/routes/domain/entities/route_stop.dart';

void main() {
  test('naverSearchAppUri 한글 주소 인코딩 + appname 포함', () {
    final String uri = naverSearchAppUri('서울 중구 세종대로 110');
    expect(uri, startsWith('nmap://search?query='));
    expect(uri, contains(Uri.encodeQueryComponent('서울 중구 세종대로 110')));
    expect(uri, contains('appname=com.doh.memotrip'));
    // 원문 한글이 그대로 남으면 인코딩 누락
    expect(uri.contains('서울'), isFalse);
  });

  test('naverSearchWebUri 검색어 경로 인코딩', () {
    final String uri = naverSearchWebUri('강남역 2번 출구');
    expect(uri, startsWith('https://map.naver.com/v5/search/'));
    expect(uri, contains(Uri.encodeComponent('강남역 2번 출구')));
  });

  group('resolveMapSearchQuery', () {
    test('기본(검색·심볼): 장소명 우선', () {
      expect(
        resolveMapSearchQuery(
          preferAddress: false,
          name: '강남역',
          address: '서울 강남구 강남대로 396',
        ),
        '강남역',
      );
    });

    test('기본: 이름 비면 주소 폴백', () {
      expect(
        resolveMapSearchQuery(
          preferAddress: false,
          name: '  ',
          address: '서울 강남구 강남대로 396',
        ),
        '서울 강남구 강남대로 396',
      );
    });

    test('롱프레스: 주소 우선', () {
      expect(
        resolveMapSearchQuery(
          preferAddress: true,
          name: '새 장소',
          address: '서울 중구 세종대로 110',
        ),
        '서울 중구 세종대로 110',
      );
    });

    test('롱프레스: 주소 비면 이름 폴백', () {
      expect(
        resolveMapSearchQuery(preferAddress: true, name: '새 장소', address: null),
        '새 장소',
      );
    });

    test('둘 다 없으면 빈 문자열', () {
      expect(
        resolveMapSearchQuery(preferAddress: false, name: '', address: ''),
        '',
      );
    });
  });

  group('카카오맵 URI', () {
    const NavPoint dep = NavPoint(name: '출발지', lat: 37.1, lng: 127.1);
    const NavPoint dest = NavPoint(name: '강남역', lat: 37.5, lng: 127.0);

    test('kakaoSearchAppUri 검색어 인코딩', () {
      final String uri = kakaoSearchAppUri('강남역 2번 출구');
      expect(uri, startsWith('kakaomap://search?q='));
      expect(uri, contains(Uri.encodeQueryComponent('강남역 2번 출구')));
      expect(uri.contains('강남'), isFalse); // 원문 한글 남으면 인코딩 누락
    });

    test('kakaoSearchWebUri 경로 인코딩', () {
      final String uri = kakaoSearchWebUri('강남역');
      expect(uri, startsWith('https://map.kakao.com/link/search/'));
      expect(uri, contains(Uri.encodeComponent('강남역')));
    });

    test('kakaoRouteAppUri 출발지 없으면 ep만', () {
      final String uri = kakaoRouteAppUri(null, dest, TransportMode.car);
      expect(uri, 'kakaomap://route?ep=37.5,127.0&by=CAR');
    });

    test('kakaoRouteAppUri 출발지 있으면 sp 포함', () {
      final String uri = kakaoRouteAppUri(dep, dest, TransportMode.publictransit);
      expect(uri, contains('ep=37.5,127.0'));
      expect(uri, contains('sp=37.1,127.1'));
      expect(uri, contains('by=PUBLICTRANSIT'));
    });

    test('자전거는 카카오 스킴 미지원 → 도보 폴백', () {
      expect(kakaoRouteBy(TransportMode.bicycle), 'FOOT');
      expect(kakaoRouteBy(TransportMode.foot), 'FOOT');
    });

    test('kakaoRouteWebUri 출발지 유무 분기', () {
      expect(
        kakaoRouteWebUri(null, dest),
        'https://map.kakao.com/link/to/${Uri.encodeComponent('강남역')},37.5,127.0',
      );
      expect(
        kakaoRouteWebUri(dep, dest),
        contains('/link/from/${Uri.encodeComponent('출발지')},37.1,127.1'
            '/to/${Uri.encodeComponent('강남역')},37.5,127.0'),
      );
    });
  });
}
