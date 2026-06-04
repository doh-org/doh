import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/repositories/auth_repository_impl.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

part 'signup_usecase.g.dart';

@riverpod
SignUpUsecase signUpUsecase(Ref ref) =>
    SignUpUsecase(ref.watch(authRepositoryProvider));

class SignUpUsecase {
  const SignUpUsecase(this._repo);
  final AuthRepository _repo;

  Future<User> call(String email, String password, String nickname) =>
      _repo.signUp(email, password, nickname);
}
