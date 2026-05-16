import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_model.dart';

part 'auth_remote_datasource.g.dart';

@riverpod
AuthRemoteDatasource authRemoteDatasource(Ref ref) =>
    AuthRemoteDatasource(Supabase.instance.client);

class AuthRemoteDatasource {
  const AuthRemoteDatasource(this._supabase);
  final SupabaseClient _supabase;

  Future<UserModel> loginWithKakao() async {
    // 카카오 SDK로 토큰 획득
    final token = await UserApi.instance.loginWithKakaoAccount();
    final idToken = token.idToken;

    // Supabase에 카카오 토큰으로 로그인
    await _supabase.auth.signInWithIdToken(
      provider: OAuthProvider.kakao,
      idToken: idToken ?? '',
    );

    final userId = _supabase.auth.currentUser!.id;
    final data = await _supabase
        .from('users')
        .select()
        .eq('id', userId)
        .single();

    return UserModel.fromJson(data);
  }

  Future<void> logout() => _supabase.auth.signOut();

  Future<UserModel?> getCurrentUser() async {
    final authUser = _supabase.auth.currentUser;
    if (authUser == null) return null;

    final data = await _supabase
        .from('users')
        .select()
        .eq('id', authUser.id)
        .maybeSingle();

    return data == null ? null : UserModel.fromJson(data);
  }
}
