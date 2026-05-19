import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/config/app_config.dart';

part 'member_remote_datasource.g.dart';

@riverpod
MemberRemoteDatasource memberRemoteDatasource(Ref ref) =>
    MemberRemoteDatasource(Supabase.instance.client);

class MemberRemoteDatasource {
  const MemberRemoteDatasource(this._supabase);
  final SupabaseClient _supabase;

  Future<List<Map<String, dynamic>>> getMembers(String tripId) async {
    final data = await _supabase
        .from('trip_members')
        .select()
        .eq('trip_id', tripId);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<Map<String, dynamic>> inviteMember(
      String tripId, String email) async {
    final invitedBy = _supabase.auth.currentUser?.id ?? AppConfig.devUserId;
    final data = await _supabase
        .from('trip_invitations')
        .insert({
          'trip_id': tripId,
          'invited_by': invitedBy,
          'email': email,
        })
        .select()
        .single();
    return data;
  }

  Future<void> removeMember(String tripId, String userId) async {
    await _supabase
        .from('trip_members')
        .delete()
        .eq('trip_id', tripId)
        .eq('user_id', userId);
  }
}
