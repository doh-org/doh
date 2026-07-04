import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/storage/token_storage.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user.dart';
import '../../domain/usecases/login_email_usecase.dart';
import '../../domain/usecases/login_kakao_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/signup_usecase.dart';

part 'auth_provider.g.dart';

@Riverpod(keepAlive: true)
class AuthNotifier extends _$AuthNotifier {
  @override
  Future<User?> build() async {
    final tokenStorage = ref.read(tokenStorageProvider);
    final token = await tokenStorage.getAccessToken();
    if (token == null) return null;
    return tokenStorage.getUser();
  }

  Future<void> loginWithEmail(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard<User?>(
      () => ref.read(loginEmailUsecaseProvider).call(email, password),
    );
  }

  Future<void> signUp(String email, String password, String nickname) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard<User?>(
      () => ref.read(signUpUsecaseProvider).call(email, password, nickname),
    );
  }

  Future<void> loginWithKakao() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard<User?>(
      () => ref.read(loginKakaoUsecaseProvider).call(),
    );
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
