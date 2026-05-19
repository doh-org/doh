import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/repositories/member_repository_impl.dart';
import '../../domain/entities/trip_member.dart';

part 'member_provider.g.dart';

@riverpod
Future<List<TripMember>> members(Ref ref, String tripId) =>
    ref.watch(memberRepositoryProvider).getMembers(tripId);
