import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/user.dart';

part 'auth_response_model.freezed.dart';
part 'auth_response_model.g.dart';

@freezed
abstract class AuthResponseModel with _$AuthResponseModel {
  const factory AuthResponseModel({
    @JsonKey(name: 'access_token') required String accessToken,
    @JsonKey(name: 'refresh_token') required String refreshToken,
    required UserResponseModel user,
  }) = _AuthResponseModel;

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) =>
      _$AuthResponseModelFromJson(json);
}

@freezed
abstract class UserResponseModel with _$UserResponseModel {
  const factory UserResponseModel({
    @JsonKey(name: 'user_id') required String userId,
    required String email,
    required String nickname,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _UserResponseModel;

  factory UserResponseModel.fromJson(Map<String, dynamic> json) =>
      _$UserResponseModelFromJson(json);
}

extension UserResponseModelX on UserResponseModel {
  User toEntity() => User(
        id: userId,
        email: email,
        nickname: nickname,
        createdAt: createdAt,
      );
}
