import 'package:flutter_test/flutter_test.dart';

import 'package:doh/features/map/domain/entities/place.dart';

void main() {
  group('Place.fromJson', () {
    test('number 좌표를 double로 파싱', () {
      final Place p = Place.fromJson({
        'provider': 'naver',
        'title': '버거킹 강남점',
        'category': '음식점>햄버거',
        'address': '서울 강남구 역삼동 858',
        'roadAddress': '서울 강남구 강남대로 396',
        'telephone': '02-123-4567',
        'link': '',
        'mapx': 127.0276,
        'mapy': 37.4979,
      });
      expect(p.longitude, 127.0276);
      expect(p.latitude, 37.4979);
      expect(p.title, '버거킹 강남점');
      expect(p.telephone, '02-123-4567');
    });

    test('roadAddress 우선, 없으면 address로 fallback', () {
      final Place road = Place.fromJson({
        'title': 'A',
        'category': '',
        'address': '지번',
        'roadAddress': '도로명',
        'mapx': 1.0,
        'mapy': 2.0,
      });
      expect(road.address, '도로명');

      final Place jibun = Place.fromJson({
        'title': 'A',
        'category': '',
        'address': '지번',
        'roadAddress': '',
        'mapx': 1.0,
        'mapy': 2.0,
      });
      expect(jibun.address, '지번');
    });

    test('category 마지막 세그먼트, 빈값은 기타', () {
      final Place p = Place.fromJson({
        'title': 'A',
        'category': '음식점>카페>디저트카페',
        'address': '',
        'roadAddress': '',
        'mapx': 1.0,
        'mapy': 2.0,
      });
      expect(p.category, '디저트카페');
      expect(p.categoryPath, '음식점>카페>디저트카페');

      final Place empty = Place.fromJson({
        'title': 'A',
        'category': '',
        'address': '',
        'roadAddress': '',
        'mapx': 1.0,
        'mapy': 2.0,
      });
      expect(empty.category, '기타');
    });

    test('카카오형 데이터도 동일 파싱', () {
      final Place p = Place.fromJson({
        'provider': 'kakao',
        'title': '스타벅스 강남점',
        'category': '음식점>카페>커피전문점',
        'address': '서울 강남구 역삼동 1',
        'roadAddress': '서울 강남구 테헤란로 1',
        'telephone': '',
        'link': 'http://place.map.kakao.com/123',
        'mapx': 127.03,
        'mapy': 37.49,
      });
      expect(p.title, '스타벅스 강남점');
      expect(p.category, '커피전문점');
      expect(p.longitude, 127.03);
      expect(p.telephone, '');
    });
  });

  test('toDetail은 무접두 키로 저장', () {
    const Place p = Place(
      title: 'A',
      category: '카페',
      categoryPath: '음식점>카페',
      address: '주소',
      latitude: 37.0,
      longitude: 127.0,
      telephone: '02-1',
    );
    expect(p.toDetail(), {
      'category': '카페',
      'category_path': '음식점>카페',
      'address': '주소',
      'phone': '02-1',
    });
  });
}
