import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/user.dart';
import '../../domain/usecases/login_email_usecase.dart';
import '../../domain/usecases/sign_up_usecase.dart';

part 'auth_provider.g.dart';

@Riverpod(keepAlive: true)
class AuthNotifier extends _$AuthNotifier {
  @override
  Future<User?> build() async => null;

  Future<void> loginWithEmail(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(loginEmailUsecaseProvider).call(email, password),
    );
  }

  Future<void> signUp(String email, String password, String nickname) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(signUpUsecaseProvider).call(email, password, nickname),
    );
  }

  Future<void> logout() async {
    state = const AsyncData(null);
  }
}
