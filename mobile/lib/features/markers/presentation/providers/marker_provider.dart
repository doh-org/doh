import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/repositories/marker_repository_impl.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/marker.dart';

part 'marker_provider.g.dart';

@riverpod
Future<List<TripMarker>> markerEntities(Ref ref, String tripId) =>
    ref.watch(markerRepositoryProvider).getMarkers(tripId);

@riverpod
Future<List<Category>> categories(Ref ref, String tripId) =>
    ref.watch(markerRepositoryProvider).getCategories(tripId);
