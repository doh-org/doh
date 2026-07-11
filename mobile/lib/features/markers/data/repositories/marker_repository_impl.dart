import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/auth/guest_mode_provider.dart';
import '../../../../core/storage/guest_store.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/marker.dart';
import '../../domain/repositories/marker_repository.dart';
import '../datasources/marker_remote_datasource.dart';
import '../models/category_model.dart';
import '../models/marker_model.dart';
import 'marker_local_repository.dart';

part 'marker_repository_impl.g.dart';

// 게스트면 로컬 저장소, 아니면 기존 원격 구현.
@riverpod
MarkerRepository markerRepository(Ref ref) => ref.watch(guestModeProvider)
    ? MarkerLocalRepository(ref.watch(guestStoreProvider))
    : MarkerRepositoryImpl(ref.watch(markerRemoteDatasourceProvider));

class MarkerRepositoryImpl implements MarkerRepository {
  const MarkerRepositoryImpl(this._datasource);
  final MarkerRemoteDatasource _datasource;

  // 전체 마커 캐시(tripId별). 변이 시 무효화.
  static final Map<String, List<TripMarker>> _markersCache = {};

  @override
  Future<List<TripMarker>> getMarkers(String tripId, int dayCount) async {
    final List<TripMarker>? cached = _markersCache[tripId];
    if (cached != null) return cached;

    // 미정(0)+각 day(1..dayCount) 병렬 조회 후 id로 중복 제거.
    final List<List<MarkerModel>> lists = await Future.wait([
      for (int d = 0; d <= dayCount; d++) _datasource.getMarkersByDay(tripId, d),
    ]);
    final Map<String, TripMarker> byId = {};
    for (final List<MarkerModel> list in lists) {
      for (final MarkerModel m in list) {
        byId.putIfAbsent(m.id, () => m.toEntity());
      }
    }
    final List<TripMarker> result = byId.values.toList();
    _markersCache[tripId] = result;
    return result;
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
    _markersCache.remove(tripId);
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
    _markersCache.remove(tripId);
    return model.toEntity();
  }

  @override
  Future<void> deleteMarker(String tripId, String markerId) async {
    await _datasource.deleteMarker(tripId, markerId);
    _markersCache.remove(tripId);
  }

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
