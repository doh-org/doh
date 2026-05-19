import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/repositories/trip_repository_impl.dart';
import '../../domain/entities/trip.dart';
import '../../domain/repositories/trip_repository.dart';

part 'trip_provider.g.dart';

@riverpod
Future<List<Trip>> trips(Ref ref) =>
    ref.watch(tripRepositoryProvider).getTrips();

@riverpod
class TripDetailNotifier extends _$TripDetailNotifier {
  @override
  Future<Trip> build(String tripId) =>
      ref.watch(tripRepositoryProvider).getTrip(tripId);
}
