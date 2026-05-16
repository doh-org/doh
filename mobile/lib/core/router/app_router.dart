import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/map/presentation/pages/map_page.dart';
import '../../features/trips/presentation/pages/trip_create_page.dart';
import '../../features/trips/presentation/pages/trip_list_page.dart';

part 'app_router.g.dart';

@riverpod
GoRouter appRouter(Ref ref) {
  return GoRouter(
    initialLocation: '/trips',
    redirect: (context, state) {
      // TODO: 인증 상태 확인 후 리다이렉트
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
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
}
