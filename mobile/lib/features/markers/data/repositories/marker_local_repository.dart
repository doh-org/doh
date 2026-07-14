import 'package:uuid/uuid.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/storage/guest_store.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/marker.dart';
import '../../domain/repositories/marker_repository.dart';
import '../models/marker_model.dart';

/// 게스트 모드의 마커 저장소 — 서버 대신 로컬(GuestStore).
/// 카테고리는 서버 조회 대신 고정 기본 5종(식당·카페·관광·숙소·기타)을 준다.
class MarkerLocalRepository implements MarkerRepository {
  MarkerLocalRepository(this._store);
  final GuestStore _store;

  static const Uuid _uuid = Uuid();
  static const String _createdBy = 'guest';

  // 기본 카테고리. id는 안정적 slug — 마커가 참조한 categoryId와 계속 일치해야 함.
  // color는 categoryColor(name)와 동일 팔레트(표시 일관성).
  static const List<({String id, String name, String color})> _defaultCats = [
    (id: 'cat_restaurant', name: '식당', color: '#FE8505'),
    (id: 'cat_cafe', name: '카페', color: '#FFCC00'),
    (id: 'cat_sightseeing', name: '관광', color: '#2A6FDB'),
    (id: 'cat_lodging', name: '숙소', color: '#34C759'),
    (id: 'cat_etc', name: '기타', color: '#8A847B'),
  ];

  Future<List<MarkerModel>> _load(String tripId) async {
    final objs = await _store.readObjects(GuestStore.markersKey(tripId));
    return objs.map(MarkerModel.fromJson).toList();
  }

  Future<void> _save(String tripId, List<MarkerModel> markers) =>
      _store.writeObjects(
        GuestStore.markersKey(tripId),
        markers.map((m) => m.toJson()).toList(),
      );

  @override
  Future<List<TripMarker>> getMarkers(String tripId, int dayCount) async {
    final models = await _load(tripId);
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
    final models = await _load(tripId);
    final MarkerModel model = MarkerModel(
      id: _uuid.v4(),
      tripId: tripId,
      categoryId: categoryId,
      createdBy: _createdBy,
      name: name,
      latitude: latitude,
      longitude: longitude,
      address: address,
      memo: memo,
      source: source.name,
      detail: detail ?? <String, dynamic>{},
      visitDays: visitDays,
      createdAt: DateTime.now(),
    );
    models.add(model);
    await _save(tripId, models);
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
    final models = await _load(tripId);
    final int i = models.indexWhere((m) => m.id == markerId);
    if (i == -1) throw const NotFoundException();
    final MarkerModel cur = models[i];
    // categoryId는 3상태(유지/해제/설정) — freezed copyWith가 명시적 null을
    // 구분 못 하므로 직접 재구성한다.
    models[i] = MarkerModel(
      id: cur.id,
      tripId: cur.tripId,
      categoryId: clearCategoryId ? null : (categoryId ?? cur.categoryId),
      createdBy: cur.createdBy,
      name: name ?? cur.name,
      latitude: cur.latitude,
      longitude: cur.longitude,
      address: cur.address,
      memo: memo ?? cur.memo,
      source: cur.source,
      detail: cur.detail,
      visitDays: visitDays ?? cur.visitDays,
      deletedAt: cur.deletedAt,
      createdAt: cur.createdAt,
    );
    await _save(tripId, models);
    return models[i].toEntity();
  }

  @override
  Future<void> deleteMarker(String tripId, String markerId) async {
    final models = await _load(tripId);
    models.removeWhere((m) => m.id == markerId);
    await _save(tripId, models);
  }

  @override
  Future<List<Category>> getCategories(String tripId) async {
    // 고정 시각(epoch) — 정렬·표시에 영향 없으므로 상수로 둔다.
    final DateTime seedAt = DateTime.fromMillisecondsSinceEpoch(0);
    return [
      for (final c in _defaultCats)
        Category(
          id: c.id,
          tripId: tripId,
          name: c.name,
          color: c.color,
          createdAt: seedAt,
        ),
    ];
  }
}
