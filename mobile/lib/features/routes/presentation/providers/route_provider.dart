import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/repositories/route_repository_impl.dart';
import '../../domain/entities/route_stop.dart';

part 'route_provider.g.dart';

/// 선택 Day의 stop 목록(정렬 적용).
@riverpod
Future<List<RouteStop>> dayStops(
  Ref ref,
  String tripId,
  int day,
  RouteSort sort,
) =>
    ref.watch(routeRepositoryProvider).getDayStops(tripId, day, sort: sort);
