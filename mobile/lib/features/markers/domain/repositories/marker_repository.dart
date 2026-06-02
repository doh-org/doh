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
    Map<String, dynamic>? detail,
    required MarkerSource source,
    DateTime? visitTime,
  });

  Future<TripMarker> updateMarker(
    String tripId,
    String markerId, {
    String? name,
    String? categoryId,
    bool clearCategoryId = false,
    DateTime? visitTime,
    bool clearVisitTime = false,
    String? memo,
  });

  Future<void> deleteMarker(String tripId, String markerId);

  Future<List<Category>> getCategories(String tripId);
}
