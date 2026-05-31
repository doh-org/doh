import '../entities/trip_route.dart';

abstract interface class RouteRepository {
  Future<List<TripRoute>> getRoutes(String tripId);
  Future<TripRoute> createRoute({
    required String tripId,
    required String title,
    required TransportMode transportMode,
    String? description,
  });
  Future<void> deleteRoute(String routeId);
  Future<List<RouteWaypoint>> getWaypoints(String routeId);
  Future<void> addWaypoint(String routeId, String markerId, int order);
  Future<void> removeWaypoint(String waypointId);
}
