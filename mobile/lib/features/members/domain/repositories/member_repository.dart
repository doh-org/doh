import '../entities/trip_member.dart';

abstract interface class MemberRepository {
  Future<List<TripMember>> getMembers(String tripId);
  Future<Invitation> inviteMember(String tripId, String email);
  Future<void> removeMember(String tripId, String userId);
}
