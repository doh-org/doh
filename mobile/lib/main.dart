import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart' show FlutterNaverMap;
import 'package:marionette_flutter/marionette_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/auth/guest_mode_provider.dart';
import 'core/storage/guest_store.dart';

void main() async {
  // 디버그 빌드에서만 Marionette 바인딩 — MCP 위젯 조회/탭/스크린샷 가능
  if (kDebugMode) {
    MarionetteBinding.ensureInitialized();
  } else {
    WidgetsFlutterBinding.ensureInitialized();
  }

  await FlutterNaverMap().init(
    clientId: const String.fromEnvironment('NAVER_MAP_CLIENT_ID'),
  );

  // 게스트 플래그는 미리 읽어 동기적으로 주입 — 라우터 첫 redirect와의 레이스 방지.
  final bool initialGuest =
      await SharedPreferencesAsync().getBool(GuestStore.guestFlagKey) ?? false;

  runApp(
    ProviderScope(
      overrides: [initialGuestModeProvider.overrideWithValue(initialGuest)],
      child: const App(),
    ),
  );
}