import 'package:uuid/uuid.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/storage/guest_store.dart';
import '../../domain/entities/trip.dart';
import '../../domain/repositories/trip_repository.dart';
import '../models/trip_model.dart';

/// 게스트(로그인 없이) 모드의 여행 저장소 — 서버 대신 로컬(GuestStore).
///
/// 직렬화는 서버용 [TripModel]의 JSON을 그대로 재사용한다(게스트/서버 데이터는
/// 섞이지 않으므로 필드명이 같아도 무방, 코드 중복 방지).
/// 서버가 채우던 id·ownerId·createdAt은 여기서 로컬 생성한다.
class TripLocalRepository implements TripRepository {
  TripLocalRepository(this._store);
  final GuestStore _store;

  static const Uuid _uuid = Uuid();
  static const String _ownerId = 'guest'; // 게스트는 서버 유저가 없음

  Future<List<TripModel>> _load() async {
    final objs = await _store.readObjects(GuestStore.tripsKey());
    return objs.map(TripModel.fromJson).toList();
  }

  Future<void> _save(List<TripModel> trips) => _store.writeObjects(
        GuestStore.tripsKey(),
        trips.map((t) => t.toJson()).toList(),
      );

  // 여행 카드의 마커 개수는 로컬 마커 저장분을 세어 채운다.
  Future<Trip> _withMarkerNum(TripModel m) async {
    final markers = await _store.readObjects(GuestStore.markersKey(m.id));
    return m.toEntity().copyWith(markerNum: markers.length);
  }

  @override
  Future<List<Trip>> getTrips() async {
    final models = await _load();
    final List<Trip> trips = [
      for (final m in models) await _withMarkerNum(m),
    ];
    trips.sort((a, b) => b.createdAt.compareTo(a.createdAt)); // 최신순
    return trips;
  }

  @override
  Future<Trip> getTrip(String tripId) async {
    final models = await _load();
    final int i = models.indexWhere((t) => t.id == tripId);
    if (i == -1) throw const NotFoundException();
    return _withMarkerNum(models[i]);
  }

  @override
  Future<Trip> createTrip({
    required String title,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    String? coverColor,
  }) async {
    final models = await _load();
    final TripModel model = TripModel(
      id: _uuid.v4(),
      ownerId: _ownerId,
      title: title,
      description: description,
      startDate: startDate,
      endDate: endDate,
      coverColor: coverColor,
      createdAt: DateTime.now(),
    );
    models.add(model);
    await _save(models);
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
    final models = await _load();
    final int i = models.indexWhere((t) => t.id == tripId);
    if (i == -1) throw const NotFoundException();
    // 미전달(null)=유지 — 원격 updateTrip이 필드 생략으로 유지하는 것과 동일 의미
    final TripModel updated = models[i].copyWith(
      title: title ?? models[i].title,
      description: description ?? models[i].description,
      startDate: startDate ?? models[i].startDate,
      endDate: endDate ?? models[i].endDate,
      coverColor: coverColor ?? models[i].coverColor,
    );
    models[i] = updated;
    await _save(models);
    return updated.toEntity();
  }

  @override
  Future<void> deleteTrip(String tripId) async {
    final models = await _load();
    models.removeWhere((t) => t.id == tripId);
    await _save(models);
    // 딸린 마커·경로 오버라이드도 함께 정리
    await _store.remove(GuestStore.markersKey(tripId));
    await _store.remove(GuestStore.dayStopsKey(tripId));
  }
}
