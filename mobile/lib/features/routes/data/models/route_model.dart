import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/trip_route.dart';

part 'route_model.freezed.dart';
part 'route_model.g.dart';

@freezed
abstract class RouteModel with _$RouteModel {
  const factory RouteModel({
    required String id,
    @JsonKey(name: 'trip_id') required String tripId,
    @JsonKey(name: 'created_by') String? createdBy,
    required String title,
    String? description,
    @JsonKey(name: 'transport_mode') required String transportMode,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
  }) = _RouteModel;

  factory RouteModel.fromJson(Map<String, dynamic> json) =>
      _$RouteModelFromJson(json);
}

extension RouteModelX on RouteModel {
  TripRoute toEntity() => TripRoute(
        id: id,
        tripId: tripId,
        createdBy: createdBy,
        title: title,
        description: description,
        transportMode: TransportMode.values.byName(transportMode),
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}
