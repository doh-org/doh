import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/trip_member.dart';
import '../../domain/repositories/member_repository.dart';
import '../datasources/member_remote_datasource.dart';

part 'member_repository_impl.g.dart';

@riverpod
MemberRepository memberRepository(Ref ref) =>
    MemberRepositoryImpl(ref.watch(memberRemoteDatasourceProvider));

class MemberRepositoryImpl implements MemberRepository {
  const MemberRepositoryImpl(this._datasource);
  final MemberRemoteDatasource _datasource;

  @override
  Future<List<TripMember>> getMembers(String tripId) async {
    final data = await _datasource.getMembers(tripId);
    return data
        .map((e) => TripMember(
              id: e['id'] as String,
              tripId: e['trip_id'] as String,
              userId: e['user_id'] as String,
              role: MemberRole.values.byName(e['role'] as String),
              joinedAt: DateTime.parse(e['joined_at'] as String),
            ))
        .toList();
  }

  @override
  Future<Invitation> inviteMember(String tripId, String email) async {
    final data = await _datasource.inviteMember(tripId, email);
    return Invitation(
      id: data['id'] as String,
      tripId: data['trip_id'] as String,
      invitedBy: data['invited_by'] as String?,
      email: data['email'] as String,
      status: data['status'] as String,
      expiredAt: DateTime.parse(data['expired_at'] as String),
      createdAt: DateTime.parse(data['created_at'] as String),
    );
  }

  @override
  Future<void> removeMember(String tripId, String userId) =>
      _datasource.removeMember(tripId, userId);
}
