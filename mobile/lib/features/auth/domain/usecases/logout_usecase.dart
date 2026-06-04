import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/repositories/auth_repository_impl.dart';
import '../repositories/auth_repository.dart';

part 'logout_usecase.g.dart';

@riverpod
LogoutUsecase logoutUsecase(Ref ref) =>
    LogoutUsecase(ref.watch(authRepositoryProvider));

class LogoutUsecase {
  const LogoutUsecase(this._repo);
  final AuthRepository _repo;

  Future<void> call() => _repo.logout();
}
