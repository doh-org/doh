import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../markers/presentation/providers/marker_provider.dart';
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
) async {
  // 마커가 바뀌면(추가·삭제·방문일 수정) 이 목록도 다시 조회되도록 의존을 건다.
  // 값 자체는 안 쓰고 "갱신 신호"로만 구독한다.
  // .future로 기다리는 이유: AsyncValue를 watch하면 loading→data 두 번 재계산돼
  // 서버를 두 번 부른다.
  await ref.watch(markerEntitiesProvider(tripId).future);
  return ref.watch(routeRepositoryProvider).getDayStops(tripId, day, sort: sort);
}
