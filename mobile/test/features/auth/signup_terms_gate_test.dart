import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:doh/features/auth/domain/entities/user.dart';
import 'package:doh/features/auth/presentation/pages/signup_terms_page.dart';
import 'package:doh/features/auth/presentation/providers/auth_provider.dart';

// authNotifier의 build()가 토큰 저장소(플러그인)를 건드리지 않도록 대체.
// 항상 비로그인(null) 상태 → isLoading이 곧 false가 되어 버튼 게이트만 검증한다.
class _FakeAuthNotifier extends AuthNotifier {
  @override
  Future<User?> build() async => null;
}

Widget _harness() => ProviderScope(
      overrides: [authNotifierProvider.overrideWith(_FakeAuthNotifier.new)],
      child: const MaterialApp(
        home: SignupTermsPage(
          args: SignupCompletionArgs(
            token: 't',
            password: 'Abcd1234',
            nickname: 'nick',
          ),
        ),
      ),
    );

ElevatedButton _submitButton(WidgetTester tester) => tester.widget(
      find.widgetWithText(ElevatedButton, '가입 완료'),
    );

void main() {
  // 회귀: 필수 약관 동의 없이는 가입이 진행되면 안 된다(법적 동의 게이트).
  testWidgets('필수 동의 전에는 가입 버튼 비활성', (WidgetTester tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    expect(_submitButton(tester).onPressed, isNull);
  });

  testWidgets('필수 2개 개별 체크 시에만 버튼 활성', (WidgetTester tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    await tester.tap(find.text('[필수] 서비스 이용약관 동의'));
    await tester.pump();
    // 하나만 체크 → 아직 비활성
    expect(_submitButton(tester).onPressed, isNull);

    await tester.tap(find.text('[필수] 개인정보 수집·이용 동의'));
    await tester.pump();
    // 둘 다 체크 → 활성
    expect(_submitButton(tester).onPressed, isNotNull);
  });

  testWidgets('전체 동의 한 번으로 버튼 활성', (WidgetTester tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    await tester.tap(find.text('약관 전체 동의'));
    await tester.pump();

    expect(_submitButton(tester).onPressed, isNotNull);
  });
}
