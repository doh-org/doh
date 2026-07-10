import 'package:flutter_test/flutter_test.dart';
import 'package:doh/features/map/presentation/utils/map_navigation.dart';

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

  group('resolveNaverSearchQuery', () {
    test('기본(검색·심볼): 장소명 우선', () {
      expect(
        resolveNaverSearchQuery(
          preferAddress: false,
          name: '강남역',
          address: '서울 강남구 강남대로 396',
        ),
        '강남역',
      );
    });

    test('기본: 이름 비면 주소 폴백', () {
      expect(
        resolveNaverSearchQuery(
          preferAddress: false,
          name: '  ',
          address: '서울 강남구 강남대로 396',
        ),
        '서울 강남구 강남대로 396',
      );
    });

    test('롱프레스: 주소 우선', () {
      expect(
        resolveNaverSearchQuery(
          preferAddress: true,
          name: '새 장소',
          address: '서울 중구 세종대로 110',
        ),
        '서울 중구 세종대로 110',
      );
    });

    test('롱프레스: 주소 비면 이름 폴백', () {
      expect(
        resolveNaverSearchQuery(preferAddress: true, name: '새 장소', address: null),
        '새 장소',
      );
    });

    test('둘 다 없으면 빈 문자열', () {
      expect(
        resolveNaverSearchQuery(preferAddress: false, name: '', address: ''),
        '',
      );
    });
  });
}
