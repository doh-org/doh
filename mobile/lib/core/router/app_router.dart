import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/signup_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/map/presentation/pages/map_page.dart';
import '../../features/trips/presentation/pages/trip_create_page.dart';
import '../../features/trips/presentation/pages/trip_list_page.dart';

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

      if (authState.isLoading) {
        final isAuthOrSplash = loc == '/login' ||
            loc == '/signup' ||
            loc == '/splash';
        return isAuthOrSplash ? null : '/splash';
      }

      final isAuthenticated = authState.valueOrNull != null;
      final isAuthRoute = loc == '/login' || loc == '/signup';

      if (!isAuthenticated && !isAuthRoute) return '/login';
      if (isAuthenticated && isAuthRoute) return '/trips';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupPage(),
      ),
      GoRoute(
        path: '/trips',
        builder: (context, state) => const TripListPage(),
        routes: [
          GoRoute(
            path: 'create',
            builder: (context, state) => const TripCreatePage(),
          ),
          GoRoute(
            path: ':tripId/map',
            builder: (context, state) => MapPage(
              tripId: state.pathParameters['tripId']!,
            ),
          ),
        ],
      ),
    ],
  );

  ref.onDispose(router.dispose);
  return router;
}
