// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'route_stop_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RouteStopModel _$RouteStopModelFromJson(Map<String, dynamic> json) =>
    _RouteStopModel(
      markerId: _readMarkerId(json, 'id') as String,
      name: json['name'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      categoryId: json['category_id'] as String?,
      order: (json['order'] as num).toInt(),
      visitTime: json['visit_time'] as String?,
      transportToNext: json['transport_to_next'] as String?,
      distanceToNext: (json['distance_to_next'] as num?)?.toDouble(),
      durationToNext: (json['duration_to_next'] as num?)?.toInt(),
    );

Map<String, dynamic> _$RouteStopModelToJson(_RouteStopModel instance) =>
    <String, dynamic>{
      'id': instance.markerId,
      'name': instance.name,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'category_id': instance.categoryId,
      'order': instance.order,
      'visit_time': instance.visitTime,
      'transport_to_next': instance.transportToNext,
      'distance_to_next': instance.distanceToNext,
      'duration_to_next': instance.durationToNext,
    };
