import '../entities/category.dart';
import '../entities/marker.dart';

abstract interface class MarkerRepository {
  Future<List<TripMarker>> getMarkers(String tripId, int dayCount);

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
    List<int> visitDays = const [],
  });

  Future<TripMarker> updateMarker(
    String tripId,
    String markerId, {
    String? name,
    String? categoryId,
    bool clearCategoryId = false,
    List<int>? visitDays,
    String? memo,
  });

  Future<void> deleteMarker(String tripId, String markerId);

  Future<List<Category>> getCategories(String tripId);
}
