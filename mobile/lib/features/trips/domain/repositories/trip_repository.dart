import '../entities/trip.dart';

abstract interface class TripRepository {
  Future<List<Trip>> getTrips();
  Future<Trip> getTrip(String tripId);
  Future<Trip> createTrip({
    required String title,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    String? coverColor,
  });
  Future<Trip> updateTrip(
    String tripId, {
    String? title,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    String? coverColor,
  });
  Future<void> deleteTrip(String tripId);
}
