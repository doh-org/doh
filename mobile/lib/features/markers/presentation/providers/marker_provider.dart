import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../trips/domain/entities/trip.dart';
import '../../../trips/presentation/providers/trip_provider.dart';
import '../../data/repositories/marker_repository_impl.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/marker.dart';

part 'marker_provider.g.dart';

@riverpod
Future<List<TripMarker>> markerEntities(Ref ref, String tripId) async {
  final Trip trip = await ref.watch(tripDetailNotifierProvider(tripId).future);
  return ref.watch(markerRepositoryProvider).getMarkers(tripId, _dayCount(trip));
}

// trip 기간으로 day 수 산출(날짜 없으면 0=미정만).
int _dayCount(Trip trip) {
  if (trip.startDate == null || trip.endDate == null) return 0;
  return trip.endDate!.difference(trip.startDate!).inDays + 1;
}

@riverpod
Future<List<Category>> categories(Ref ref, String tripId) =>
    ref.watch(markerRepositoryProvider).getCategories(tripId);
