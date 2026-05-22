import 'package:freezed_annotation/freezed_annotation.dart';

part 'category.freezed.dart';

@freezed
class Category with _$Category {
  const factory Category({
    required String id,
    required String tripId,
    required String name,
    required String color,
    required DateTime createdAt,
  }) = _Category;
}
