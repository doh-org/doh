import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/user_model.dart';

part 'auth_repository_impl.g.dart';

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) =>
    AuthRepositoryImpl(ref.watch(authRemoteDatasourceProvider));

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._datasource);
  final AuthRemoteDatasource _datasource;

  @override
  Future<User> loginWithEmail(String email, String password) async {
    final model = await _datasource.loginWithEmail(email, password);
    return model.toEntity();
  }

  @override
  Future<User> signUp(String email, String password, String nickname) async {
    final model = await _datasource.signUp(email, password, nickname);
    return model.toEntity();
  }

  @override
  Future<void> logout() => _datasource.logout();

  @override
  Future<User?> getCurrentUser() async {
    final model = await _datasource.getCurrentUser();
    return model?.toEntity();
  }
}
