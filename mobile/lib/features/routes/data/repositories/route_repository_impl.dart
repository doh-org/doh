import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/trip_route.dart';
import '../../domain/repositories/route_repository.dart';
import '../datasources/route_remote_datasource.dart';
import '../models/route_model.dart';

part 'route_repository_impl.g.dart';

@riverpod
RouteRepository routeRepository(Ref ref) => RouteRepositoryImpl(
      ref.watch(routeRemoteDatasourceProvider),
      ref.watch(authNotifierProvider).valueOrNull?.id ?? '',
    );

class RouteRepositoryImpl implements RouteRepository {
  const RouteRepositoryImpl(this._datasource, this._userId);
  final RouteRemoteDatasource _datasource;
  final String _userId;

  @override
  Future<List<TripRoute>> getRoutes(String tripId) async {
    final models = await _datasource.getRoutes(tripId);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<TripRoute> createRoute({
    required String tripId,
    required String title,
    required TransportMode transportMode,
    String? description,
  }) async {
    final model = await _datasource.createRoute({
      'trip_id': tripId,
      'created_by': _userId,
      'title': title,
      'transport_mode': transportMode.name,
      if (description != null) 'description': description,
    });
    return model.toEntity();
  }

  @override
  Future<void> deleteRoute(String routeId) =>
      _datasource.deleteRoute(routeId);

  @override
  Future<List<RouteWaypoint>> getWaypoints(String routeId) async {
    final data = await _datasource.getWaypoints(routeId);
    return data
        .map((e) => RouteWaypoint(
              id: e['id'] as String,
              routeId: e['route_id'] as String,
              markerId: e['marker_id'] as String,
              order: e['order'] as int,
            ))
        .toList();
  }

  @override
  Future<void> addWaypoint(
      String routeId, String markerId, int order) async {
    // TODO: implement via datasource
  }

  @override
  Future<void> removeWaypoint(String waypointId) async {
    // TODO: implement via datasource
  }
}
