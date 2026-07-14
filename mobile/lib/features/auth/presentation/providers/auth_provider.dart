import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/auth/guest_mode_provider.dart';
import '../../../../core/storage/token_storage.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user.dart';
import '../../domain/usecases/login_email_usecase.dart';
import '../../domain/usecases/login_kakao_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';

part 'auth_provider.g.dart';

@Riverpod(keepAlive: true)
class AuthNotifier extends _$AuthNotifier {
  @override
  Future<User?> build() async {
    final tokenStorage = ref.read(tokenStorageProvider);

    // 온보딩 로고를 최소 1초 노출: 타이머를 먼저 걸어두고
    // 토큰 복원을 끝낸 뒤 남은 시간만큼 기다린다(둘 중 더 오래 걸리는 쪽).
    final Future<void> minSplash =
        Future<void>.delayed(const Duration(seconds: 1));
    final token = await tokenStorage.getAccessToken();
    final User? user = token == null ? null : await tokenStorage.getUser();
    await minSplash;
    return user;
  }

  Future<void> loginWithEmail(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard<User?>(
      () => ref.read(loginEmailUsecaseProvider).call(email, password),
    );
    await _exitGuestOnSuccess();
  }

  // 회원가입 3단계: 가입 세션으로 비번·닉네임 설정 → 성공 시 자동 로그인(로그인과 동일 흐름).
  // 1·2단계(코드 발송·검증)는 로그인 전이라 페이지가 repository를 직접 호출한다.
  Future<void> completeSignup(
      String accessToken, String password, String nickname) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard<User?>(
      () => ref
          .read(authRepositoryProvider)
          .completeSignup(accessToken, password, nickname),
    );
    await _exitGuestOnSuccess();
  }

  Future<void> loginWithKakao() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard<User?>(
      () => ref.read(loginKakaoUsecaseProvider).call(),
    );
    await _exitGuestOnSuccess();
  }

  // 로그인·회원가입이 실제로 성공(유저 세팅)했을 때만 게스트 모드를 끈다.
  // 안 그러면 로그인했는데도 repository가 로컬(게스트) 구현을 계속 써버린다.
  Future<void> _exitGuestOnSuccess() async {
    if (state.valueOrNull != null) {
      await ref.read(guestModeProvider.notifier).exit();
    }
  }

  Future<void> logout() async {
    state = const AsyncLoading();
    try {
      await ref.read(logoutUsecaseProvider).call();
    } catch (_) {}
    state = const AsyncData(null);
  }

  // 회원 탈퇴. 성공 시에만 세션 해제(null) → 라우터가 /login으로 redirect.
  // 실패 시 이전 상태를 복원하고 false 반환(호출부가 실패 안내).
  Future<bool> withdraw() async {
    final User? prev = state.valueOrNull;
    state = const AsyncLoading();
    try {
      await ref.read(authRepositoryProvider).deleteAccount();
      state = const AsyncData(null);
      return true;
    } catch (_) {
      state = AsyncData(prev); // 실패 → 세션 유지
      return false;
    }
  }

  Future<void> refreshUser() async {
    try {
      final user = await ref.read(authRepositoryProvider).getMe();
      state = AsyncData(user);
    } catch (_) {}
  }

  // refresh 재발급 최종 실패(토큰 만료) 시 인터셉터가 호출.
  // 상태 null → 라우터 redirect가 /login으로 보낸다.
  void sessionExpired() {
    state = const AsyncData(null);
  }
}
