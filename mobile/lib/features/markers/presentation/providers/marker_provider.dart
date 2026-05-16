import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/repositories/marker_repository_impl.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/marker.dart';
import '../../domain/repositories/marker_repository.dart';

part 'marker_provider.g.dart';

@riverpod
Future<Set<Marker>> markers(Ref ref, String tripId) async {
  final tripMarkers =
      await ref.watch(markerRepositoryProvider).getMarkers(tripId);
  final categories =
      await ref.watch(markerRepositoryProvider).getCategories(tripId);

  final categoryMap = {for (final c in categories) c.id: c};

  return tripMarkers.map((m) {
    final category = m.categoryId != null ? categoryMap[m.categoryId] : null;
    return _buildMarker(m, category);
  }).toSet();
}

@riverpod
Future<List<TripMarker>> markerEntities(Ref ref, String tripId) =>
    ref.watch(markerRepositoryProvider).getMarkers(tripId);

@riverpod
Future<List<Category>> categories(Ref ref, String tripId) =>
    ref.watch(markerRepositoryProvider).getCategories(tripId);

Marker _buildMarker(TripMarker m, Category? category) {
  return Marker(
    markerId: MarkerId(m.id),
    position: LatLng(m.latitude, m.longitude),
    infoWindow: InfoWindow(title: m.name, snippet: m.address),
  );
}
