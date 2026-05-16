import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/user.dart';
import '../../domain/usecases/login_kakao_usecase.dart';

part 'auth_provider.g.dart';

@Riverpod(keepAlive: true)
class AuthNotifier extends _$AuthNotifier {
  @override
  Future<User?> build() async {
    // TODO: authRepository를 keepAlive로 provide 후 getCurrentUser 호출
    return null;
  }

  Future<void> loginWithKakao() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(loginKakaoUsecaseProvider).call(),
    );
  }

  Future<void> logout() async {
    // TODO: logout usecase
    state = const AsyncData(null);
  }
}
