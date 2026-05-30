import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/user.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

@freezed
abstract class UserModel with _$UserModel {
  const factory UserModel({
    required String id,
    String? email,
    required String nickname,
    @JsonKey(name: 'deleted_at') DateTime? deletedAt,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
}

extension UserModelX on UserModel {
  User toEntity() => User(
        id: id,
        email: email ?? '',
        nickname: nickname,
        deletedAt: deletedAt,
        createdAt: createdAt,
      );
}
