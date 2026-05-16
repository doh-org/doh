import 'package:freezed_annotation/freezed_annotation.dart';

part 'trip_member.freezed.dart';

enum MemberRole { owner, editor }

@freezed
class TripMember with _$TripMember {
  const factory TripMember({
    required String id,
    required String tripId,
    required String userId,
    required MemberRole role,
    required DateTime joinedAt,
  }) = _TripMember;
}

@freezed
class Invitation with _$Invitation {
  const factory Invitation({
    required String id,
    required String tripId,
    String? invitedBy,
    required String email,
    required String status,
    required DateTime expiredAt,
    required DateTime createdAt,
  }) = _Invitation;
}
