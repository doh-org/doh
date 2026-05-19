import 'package:doh/features/auth/presentation/pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => ProviderScope(child: MaterialApp(home: child));

void main() {
  group('LoginPage', () {
    testWidgets('이메일·비밀번호 필드와 로그인 버튼이 표시된다', (tester) async {
      await tester.pumpWidget(_wrap(const LoginPage()));
      await tester.pumpAndSettle();

      expect(find.text('이메일'), findsOneWidget);
      expect(find.text('비밀번호'), findsOneWidget);
      expect(find.text('로그인'), findsOneWidget);
      expect(find.text('닉네임'), findsNothing);
    });

    testWidgets('회원가입 토글 시 닉네임 필드가 나타난다', (tester) async {
      await tester.pumpWidget(_wrap(const LoginPage()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('계정이 없어요'));
      await tester.pump();

      expect(find.text('닉네임'), findsOneWidget);
      expect(find.text('회원가입'), findsOneWidget);
      expect(find.text('이미 계정이 있어요'), findsOneWidget);
    });

    testWidgets('빈 폼 제출 시 유효성 에러가 표시된다', (tester) async {
      await tester.pumpWidget(_wrap(const LoginPage()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('로그인'));
      await tester.pump();

      expect(find.text('올바른 이메일을 입력해주세요.'), findsOneWidget);
    });

    testWidgets('6자 미만 비밀번호 입력 시 에러가 표시된다', (tester) async {
      await tester.pumpWidget(_wrap(const LoginPage()));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, '이메일'),
        'test@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, '비밀번호'),
        '123',
      );
      await tester.tap(find.text('로그인'));
      await tester.pump();

      expect(find.text('6자 이상 입력해주세요.'), findsOneWidget);
    });
  });
}
