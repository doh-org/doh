import 'package:flutter_test/flutter_test.dart';
import 'package:doh/features/share/utils/share_text_parser.dart';

void main() {
  group('parseSharedPlaceName', () {
    test('네이버 표준 형식: 헤더·링크 걷어내고 장소명', () {
      const raw = '[네이버 지도]\n스타벅스 강남점\nhttps://naver.me/xAbC12';
      expect(parseSharedPlaceName(raw), '스타벅스 강남점');
    });

    test('한 줄에 이름+링크 섞여도 이름만', () {
      const raw = '스타벅스 강남점 https://naver.me/xAbC12';
      expect(parseSharedPlaceName(raw), '스타벅스 강남점');
    });

    test('헤더 없이 이름+링크 두 줄', () {
      const raw = '경복궁\nhttps://map.naver.com/v5/entry/place/123';
      expect(parseSharedPlaceName(raw), '경복궁');
    });

    test('링크만 있으면 null', () {
      const raw = 'https://naver.me/xAbC12';
      expect(parseSharedPlaceName(raw), isNull);
    });

    test('빈 문자열이면 null', () {
      expect(parseSharedPlaceName(''), isNull);
    });

    test('앞뒤 공백·빈 줄 무시', () {
      const raw = '\n\n   \n부산 감천문화마을\nhttps://naver.me/zzz';
      expect(parseSharedPlaceName(raw), '부산 감천문화마을');
    });

    test('헤더만 있고 이름 없으면 null', () {
      expect(parseSharedPlaceName('[네이버 지도]'), isNull);
    });

    test('인라인 헤더: 한 줄에 [앱명]+이름 → 헤더만 떼고 이름', () {
      const raw = '[카카오맵] 스타벅스 강남점\nhttps://kko.to/xAbC12';
      expect(parseSharedPlaceName(raw), '스타벅스 강남점');
    });

    test('인라인 헤더+링크 한 줄에 모두 섞여도 이름만', () {
      const raw = '[카카오맵] 경복궁 https://kko.to/xAbC12';
      expect(parseSharedPlaceName(raw), '경복궁');
    });
  });
}
