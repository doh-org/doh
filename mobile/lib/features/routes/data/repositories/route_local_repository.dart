import '../../../../core/storage/guest_store.dart';
import '../../../markers/data/models/marker_model.dart';
import '../../domain/entities/route_stop.dart';
import '../../domain/repositories/route_repository.dart';

/// 게스트 모드의 경로(Day stop) 저장소.
///
/// 서버는 마커를 Day별로 정렬·계산해 stop을 내려주지만, 여기서는 로컬 마커에서
/// 파생한다. 순서(order)·방문시간·이동수단만 오버라이드로 저장하고,
/// 거리/시간은 백엔드 Directions 산출값이라 항상 null.
class RouteLocalRepository implements RouteRepository {
  RouteLocalRepository(this._store);
  final GuestStore _store;

  // 해당 여행의 Day별 마커를 읽는다.
  Future<List<MarkerModel>> _markers(String tripId) async {
    final objs = await _store.readObjects(GuestStore.markersKey(tripId));
    return objs.map(MarkerModel.fromJson).toList();
  }

  // (day, markerId)별 오버라이드 원본 리스트.
  Future<List<Map<String, dynamic>>> _overrides(String tripId) =>
      _store.readObjects(GuestStore.dayStopsKey(tripId));

  Future<void> _saveOverrides(
    String tripId,
    List<Map<String, dynamic>> rows,
  ) =>
      _store.writeObjects(GuestStore.dayStopsKey(tripId), rows);

  // Day 필터: 0=미정(방문일 없음), 1↑=해당 Day 포함.
  bool _inDay(MarkerModel m, int day) =>
      day == 0 ? m.visitDays.isEmpty : m.visitDays.contains(day);

  @override
  Future<List<RouteStop>> getDayStops(
    String tripId,
    int day, {
    required RouteSort sort,
  }) async {
    final List<MarkerModel> all = await _markers(tripId);
    // 기준 순서: 생성순(안정적) — 오버라이드가 없을 때의 기본 order
    final List<MarkerModel> inDay = all.where((m) => _inDay(m, day)).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    final List<Map<String, dynamic>> ov = await _overrides(tripId);
    Map<String, dynamic>? row(String markerId) => ov.firstWhere(
          (r) => r['day'] == day && r['marker_id'] == markerId,
          orElse: () => <String, dynamic>{},
        );

    // 마커 → RouteStop (오버라이드 없으면 생성순 인덱스를 order로)
    final List<RouteStop> stops = [
      for (int i = 0; i < inDay.length; i++)
        _toStop(inDay[i], row(inDay[i].id), fallbackOrder: i),
    ];

    // 정렬: 방문시간순(빈 값 뒤로) 또는 order순
    if (sort == RouteSort.visitTime) {
      stops.sort((a, b) => _byVisitTime(a, b));
    } else {
      stops.sort((a, b) => a.order.compareTo(b.order));
    }

    // 표시 order를 0..n-1로 재부여(연속 보장)
    return [
      for (int i = 0; i < stops.length; i++) stops[i].copyWith(order: i),
    ];
  }

  @override
  Future<RouteStop> updateStop(
    String tripId,
    int day,
    String markerId, {
    String? visitTime,
    bool clearVisitTime = false,
    TransportMode? transport,
    bool clearTransport = false,
  }) async {
    final List<Map<String, dynamic>> ov = await _overrides(tripId);
    final int i = ov.indexWhere(
      (r) => r['day'] == day && r['marker_id'] == markerId,
    );
    final Map<String, dynamic> entry = i == -1
        ? <String, dynamic>{'day': day, 'marker_id': markerId}
        : Map<String, dynamic>.from(ov[i]);

    // 3상태: clear=해제(null) / 값=설정 / 미전달=유지
    if (clearVisitTime) {
      entry['visit_time'] = null;
    } else if (visitTime != null) {
      entry['visit_time'] = visitTime;
    }
    if (clearTransport) {
      entry['transport'] = null;
    } else if (transport != null) {
      entry['transport'] = transport.name;
    }

    if (i == -1) {
      ov.add(entry);
    } else {
      ov[i] = entry;
    }
    await _saveOverrides(tripId, ov);

    final MarkerModel m =
        (await _markers(tripId)).firstWhere((m) => m.id == markerId);
    return _toStop(m, entry, fallbackOrder: entry['order'] as int? ?? 0);
  }

  @override
  Future<int> reorder(String tripId, int day, List<String> markerIds) async {
    final List<Map<String, dynamic>> ov = await _overrides(tripId);
    // 전달된 순서대로 order를 0..n-1로 재기록
    for (int i = 0; i < markerIds.length; i++) {
      final int idx = ov.indexWhere(
        (r) => r['day'] == day && r['marker_id'] == markerIds[i],
      );
      if (idx == -1) {
        ov.add({'day': day, 'marker_id': markerIds[i], 'order': i});
      } else {
        ov[idx] = Map<String, dynamic>.from(ov[idx])..['order'] = i;
      }
    }
    await _saveOverrides(tripId, ov);
    return markerIds.length;
  }

  // MarkerModel + 오버라이드 → RouteStop. 거리/시간은 게스트에선 항상 null.
  RouteStop _toStop(
    MarkerModel m,
    Map<String, dynamic>? ov, {
    required int fallbackOrder,
  }) {
    final String? tRaw = ov?['transport'] as String?;
    return RouteStop(
      markerId: m.id,
      name: m.name,
      latitude: m.latitude,
      longitude: m.longitude,
      categoryId: m.categoryId,
      order: (ov?['order'] as int?) ?? fallbackOrder,
      visitTime: ov?['visit_time'] as String?,
      transportToNext: tRaw == null ? null : TransportMode.values.byName(tRaw),
    );
  }

  // 방문시간 오름차순, 빈 값은 뒤로. 동시간은 order로 안정 정렬.
  int _byVisitTime(RouteStop a, RouteStop b) {
    final String? av = a.visitTime;
    final String? bv = b.visitTime;
    if (av == null && bv == null) return a.order.compareTo(b.order);
    if (av == null) return 1; // a 뒤로
    if (bv == null) return -1; // b 뒤로
    final int c = av.compareTo(bv);
    return c != 0 ? c : a.order.compareTo(b.order);
  }
}
