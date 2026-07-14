import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/auth/guest_mode_provider.dart';
import '../../../../core/storage/guest_store.dart';
import '../../domain/entities/trip.dart';
import '../../domain/repositories/trip_repository.dart';
import '../datasources/trip_remote_datasource.dart';
import '../models/trip_model.dart';
import 'trip_local_repository.dart';

part 'trip_repository_impl.g.dart';

// 게스트면 로컬 저장소, 아니면 기존 원격 구현. (도메인 인터페이스가 같아 UI 무변경)
@riverpod
TripRepository tripRepository(Ref ref) => ref.watch(guestModeProvider)
    ? TripLocalRepository(ref.watch(guestStoreProvider))
    : TripRepositoryImpl(ref.watch(tripRemoteDatasourceProvider));

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
    String? coverColor,
  }) async {
    final model = await _datasource.createTrip({
      'title': title,
      if (description != null) 'description': description,
      if (startDate != null) 'start_date': _formatDate(startDate),
      if (endDate != null) 'end_date': _formatDate(endDate),
      if (coverColor != null) 'cover_color': coverColor,
    });
    return model.toEntity();
  }

  @override
  Future<Trip> updateTrip(
    String tripId, {
    String? title,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    String? coverColor,
  }) async {
    final model = await _datasource.updateTrip(tripId, {
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (startDate != null) 'start_date': _formatDate(startDate),
      if (endDate != null) 'end_date': _formatDate(endDate),
      if (coverColor != null) 'cover_color': coverColor,
    });
    return model.toEntity();
  }

  @override
  Future<void> deleteTrip(String tripId) => _datasource.deleteTrip(tripId);

  String _formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
