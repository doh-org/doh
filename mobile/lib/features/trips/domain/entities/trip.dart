import 'package:freezed_annotation/freezed_annotation.dart';

part 'trip.freezed.dart';

@freezed
abstract class Trip with _$Trip {
  const factory Trip({
    required String id,
    required String ownerId,
    required String title,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    String? coverColor,
    DateTime? deletedAt,
    required DateTime createdAt,
  }) = _Trip;
}
