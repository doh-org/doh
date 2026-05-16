import 'package:freezed_annotation/freezed_annotation.dart';

part 'trip_route.freezed.dart';

enum TransportMode { car, foot, publictransit, bicycle }

@freezed
class TripRoute with _$TripRoute {
  const factory TripRoute({
    required String id,
    required String tripId,
    String? createdBy,
    required String title,
    String? description,
    required TransportMode transportMode,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _TripRoute;
}

@freezed
class RouteWaypoint with _$RouteWaypoint {
  const factory RouteWaypoint({
    required String id,
    required String routeId,
    required String markerId,
    required int order,
  }) = _RouteWaypoint;
}
