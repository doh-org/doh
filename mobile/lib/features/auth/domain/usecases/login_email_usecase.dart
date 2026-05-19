import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/repositories/auth_repository_impl.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

part 'login_email_usecase.g.dart';

@riverpod
LoginEmailUsecase loginEmailUsecase(Ref ref) =>
    LoginEmailUsecase(ref.watch(authRepositoryProvider));

class LoginEmailUsecase {
  const LoginEmailUsecase(this._repo);
  final AuthRepository _repo;

  Future<User> call(String email, String password) =>
      _repo.loginWithEmail(email, password);
}
