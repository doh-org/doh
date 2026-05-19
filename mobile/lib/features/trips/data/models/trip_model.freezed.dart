// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'trip_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TripModel {
  String get id;
  @JsonKey(name: 'owner_id')
  String get ownerId;
  String get title;
  String? get description;
  @JsonKey(name: 'start_date')
  DateTime? get startDate;
  @JsonKey(name: 'end_date')
  DateTime? get endDate;
  @JsonKey(name: 'deleted_at')
  DateTime? get deletedAt;
  @JsonKey(name: 'created_at')
  DateTime get createdAt;

  /// Create a copy of TripModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $TripModelCopyWith<TripModel> get copyWith =>
      _$TripModelCopyWithImpl<TripModel>(this as TripModel, _$identity);

  /// Serializes this TripModel to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is TripModel &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.ownerId, ownerId) || other.ownerId == ownerId) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.startDate, startDate) ||
                other.startDate == startDate) &&
            (identical(other.endDate, endDate) || other.endDate == endDate) &&
            (identical(other.deletedAt, deletedAt) ||
                other.deletedAt == deletedAt) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, ownerId, title, description,
      startDate, endDate, deletedAt, createdAt);

  @override
  String toString() {
    return 'TripModel(id: $id, ownerId: $ownerId, title: $title, description: $description, startDate: $startDate, endDate: $endDate, deletedAt: $deletedAt, createdAt: $createdAt)';
  }
}

/// @nodoc
abstract mixin class $TripModelCopyWith<$Res> {
  factory $TripModelCopyWith(TripModel value, $Res Function(TripModel) _then) =
      _$TripModelCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'owner_id') String ownerId,
      String title,
      String? description,
      @JsonKey(name: 'start_date') DateTime? startDate,
      @JsonKey(name: 'end_date') DateTime? endDate,
      @JsonKey(name: 'deleted_at') DateTime? deletedAt,
      @JsonKey(name: 'created_at') DateTime createdAt});
}

/// @nodoc
class _$TripModelCopyWithImpl<$Res> implements $TripModelCopyWith<$Res> {
  _$TripModelCopyWithImpl(this._self, this._then);

  final TripModel _self;
  final $Res Function(TripModel) _then;

