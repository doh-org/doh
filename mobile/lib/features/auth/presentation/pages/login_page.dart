import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../widgets/kakao_login_button.dart';

class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<dynamic>>(authNotifierProvider, (_, next) {
      if (next is AsyncData && next.value != null) {
        context.go('/trips');
      }
    });

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const FlutterLogo(size: 80),
            const SizedBox(height: 48),
            KakaoLoginButton(
              onPressed: () =>
                  ref.read(authNotifierProvider.notifier).loginWithKakao(),
            ),
          ],
        ),
      ),
    );
  }
}
