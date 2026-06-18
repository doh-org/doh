import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/route_stop.dart';

part 'route_stop_model.freezed.dart';
part 'route_stop_model.g.dart';

/// marker_id 키 호환: day 목록(GET)은 `id`, stop 수정(PATCH)은 `marker_id` 반환.
Object? _readMarkerId(Map<dynamic, dynamic> json, String key) =>
    json['id'] ?? json['marker_id'];

@freezed
abstract class RouteStopModel with _$RouteStopModel {
  const factory RouteStopModel({
    @JsonKey(name: 'id', readValue: _readMarkerId) required String markerId,
    required String name,
    required double latitude,
    required double longitude,
    @JsonKey(name: 'category_id') String? categoryId,
    required int order,
    @JsonKey(name: 'visit_time') String? visitTime,
    @JsonKey(name: 'transport_to_next') String? transportToNext,
    @JsonKey(name: 'distance_to_next') double? distanceToNext,
    @JsonKey(name: 'duration_to_next') int? durationToNext,
  }) = _RouteStopModel;

  factory RouteStopModel.fromJson(Map<String, dynamic> json) =>
      _$RouteStopModelFromJson(json);
}

extension RouteStopModelX on RouteStopModel {
  RouteStop toEntity() => RouteStop(
        markerId: markerId,
        name: name,
        latitude: latitude,
        longitude: longitude,
        categoryId: categoryId,
        order: order,
        visitTime: visitTime,
        transportToNext: transportToNext == null
            ? null
            : TransportMode.values.byName(transportToNext!),
        distanceToNext: distanceToNext,
        durationToNext: durationToNext,
      );
}
