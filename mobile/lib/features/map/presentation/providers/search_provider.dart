import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/datasources/naver_local_search_datasource.dart';
import '../../domain/entities/naver_place.dart';

part 'search_provider.g.dart';

@riverpod
class NaverSearchNotifier extends _$NaverSearchNotifier {
  final _cache = <String, List<NaverPlace>>{};

  @override
  AsyncValue<List<NaverPlace>> build() => const AsyncData([]);

  Future<void> search(String query) async {
    final q = query.trim();
    if (q.isEmpty) {
      state = const AsyncData([]);
      return;
    }
    if (_cache.containsKey(q)) {
      state = AsyncData(_cache[q]!);
      return;
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final results =
          await ref.read(naverLocalSearchDatasourceProvider).search(q);
      _cache[q] = results;
      return results;
    });
  }

  void clear() {
    state = const AsyncData([]);
  }
}
