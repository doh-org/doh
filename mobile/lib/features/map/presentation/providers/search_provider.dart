import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/datasources/place_search_datasource.dart';
import '../../domain/entities/place.dart';

part 'search_provider.g.dart';

@riverpod
class PlaceSearchNotifier extends _$PlaceSearchNotifier {
  final Map<String, List<Place>> _cache = <String, List<Place>>{};

  @override
  AsyncValue<List<Place>> build() => const AsyncData([]);

  Future<void> search(
    String query, {
    String? x,
    String? y,
    double? zoom,
  }) async {
    final String q = query.trim();
    if (q.isEmpty) {
      state = const AsyncData([]);
      return;
    }
    final String cacheKey = x != null ? '$q|$x,$y' : q;
    if (_cache.containsKey(cacheKey)) {
      state = AsyncData(_cache[cacheKey]!);
      return;
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final List<Place> results = await ref
          .read(placeSearchDatasourceProvider)
          .search(q, x: x, y: y, zoom: zoom);
      _cache[cacheKey] = results;
      return results;
    });
  }

  void clear() {
    state = const AsyncData([]);
  }
}
