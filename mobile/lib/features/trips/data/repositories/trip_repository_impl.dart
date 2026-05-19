import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/config/app_config.dart';
import '../../domain/entities/trip.dart';
import '../../domain/repositories/trip_repository.dart';
import '../datasources/trip_remote_datasource.dart';
import '../models/trip_model.dart';

part 'trip_repository_impl.g.dart';

@riverpod
TripRepository tripRepository(Ref ref) =>
    TripRepositoryImpl(ref.watch(tripRemoteDatasourceProvider));

class TripRepositoryImpl implements TripRepository {
  const TripRepositoryImpl(this._datasource);
  final TripRemoteDatasource _datasource;

  @override
  Future<List<Trip>> getTrips() async {
    final models = await _datasource.getTrips();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<Trip> getTrip(String tripId) async {
    final model = await _datasource.getTrip(tripId);
    return model.toEntity();
  }

  @override
  Future<Trip> createTrip({
    required String title,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final ownerId = Supabase.instance.client.auth.currentUser?.id ?? AppConfig.devUserId;
    final model = await _datasource.createTrip({
      'owner_id': ownerId,
      'title': title,
      if (description != null) 'description': description,
      if (startDate != null) 'start_date': startDate.toIso8601String(),
      if (endDate != null) 'end_date': endDate.toIso8601String(),
    });
    return model.toEntity();
  }

  @override
  Future<Trip> updateTrip(String tripId, {
    String? title,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final model = await _datasource.updateTrip(tripId, {
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (startDate != null) 'start_date': startDate.toIso8601String(),
      if (endDate != null) 'end_date': endDate.toIso8601String(),
    });
    return model.toEntity();
  }

  @override
  Future<void> deleteTrip(String tripId) => _datasource.deleteTrip(tripId);
}
