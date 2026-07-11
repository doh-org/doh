import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../storage/guest_store.dart';

part 'guest_mode_provider.g.dart';

/// 앱 시작 시점의 게스트 플래그. main()에서 로컬 값을 미리 읽어 override 한다.
/// (async로 읽으면 라우터 첫 redirect와 레이스 → 미리 주입해 동기적으로 확정)
final Provider<bool> initialGuestModeProvider =
    Provider<bool>((_) => false);

/// 게스트(로그인 없이) 모드 여부. true면 라우터가 앱 진입을 허용하고,
/// repository provider들이 로컬 구현으로 스왑된다.
@Riverpod(keepAlive: true)
class GuestMode extends _$GuestMode {
  @override
  bool build() => ref.read(initialGuestModeProvider);

  // "로그인 없이" 진입 — 플래그를 켜고 로컬에 저장.
  Future<void> enter() async {
    await ref.read(guestStoreProvider).setGuest(true);
    state = true;
  }

  // 게스트 해제 — 플래그만 끄고 로컬 데이터는 건드리지 않는다.
  Future<void> exit() async {
    await ref.read(guestStoreProvider).setGuest(false);
    state = false;
  }
}

/// 게스트 표시용 닉네임. 계정 정보 페이지에서 수정, 목록 인사말 등에 표시.
@Riverpod(keepAlive: true)
class GuestNickname extends _$GuestNickname {
  static const String _fallback = '나';

  @override
  Future<String> build() async =>
      await ref.read(guestStoreProvider).getNickname() ?? _fallback;

  Future<void> save(String nickname) async {
    final String v = nickname.trim();
    if (v.isEmpty) return; // 빈 닉네임은 저장하지 않음(호출부가 검증·안내)
    await ref.read(guestStoreProvider).setNickname(v);
    state = AsyncData(v);
  }
}
