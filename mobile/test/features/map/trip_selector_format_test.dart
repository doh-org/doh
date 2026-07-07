import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:doh/features/map/presentation/widgets/trip_selector_sheet.dart';
import 'package:doh/features/trips/domain/entities/trip.dart';

Trip _trip({DateTime? start, DateTime? end, String? coverColor}) => Trip(
      id: 't1',
      ownerId: 'u1',
      title: '테스트 여행',
      startDate: start,
      endDate: end,
      coverColor: coverColor,
      createdAt: DateTime(2026, 1, 1),
    );

void main() {
  group('formatTripDate', () {
    test('yyyy.MM.dd 0채움', () {
      expect(formatTripDate(DateTime(2026, 7, 5)), '2026.07.05');
    });
    test('null → 빈 문자열', () {
      expect(formatTripDate(null), '');
    });
  });

  group('tripDateRange', () {
    test('양쪽 있음 → "s ~ e"', () {
      expect(
        tripDateRange(_trip(
            start: DateTime(2026, 7, 1), end: DateTime(2026, 7, 3))),
        '2026.07.01 ~ 2026.07.03',
      );
    });
    test('시작만 → 시작만', () {
      expect(tripDateRange(_trip(start: DateTime(2026, 7, 1))), '2026.07.01');
    });
    test('종료만 → 종료만', () {
      expect(tripDateRange(_trip(end: DateTime(2026, 7, 3))), '2026.07.03');
    });
    test('둘 다 없음 → 빈 문자열', () {
      expect(tripDateRange(_trip()), '');
    });
  });

  group('tripCoverColor', () {
    // 커버 팔레트와 동일한 50% 알파(0x80)로 통일 (회귀 방지)
    test('"#FE8505" → 50% 알파 주황', () {
      expect(tripCoverColor(_trip(coverColor: '#FE8505')),
          const Color(0x80FE8505));
    });
    test('null → 기본 회색(50% 알파)', () {
      expect(tripCoverColor(_trip()), const Color(0x80D5D5D5));
    });
    test('잘못된 hex → 기본 회색(50% 알파)', () {
      expect(tripCoverColor(_trip(coverColor: 'not-a-color')),
          const Color(0x80D5D5D5));
    });
  });
}
