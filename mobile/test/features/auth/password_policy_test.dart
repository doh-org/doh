import 'package:flutter_test/flutter_test.dart';

import 'package:doh/features/auth/utils/password_policy.dart';

void main() {
  group('isValidPassword', () {
    test('유효: 8자 + 대·소문자·숫자', () {
      expect(isValidPassword('Test1234'), isTrue);
    });

    test('유효: 특수문자 포함', () {
      expect(isValidPassword('Test1234!@#'), isTrue);
    });

    test('거부: 7자', () {
      expect(isValidPassword('Test123'), isFalse);
    });

    test('거부: 대문자 없음', () {
      expect(isValidPassword('test1234'), isFalse);
    });

    test('거부: 소문자 없음', () {
      expect(isValidPassword('TEST1234'), isFalse);
    });

    test('거부: 숫자 없음', () {
      expect(isValidPassword('TestPass'), isFalse);
    });

    test('거부: 한글 포함 (화이트리스트 외)', () {
      expect(isValidPassword('가가가Ab1cd'), isFalse);
    });

    test('거부: 공백 포함', () {
      expect(isValidPassword('Test 1234'), isFalse);
    });
  });
}
