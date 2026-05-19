import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/repositories/route_repository_impl.dart';
import '../../domain/entities/trip_route.dart';

part 'route_provider.g.dart';

@riverpod
Future<List<TripRoute>> routes(Ref ref, String tripId) =>
    ref.watch(routeRepositoryProvider).getRoutes(tripId);
