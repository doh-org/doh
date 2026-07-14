import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/auth/guest_mode_provider.dart';
import '../../../../core/storage/guest_store.dart';
import '../../domain/entities/route_stop.dart';
import '../../domain/repositories/route_repository.dart';
import '../datasources/route_remote_datasource.dart';
import '../models/route_stop_model.dart';
import 'route_local_repository.dart';

part 'route_repository_impl.g.dart';

// 게스트면 로컬 저장소(마커에서 파생), 아니면 기존 원격 구현.
@riverpod
RouteRepository routeRepository(Ref ref) => ref.watch(guestModeProvider)
    ? RouteLocalRepository(ref.watch(guestStoreProvider))
    : RouteRepositoryImpl(ref.watch(routeRemoteDatasourceProvider));

class RouteRepositoryImpl implements RouteRepository {
  const RouteRepositoryImpl(this._datasource);
  final RouteRemoteDatasource _datasource;

  @override
  Future<List<RouteStop>> getDayStops(
    String tripId,
    int day, {
    required RouteSort sort,
  }) async {
    final models = await _datasource.getDayStops(tripId, day, sort: sort.query);
    return models.map((m) => m.toEntity()).toList();
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
    final body = <String, dynamic>{};
    if (clearVisitTime) {
      body['visit_time'] = null;
    } else if (visitTime != null) {
      body['visit_time'] = visitTime;
    }
    if (clearTransport) {
      body['transport_to_next'] = null;
    } else if (transport != null) {
      body['transport_to_next'] = transport.name;
    }
    final model = await _datasource.updateStop(tripId, day, markerId, body);
    return model.toEntity();
  }

  @override
  Future<int> reorder(String tripId, int day, List<String> markerIds) =>
      _datasource.reorder(tripId, day, markerIds);
}
