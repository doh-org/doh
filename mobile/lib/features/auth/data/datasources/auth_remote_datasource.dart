import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  Future<UserModel> loginWithEmail(String email, String password) async {
    await _supabase.auth.signInWithPassword(email: email, password: password);
    return _fetchCurrentUser();
  }

  Future<UserModel> signUp(String email, String password, String nickname) async {
    final res = await _supabase.auth.signUp(email: email, password: password);
    if (res.session == null || res.user == null) {
      throw Exception('이메일 인증 후 로그인해주세요.');
    }
    final userId = res.user!.id;
    final data = await _supabase
        .from('users')
        .upsert({'id': userId, 'nickname': nickname})
        .select()
        .single();
    return UserModel.fromJson(data);
  }

  Future<void> logout() => _supabase.auth.signOut();

  Future<UserModel?> getCurrentUser() async {
    if (_supabase.auth.currentUser == null) return null;
    return _fetchCurrentUser();
  }

  Future<UserModel> _fetchCurrentUser() async {
    final userId = _supabase.auth.currentUser!.id;
    final data = await _supabase
        .from('users')
        .select()
        .eq('id', userId)
        .single();
    return UserModel.fromJson(data);
  }
}
