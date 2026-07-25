import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'location_consent_store.g.dart';

/// 위치정보 사용 동의 상태
/// unset = 아직 안 물어본 상태 / granted = 동의 / denied = 거부
/// "거부"와 "미설정"을 굳이 구별하는 이유: 게이트가 둘을 로그·디버그에서
/// 나눠 볼 수 있게 하기 위함(동작은 둘 다 모달 재노출로 같다)
enum LocationConsent { unset, granted, denied }

// 위치정보 사용 동의 저장소.
// 계정과 무관한 기기 취향이라 서버 없이 로컬(SharedPreferences)에만 둔다.
class LocationConsentStore {
  LocationConsentStore(this._prefs);
  final SharedPreferencesAsync _prefs;

  static const String key = 'location_consent';

  Future<LocationConsent> get() async {
    final String? raw = await _prefs.getString(key);
    // 저장된 이름 → enum 복원. 없거나 알 수 없는 값이면 미설정(unset) 취급
    for (final LocationConsent c in LocationConsent.values) {
      if (c.name == raw) return c;
    }
    return LocationConsent.unset;
  }

  // unset = 저장 해제(미설정으로 되돌림)
  Future<void> set(LocationConsent consent) =>
      consent == LocationConsent.unset
          ? _prefs.remove(key)
          : _prefs.setString(key, consent.name);
}

@riverpod
LocationConsentStore locationConsentStore(Ref ref) =>
    LocationConsentStore(SharedPreferencesAsync());

/// 현재 위치정보 동의 상태, 계정 무관 기기 로컬값이라 keepAlive로 유지
@Riverpod(keepAlive: true)
class LocationConsentPref extends _$LocationConsentPref {
  @override
  Future<LocationConsent> build() =>
      ref.read(locationConsentStoreProvider).get();

  Future<void> save(LocationConsent consent) async {
    await ref.read(locationConsentStoreProvider).set(consent);
    state = AsyncData(consent); // 디스크 재조회 없이 즉시 반영
  }
}
