import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/marker.dart';
import '../../domain/repositories/marker_repository.dart';
import '../datasources/marker_remote_datasource.dart';
import '../models/category_model.dart';
import '../models/marker_model.dart';

part 'marker_repository_impl.g.dart';

@riverpod
MarkerRepository markerRepository(Ref ref) => MarkerRepositoryImpl(
      ref.watch(markerRemoteDatasourceProvider),
      ref.watch(authNotifierProvider).valueOrNull?.id ?? '',
    );

class MarkerRepositoryImpl implements MarkerRepository {
  const MarkerRepositoryImpl(this._datasource, this._userId);
  final MarkerRemoteDatasource _datasource;
  final String _userId;

  @override
  Future<List<TripMarker>> getMarkers(String tripId) async {
    final models = await _datasource.getMarkers(tripId);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<TripMarker> createMarker({
    required String tripId,
    required String name,
    required double latitude,
    required double longitude,
    String? categoryId,
    String? address,
    String? memo,
    required MarkerSource source,
  }) async {
    final model = await _datasource.createMarker({
      'trip_id': tripId,
      'created_by': _userId,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      if (categoryId != null) 'category_id': categoryId,
      if (address != null) 'address': address,
      if (memo != null) 'memo': memo,
      'source': source.name,
    });
    return model.toEntity();
  }

  @override
  Future<TripMarker> updateMarker(String markerId, {
    String? name,
    String? categoryId,
    String? memo,
    DateTime? visitTime,
  }) async {
    final model = await _datasource.updateMarker(markerId, {
      if (name != null) 'name': name,
      if (categoryId != null) 'category_id': categoryId,
      if (memo != null) 'memo': memo,
      if (visitTime != null) 'visit_time': visitTime.toIso8601String(),
    });
    return model.toEntity();
  }

  @override
  Future<void> deleteMarker(String markerId) =>
      _datasource.deleteMarker(markerId);

  @override
  Future<List<Category>> getCategories(String tripId) async {
    final models = await _datasource.getCategories(tripId);
    return models.map((m) => m.toEntity()).toList();
  }
}
