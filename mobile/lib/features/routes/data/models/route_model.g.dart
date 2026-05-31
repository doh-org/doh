// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'route_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RouteModel _$RouteModelFromJson(Map<String, dynamic> json) => _RouteModel(
      id: json['id'] as String,
      tripId: json['trip_id'] as String,
      createdBy: json['created_by'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      transportMode: json['transport_mode'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$RouteModelToJson(_RouteModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'trip_id': instance.tripId,
      'created_by': instance.createdBy,
      'title': instance.title,
      'description': instance.description,
      'transport_mode': instance.transportMode,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };
