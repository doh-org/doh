import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/category.dart';

part 'category_model.freezed.dart';
part 'category_model.g.dart';

@freezed
class CategoryModel with _$CategoryModel {
  const factory CategoryModel({
    required String id,
    @JsonKey(name: 'trip_id') required String tripId,
    required String name,
    required String color,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _CategoryModel;

  factory CategoryModel.fromJson(Map<String, dynamic> json) =>
      _$CategoryModelFromJson(json);
}

extension CategoryModelX on CategoryModel {
  Category toEntity() => Category(
        id: id,
        tripId: tripId,
        name: name,
        color: color,
        createdAt: createdAt,
      );
}
