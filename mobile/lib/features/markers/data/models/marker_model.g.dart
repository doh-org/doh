// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'marker_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MarkerModel _$MarkerModelFromJson(Map<String, dynamic> json) => _MarkerModel(
      id: json['id'] as String,
      tripId: json['trip_id'] as String,
      categoryId: json['category_id'] as String?,
      createdBy: json['created_by'] as String?,
      name: json['name'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      address: json['address'] as String?,
      memo: json['memo'] as String?,
      source: json['source'] as String,
      detail: (json['detail'] as Map<String, dynamic>?) ?? <String, dynamic>{},
      visitTime: _visitTimeFromJson(json['visit_time']),
      deletedAt: json['deleted_at'] == null
          ? null
          : DateTime.parse(json['deleted_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$MarkerModelToJson(_MarkerModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'trip_id': instance.tripId,
      'category_id': instance.categoryId,
      'created_by': instance.createdBy,
      'name': instance.name,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'address': instance.address,
      'memo': instance.memo,
      'source': instance.source,
      'detail': instance.detail,
      'visit_time': instance.visitTime?.toIso8601String(),
      'deleted_at': instance.deletedAt?.toIso8601String(),
      'created_at': instance.createdAt.toIso8601String(),
    };
