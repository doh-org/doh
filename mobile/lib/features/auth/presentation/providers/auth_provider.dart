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

  Future<void> refreshUser() async {
    try {
      final user = await ref.read(authRepositoryProvider).getMe();
      state = AsyncData(user);
    } catch (_) {}
  }
}
