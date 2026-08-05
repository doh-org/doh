import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../markers/presentation/providers/marker_provider.dart';
import '../../data/repositories/route_repository_impl.dart';
import '../../domain/entities/route_stop.dart';

part 'route_provider.g.dart';

/// tripId·day의 stop 목록을 sort 기준으로 반환.
/// markerEntities(tripId)를 구독해 마커 목록이 무효화되면 함께 재조회된다.
@riverpod
Future<List<RouteStop>> dayStops(
  Ref ref,
  String tripId,
  int day,
  RouteSort sort,
) async {
  await ref.watch(markerEntitiesProvider(tripId).future);
  return ref.watch(routeRepositoryProvider).getDayStops(tripId, day, sort: sort);
}
