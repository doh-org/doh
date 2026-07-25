import 'package:doh/core/storage/location_consent_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  late LocationConsentStore store;

  setUp(() {
    // 매 테스트 독립: 인메모리 prefs로 교체
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    store = LocationConsentStore(SharedPreferencesAsync());
  });

  test('기본값은 unset (저장된 값 없음)', () async {
    expect(await store.get(), LocationConsent.unset);
  });

  test('granted 저장→조회 왕복', () async {
    await store.set(LocationConsent.granted);
    expect(await store.get(), LocationConsent.granted);
  });

  test('denied 저장→조회 왕복', () async {
    await store.set(LocationConsent.denied);
    expect(await store.get(), LocationConsent.denied);
  });

  test('unset 저장은 값 제거 → 다시 unset', () async {
    await store.set(LocationConsent.granted);
    await store.set(LocationConsent.unset);
    expect(await store.get(), LocationConsent.unset);
  });
}