  /// Create a copy of TripModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? ownerId = null,
    Object? title = null,
    Object? description = freezed,
    Object? startDate = freezed,
    Object? endDate = freezed,
    Object? deletedAt = freezed,
    Object? createdAt = null,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      ownerId: null == ownerId
          ? _self.ownerId
          : ownerId // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _self.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _self.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      startDate: freezed == startDate
          ? _self.startDate
          : startDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      endDate: freezed == endDate
          ? _self.endDate
          : endDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      deletedAt: freezed == deletedAt
          ? _self.deletedAt
          : deletedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      createdAt: null == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// Adds pattern-matching-related methods to [TripModel].
extension TripModelPatterns on TripModel {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_TripModel value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _TripModel() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_TripModel value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TripModel():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_TripModel value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TripModel() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(
            String id,
            @JsonKey(name: 'owner_id') String ownerId,
            String title,
            String? description,
            @JsonKey(name: 'start_date') DateTime? startDate,
            @JsonKey(name: 'end_date') DateTime? endDate,
            @JsonKey(name: 'deleted_at') DateTime? deletedAt,
            @JsonKey(name: 'created_at') DateTime createdAt)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _TripModel() when $default != null:
        return $default(_that.id, _that.ownerId, _that.title, _that.description,
            _that.startDate, _that.endDate, _that.deletedAt, _that.createdAt);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(
            String id,
            @JsonKey(name: 'owner_id') String ownerId,
            String title,
            String? description,
            @JsonKey(name: 'start_date') DateTime? startDate,
            @JsonKey(name: 'end_date') DateTime? endDate,
            @JsonKey(name: 'deleted_at') DateTime? deletedAt,
            @JsonKey(name: 'created_at') DateTime createdAt)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TripModel():
        return $default(_that.id, _that.ownerId, _that.title, _that.description,
            _that.startDate, _that.endDate, _that.deletedAt, _that.createdAt);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(
            String id,
            @JsonKey(name: 'owner_id') String ownerId,
            String title,
            String? description,
            @JsonKey(name: 'start_date') DateTime? startDate,
            @JsonKey(name: 'end_date') DateTime? endDate,
            @JsonKey(name: 'deleted_at') DateTime? deletedAt,
            @JsonKey(name: 'created_at') DateTime createdAt)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TripModel() when $default != null:
        return $default(_that.id, _that.ownerId, _that.title, _that.description,
            _that.startDate, _that.endDate, _that.deletedAt, _that.createdAt);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _TripModel implements TripModel {
  const _TripModel(
      {required this.id,
      @JsonKey(name: 'owner_id') required this.ownerId,
      required this.title,
      this.description,
      @JsonKey(name: 'start_date') this.startDate,
      @JsonKey(name: 'end_date') this.endDate,
      @JsonKey(name: 'deleted_at') this.deletedAt,
      @JsonKey(name: 'created_at') required this.createdAt});
  factory _TripModel.fromJson(Map<String, dynamic> json) =>
      _$TripModelFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'owner_id')
  final String ownerId;
  @override
  final String title;
  @override
  final String? description;
  @override
  @JsonKey(name: 'start_date')
  final DateTime? startDate;
  @override
  @JsonKey(name: 'end_date')
  final DateTime? endDate;
  @override
  @JsonKey(name: 'deleted_at')
  final DateTime? deletedAt;
  @override
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  /// Create a copy of TripModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$TripModelCopyWith<_TripModel> get copyWith =>
      __$TripModelCopyWithImpl<_TripModel>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$TripModelToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _TripModel &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.ownerId, ownerId) || other.ownerId == ownerId) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.startDate, startDate) ||
                other.startDate == startDate) &&
            (identical(other.endDate, endDate) || other.endDate == endDate) &&
            (identical(other.deletedAt, deletedAt) ||
                other.deletedAt == deletedAt) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, ownerId, title, description,
      startDate, endDate, deletedAt, createdAt);

  @override
  String toString() {
    return 'TripModel(id: $id, ownerId: $ownerId, title: $title, description: $description, startDate: $startDate, endDate: $endDate, deletedAt: $deletedAt, createdAt: $createdAt)';
  }
}

/// @nodoc
abstract mixin class _$TripModelCopyWith<$Res>
    implements $TripModelCopyWith<$Res> {
  factory _$TripModelCopyWith(
          _TripModel value, $Res Function(_TripModel) _then) =
      __$TripModelCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'owner_id') String ownerId,
      String title,
      String? description,
      @JsonKey(name: 'start_date') DateTime? startDate,
      @JsonKey(name: 'end_date') DateTime? endDate,
      @JsonKey(name: 'deleted_at') DateTime? deletedAt,
      @JsonKey(name: 'created_at') DateTime createdAt});
}

/// @nodoc
class __$TripModelCopyWithImpl<$Res> implements _$TripModelCopyWith<$Res> {
  __$TripModelCopyWithImpl(this._self, this._then);

  final _TripModel _self;
  final $Res Function(_TripModel) _then;

  /// Create a copy of TripModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? ownerId = null,
    Object? title = null,
    Object? description = freezed,
    Object? startDate = freezed,
    Object? endDate = freezed,
    Object? deletedAt = freezed,
    Object? createdAt = null,
  }) {
    return _then(_TripModel(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      ownerId: null == ownerId
          ? _self.ownerId
          : ownerId // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _self.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _self.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      startDate: freezed == startDate
          ? _self.startDate
          : startDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      endDate: freezed == endDate
          ? _self.endDate
          : endDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      deletedAt: freezed == deletedAt
          ? _self.deletedAt
          : deletedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      createdAt: null == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

// dart format on
