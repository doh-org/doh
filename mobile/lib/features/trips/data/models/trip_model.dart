import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/trip.dart';

part 'trip_model.freezed.dart';
part 'trip_model.g.dart';

@freezed
abstract class TripModel with _$TripModel {
  const factory TripModel({
    required String id,
    @JsonKey(name: 'owner_id') required String ownerId,
    required String title,
    String? description,
    @JsonKey(name: 'start_date') DateTime? startDate,
    @JsonKey(name: 'end_date') DateTime? endDate,
    @JsonKey(name: 'cover_color') String? coverColor,
    @JsonKey(name: 'deleted_at') DateTime? deletedAt,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _TripModel;

  factory TripModel.fromJson(Map<String, dynamic> json) =>
      _$TripModelFromJson(json);
}

extension TripModelX on TripModel {
  Trip toEntity() => Trip(
        id: id,
        ownerId: ownerId,
        title: title,
        description: description,
        startDate: startDate,
        endDate: endDate,
        coverColor: coverColor,
        deletedAt: deletedAt,
        createdAt: createdAt,
      );
}
