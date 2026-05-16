import '../entities/category.dart';
import '../entities/marker.dart';

abstract interface class MarkerRepository {
  Future<List<TripMarker>> getMarkers(String tripId);
  Future<TripMarker> createMarker({
    required String tripId,
    required String name,
    required double latitude,
    required double longitude,
    String? categoryId,
    String? address,
    String? memo,
    required MarkerSource source,
  });
  Future<TripMarker> updateMarker(String markerId, {
    String? name,
    String? categoryId,
    String? memo,
    DateTime? visitTime,
  });
  Future<void> deleteMarker(String markerId);
  Future<List<Category>> getCategories(String tripId);
}
