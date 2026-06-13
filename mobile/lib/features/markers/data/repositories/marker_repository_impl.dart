import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/category.dart';
import '../../domain/entities/marker.dart';
import '../../domain/repositories/marker_repository.dart';
import '../datasources/marker_remote_datasource.dart';
import '../models/category_model.dart';
import '../models/marker_model.dart';

part 'marker_repository_impl.g.dart';

@riverpod
MarkerRepository markerRepository(Ref ref) =>
    MarkerRepositoryImpl(ref.watch(markerRemoteDatasourceProvider));

class MarkerRepositoryImpl implements MarkerRepository {
  const MarkerRepositoryImpl(this._datasource);
  final MarkerRemoteDatasource _datasource;

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
    Map<String, dynamic>? detail,
    required MarkerSource source,
    List<int> visitDays = const [],
  }) async {
    final model = await _datasource.createMarker(tripId, {
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'source': source.name,
      if (categoryId != null) 'category_id': categoryId,
      if (address != null) 'address': address,
      if (memo != null) 'memo': memo,
      'detail': detail ?? <String, dynamic>{},
      'visit_days': visitDays,
    });
    return model.toEntity();
  }

  @override
  Future<TripMarker> updateMarker(
    String tripId,
    String markerId, {
    String? name,
    String? categoryId,
    bool clearCategoryId = false,
    List<int>? visitDays,
    String? memo,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (clearCategoryId) {
      body['category_id'] = null;
    } else if (categoryId != null) {
      body['category_id'] = categoryId;
    }
    if (visitDays != null) body['visit_days'] = visitDays;
    if (memo != null) body['memo'] = memo;
    final model = await _datasource.updateMarker(tripId, markerId, body);
    return model.toEntity();
  }

  @override
  Future<void> deleteMarker(String tripId, String markerId) =>
      _datasource.deleteMarker(tripId, markerId);

  static final Map<String, List<Category>> _categoryCache = {};

  @override
  Future<List<Category>> getCategories(String tripId) async {
    if (_categoryCache.containsKey(tripId)) return _categoryCache[tripId]!;
    final models = await _datasource.getCategories(tripId);
    final result = models.map((m) => m.toEntity()).toList();
    _categoryCache[tripId] = result;
    return result;
  }
}
