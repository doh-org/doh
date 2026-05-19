import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/marker.dart';

part 'marker_model.freezed.dart';
part 'marker_model.g.dart';

@freezed
abstract class MarkerModel with _$MarkerModel {
  const factory MarkerModel({
    required String id,
    @JsonKey(name: 'trip_id') required String tripId,
    @JsonKey(name: 'category_id') String? categoryId,
    @JsonKey(name: 'created_by') String? createdBy,
    required String name,
    required double latitude,
    required double longitude,
    String? address,
    String? memo,
    required String source,
    required Map<String, dynamic> detail,
    @JsonKey(name: 'visit_time') DateTime? visitTime,
    @JsonKey(name: 'deleted_at') DateTime? deletedAt,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _MarkerModel;

  factory MarkerModel.fromJson(Map<String, dynamic> json) =>
      _$MarkerModelFromJson(json);
}

extension MarkerModelX on MarkerModel {
  TripMarker toEntity() => TripMarker(
        id: id,
        tripId: tripId,
        categoryId: categoryId,
        createdBy: createdBy,
        name: name,
        latitude: latitude,
        longitude: longitude,
        address: address,
        memo: memo,
        source: MarkerSource.values.byName(source),
        detail: detail,
        visitTime: visitTime,
        deletedAt: deletedAt,
        createdAt: createdAt,
      );
}
