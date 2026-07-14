import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'map_app_store.g.dart';

/// 길찾기·장소 딥링크에 쓸 지도 앱 종류.
enum MapApp { naver, kakao }

// 지도 앱 고정 설정 저장소.
// 계정과 무관한 기기 취향이라 서버 없이 로컬(SharedPreferences)에만 둔다.
class MapAppStore {
  MapAppStore(this._prefs);
  final SharedPreferencesAsync _prefs;

  static const String key = 'preferred_map_app';

  Future<MapApp?> get() async {
    final String? raw = await _prefs.getString(key);
    // 저장된 이름 → enum 복원. 없거나 알 수 없는 값이면 미설정 취급
    for (final MapApp app in MapApp.values) {
      if (app.name == raw) return app;
    }
    return null;
  }

  // null = 고정 해제(열 때마다 선택 모달)
  Future<void> set(MapApp? app) =>
      app == null ? _prefs.remove(key) : _prefs.setString(key, app.name);
}

@riverpod
MapAppStore mapAppStore(Ref ref) => MapAppStore(SharedPreferencesAsync());

/// 고정된 지도 앱. null = 미설정.
@Riverpod(keepAlive: true)
class PreferredMapApp extends _$PreferredMapApp {
  @override
  Future<MapApp?> build() => ref.read(mapAppStoreProvider).get();

  Future<void> save(MapApp? app) async {
    await ref.read(mapAppStoreProvider).set(app);
    state = AsyncData(app);
  }
}
