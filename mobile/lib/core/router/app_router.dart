import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/auth/presentation/pages/account_info_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/password_reset_request_page.dart';
import '../../features/auth/presentation/pages/password_reset_verify_page.dart';
import '../../features/auth/presentation/pages/signup_page.dart';
import '../../features/auth/presentation/pages/signup_terms_page.dart';
import '../../features/auth/presentation/pages/signup_verify_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../auth/guest_mode_provider.dart';
import '../../features/map/presentation/pages/map_page.dart';
import '../../features/share/presentation/pages/share_place_page.dart';
import '../../features/trips/presentation/pages/trip_create_page.dart';
import '../../features/trips/presentation/pages/trip_list_page.dart';
import '../../shared/widgets/bottom_nav_bar.dart';

part 'app_router.g.dart';

@riverpod
GoRouter appRouter(Ref ref) {
  final notifier = ValueNotifier(0);
  ref.listen(authNotifierProvider, (_, __) => notifier.value++);
  // 게스트 진입/해제도 redirect를 다시 태워야 하므로 함께 구독
  ref.listen(guestModeProvider, (_, __) => notifier.value++);
  ref.onDispose(notifier.dispose);

  final router = GoRouter(
    initialLocation: '/splash',
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(authNotifierProvider);
      final loc = state.matchedLocation;

      // 비로그인 상태로 접근 가능한 화면 (회원가입 코드 인증·비밀번호 찾기 포함)
      final isAuthRoute = loc == '/login' ||
          loc.startsWith('/signup') ||
          loc.startsWith('/password-reset');

      if (authState.isLoading) {
        final isAuthOrSplash = isAuthRoute || loc == '/splash';
        return isAuthOrSplash ? null : '/splash';
      }

      final isAuthenticated = authState.valueOrNull != null;
      final isGuest = ref.read(guestModeProvider);
      // 로그인 또는 게스트면 앱 진입 가능
      final canEnter = isAuthenticated || isGuest;

      // 온보딩 끝(로딩 완료) → 상태에 맞는 홈으로 스플래시에서 내보낸다.
      if (loc == '/splash') return canEnter ? '/trips' : '/login';

      if (!canEnter && !isAuthRoute) return '/login';
      // 로그인 사용자만 auth 화면에서 홈으로 (게스트는 /login 접근 가능해야 함)
      if (isAuthenticated && isAuthRoute) return '/trips';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (_, __) => const SplashPage(),
      ),
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginPage(),
      ),
      GoRoute(
        path: '/signup',
        builder: (_, __) => const SignupPage(),
      ),
      GoRoute(
        path: '/signup/verify',
        // extra로 1단계 이메일을 받고 없이 직접 진입하면 1단계부터
        builder: (_, state) {
          final String? email = state.extra as String?;
          return email == null
              ? const SignupPage()
              : SignupVerifyPage(email: email);
        },
      ),
      GoRoute(
        path: '/signup/terms',
        // extra로 앞 단계의 가입 확정 값(토큰·비번·닉네임)을 받고 없이 직접 진입하면 1단계부터
        builder: (_, state) {
          final Object? args = state.extra;
          return args is SignupCompletionArgs
              ? SignupTermsPage(args: args)
              : const SignupPage();
        },
      ),
      GoRoute(
        path: '/password-reset',
        builder: (_, __) => const PasswordResetRequestPage(),
      ),
      GoRoute(
        path: '/password-reset/verify',
        builder: (_, state) {
          final String? email = state.extra as String?;
          return email == null
              ? const PasswordResetRequestPage()
              : PasswordResetVerifyPage(email: email);
        },
      ),
      // 탭바 공유 shell (목록만)
      ShellRoute(
        builder: (_, __, child) => Scaffold(
          backgroundColor: Colors.white,
          body: child,
          bottomNavigationBar: const BottomNavBar(currentIndex: 1),
        ),
        routes: [
          GoRoute(
            path: '/trips',
            builder: (_, __) => const TripListPage(),
          ),
        ],
      ),
      // 탭바 없는 독립 화면
      GoRoute(
        path: '/account',
        builder: (_, __) => const AccountInfoPage(),
      ),
      // 외부 앱 공유 수신 → 담을 여행 선택 (비로그인은 redirect가 /login으로)
      GoRoute(
        path: '/share',
        builder: (_, __) => const SharePlacePage(),
      ),
      GoRoute(
        path: '/trips/create',
        builder: (_, __) => const TripCreatePage(),
      ),
      GoRoute(
        path: '/trips/:tripId/edit',
        builder: (_, state) => TripCreatePage(
          tripId: state.pathParameters['tripId'],
        ),
      ),
      GoRoute(
        path: '/trips/:tripId/map',
        builder: (_, state) => MapPage(
          tripId: state.pathParameters['tripId']!,
        ),
      ),
    ],
  );

  ref.onDispose(router.dispose);
  return router;
}
