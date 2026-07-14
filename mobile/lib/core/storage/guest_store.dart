import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'guest_store.g.dart';

// 게스트(로그인 없이) 모드의 로컬 데이터 저장소.
// 서버 대신 기기 로컬에 여행/마커/경로 오버라이드를 JSON으로 보관한다.
class GuestStore {
  GuestStore(this._prefs);
  final SharedPreferencesAsync _prefs;

  static const String guestFlagKey = 'guest_mode';
  static const String nicknameKey = 'guest_nickname';

  // 저장 키. 마커·경로는 여행별로 분리 저장한다(tripId를 접미사로).
  static String tripsKey() => 'guest_trips';
  static String markersKey(String tripId) => 'guest_markers_$tripId';
  static String dayStopsKey(String tripId) => 'guest_daystops_$tripId';

  Future<bool> isGuest() async => await _prefs.getBool(guestFlagKey) ?? false;
  Future<void> setGuest(bool v) => _prefs.setBool(guestFlagKey, v);

  // 게스트 표시용 닉네임(서버 유저가 없으므로 로컬 보관).
  Future<String?> getNickname() => _prefs.getString(nicknameKey);
  Future<void> setNickname(String v) => _prefs.setString(nicknameKey, v);

  // key에 저장된 JSON 객체 리스트를 읽는다(없으면 빈 리스트).
  Future<List<Map<String, dynamic>>> readObjects(String key) async {
    final List<String> raw = await _prefs.getStringList(key) ?? <String>[];
    // 각 원소는 jsonEncode된 Map 문자열 → 다시 Map으로 복원
    return raw.map((s) => jsonDecode(s) as Map<String, dynamic>).toList();
  }

  Future<void> writeObjects(String key, List<Map<String, dynamic>> objs) =>
      _prefs.setStringList(key, objs.map(jsonEncode).toList());

  Future<void> remove(String key) => _prefs.remove(key);
}

@riverpod
GuestStore guestStore(Ref ref) => GuestStore(SharedPreferencesAsync());
