import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/auth/presentation/pages/account_info_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/password_reset_request_page.dart';
import '../../features/auth/presentation/pages/password_reset_verify_page.dart';
import '../../features/auth/presentation/pages/signup_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/map/presentation/pages/map_page.dart';
import '../../features/trips/presentation/pages/trip_create_page.dart';
import '../../features/trips/presentation/pages/trip_list_page.dart';
import '../../shared/widgets/bottom_nav_bar.dart';

part 'app_router.g.dart';

@riverpod
GoRouter appRouter(Ref ref) {
  final notifier = ValueNotifier(0);
  ref.listen(authNotifierProvider, (_, __) => notifier.value++);
  ref.onDispose(notifier.dispose);

  final router = GoRouter(
    initialLocation: '/login',
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(authNotifierProvider);
      final loc = state.matchedLocation;

      // 비로그인 상태로 접근 가능한 화면 (비밀번호 찾기 포함)
      final isAuthRoute = loc == '/login' ||
          loc == '/signup' ||
          loc.startsWith('/password-reset');

      if (authState.isLoading) {
        final isAuthOrSplash = isAuthRoute || loc == '/splash';
        return isAuthOrSplash ? null : '/splash';
      }

      final isAuthenticated = authState.valueOrNull != null;

      if (!isAuthenticated && !isAuthRoute) return '/login';
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
        path: '/password-reset',
        builder: (_, __) => const PasswordResetRequestPage(),
      ),
      GoRoute(
        path: '/password-reset/verify',
        // extra로 1단계 이메일을 받는다. 없이 직접 진입하면 1단계부터.
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
