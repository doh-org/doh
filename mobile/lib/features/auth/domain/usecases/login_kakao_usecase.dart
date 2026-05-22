import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/repositories/auth_repository_impl.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

part 'login_kakao_usecase.g.dart';

@riverpod
LoginKakaoUsecase loginKakaoUsecase(Ref ref) =>
    LoginKakaoUsecase(ref.watch(authRepositoryProvider));

class LoginKakaoUsecase {
  const LoginKakaoUsecase(this._repo);
  final AuthRepository _repo;

  Future<User> call() => _repo.loginWithKakao();
}
