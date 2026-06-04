// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AuthResponseModel _$AuthResponseModelFromJson(Map<String, dynamic> json) =>
    _AuthResponseModel(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      user: UserResponseModel.fromJson(json['user'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$AuthResponseModelToJson(_AuthResponseModel instance) =>
    <String, dynamic>{
      'access_token': instance.accessToken,
      'refresh_token': instance.refreshToken,
      'user': instance.user,
    };

_UserResponseModel _$UserResponseModelFromJson(Map<String, dynamic> json) =>
    _UserResponseModel(
      userId: json['user_id'] as String,
      email: json['email'] as String,
      nickname: json['nickname'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$UserResponseModelToJson(_UserResponseModel instance) =>
    <String, dynamic>{
      'user_id': instance.userId,
      'email': instance.email,
      'nickname': instance.nickname,
      'created_at': instance.createdAt.toIso8601String(),
    };
