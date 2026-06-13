// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'marker_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MarkerModel {
  String get id;
  @JsonKey(name: 'trip_id')
  String get tripId;
  @JsonKey(name: 'category_id')
  String? get categoryId;
  @JsonKey(name: 'created_by')
  String? get createdBy;
  String get name;
  double get latitude;
  double get longitude;
  String? get address;
  String? get memo;
  String get source;
  Map<String, dynamic> get detail;
  @JsonKey(name: 'visit_days')
  List<int> get visitDays;
  @JsonKey(name: 'deleted_at')
  DateTime? get deletedAt;
  @JsonKey(name: 'created_at')
  DateTime get createdAt;

  /// Create a copy of MarkerModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $MarkerModelCopyWith<MarkerModel> get copyWith =>
      _$MarkerModelCopyWithImpl<MarkerModel>(this as MarkerModel, _$identity);

  /// Serializes this MarkerModel to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is MarkerModel &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.tripId, tripId) || other.tripId == tripId) &&
            (identical(other.categoryId, categoryId) ||
                other.categoryId == categoryId) &&
            (identical(other.createdBy, createdBy) ||
                other.createdBy == createdBy) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.latitude, latitude) ||
                other.latitude == latitude) &&
            (identical(other.longitude, longitude) ||
                other.longitude == longitude) &&
            (identical(other.address, address) || other.address == address) &&
            (identical(other.memo, memo) || other.memo == memo) &&
            (identical(other.source, source) || other.source == source) &&
            const DeepCollectionEquality().equals(other.detail, detail) &&
            const DeepCollectionEquality().equals(other.visitDays, visitDays) &&
            (identical(other.deletedAt, deletedAt) ||
                other.deletedAt == deletedAt) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      tripId,
      categoryId,
      createdBy,
      name,
      latitude,
      longitude,
      address,
      memo,
      source,
      const DeepCollectionEquality().hash(detail),
      const DeepCollectionEquality().hash(visitDays),
      deletedAt,
      createdAt);

  @override
  String toString() {
    return 'MarkerModel(id: $id, tripId: $tripId, categoryId: $categoryId, createdBy: $createdBy, name: $name, latitude: $latitude, longitude: $longitude, address: $address, memo: $memo, source: $source, detail: $detail, visitDays: $visitDays, deletedAt: $deletedAt, createdAt: $createdAt)';
  }
}

/// @nodoc
abstract mixin class $MarkerModelCopyWith<$Res> {
  factory $MarkerModelCopyWith(
          MarkerModel value, $Res Function(MarkerModel) _then) =
      _$MarkerModelCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'trip_id') String tripId,
      @JsonKey(name: 'category_id') String? categoryId,
      @JsonKey(name: 'created_by') String? createdBy,
      String name,
      double latitude,
      double longitude,
      String? address,
      String? memo,
      String source,
      Map<String, dynamic> detail,
      @JsonKey(name: 'visit_days') List<int> visitDays,
      @JsonKey(name: 'deleted_at') DateTime? deletedAt,
      @JsonKey(name: 'created_at') DateTime createdAt});
}

/// @nodoc
class _$MarkerModelCopyWithImpl<$Res> implements $MarkerModelCopyWith<$Res> {
  _$MarkerModelCopyWithImpl(this._self, this._then);

  final MarkerModel _self;
  final $Res Function(MarkerModel) _then;

  /// Create a copy of MarkerModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? tripId = null,
    Object? categoryId = freezed,
    Object? createdBy = freezed,
    Object? name = null,
    Object? latitude = null,
    Object? longitude = null,
    Object? address = freezed,
    Object? memo = freezed,
    Object? source = null,
    Object? detail = null,
    Object? visitDays = null,
    Object? deletedAt = freezed,
    Object? createdAt = null,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      tripId: null == tripId
          ? _self.tripId
          : tripId // ignore: cast_nullable_to_non_nullable
              as String,
      categoryId: freezed == categoryId
          ? _self.categoryId
          : categoryId // ignore: cast_nullable_to_non_nullable
              as String?,
      createdBy: freezed == createdBy
          ? _self.createdBy
          : createdBy // ignore: cast_nullable_to_non_nullable
              as String?,
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      latitude: null == latitude
          ? _self.latitude
          : latitude // ignore: cast_nullable_to_non_nullable
              as double,
      longitude: null == longitude
          ? _self.longitude
          : longitude // ignore: cast_nullable_to_non_nullable
              as double,
      address: freezed == address
          ? _self.address
          : address // ignore: cast_nullable_to_non_nullable
              as String?,
      memo: freezed == memo
          ? _self.memo
          : memo // ignore: cast_nullable_to_non_nullable
              as String?,
      source: null == source
          ? _self.source
          : source // ignore: cast_nullable_to_non_nullable
              as String,
      detail: null == detail
          ? _self.detail
          : detail // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      visitDays: null == visitDays
          ? _self.visitDays
          : visitDays // ignore: cast_nullable_to_non_nullable
              as List<int>,
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

/// Adds pattern-matching-related methods to [MarkerModel].
extension MarkerModelPatterns on MarkerModel {
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
    TResult Function(_MarkerModel value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _MarkerModel() when $default != null:
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
    TResult Function(_MarkerModel value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MarkerModel():
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
    TResult? Function(_MarkerModel value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MarkerModel() when $default != null:
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
            @JsonKey(name: 'trip_id') String tripId,
            @JsonKey(name: 'category_id') String? categoryId,
            @JsonKey(name: 'created_by') String? createdBy,
            String name,
            double latitude,
            double longitude,
            String? address,
            String? memo,
            String source,
            Map<String, dynamic> detail,
            @JsonKey(name: 'visit_days') List<int> visitDays,
            @JsonKey(name: 'deleted_at') DateTime? deletedAt,
            @JsonKey(name: 'created_at') DateTime createdAt)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _MarkerModel() when $default != null:
        return $default(
            _that.id,
            _that.tripId,
            _that.categoryId,
            _that.createdBy,
            _that.name,
            _that.latitude,
            _that.longitude,
            _that.address,
            _that.memo,
            _that.source,
            _that.detail,
            _that.visitDays,
            _that.deletedAt,
            _that.createdAt);
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
            @JsonKey(name: 'trip_id') String tripId,
            @JsonKey(name: 'category_id') String? categoryId,
            @JsonKey(name: 'created_by') String? createdBy,
            String name,
            double latitude,
            double longitude,
            String? address,
            String? memo,
            String source,
            Map<String, dynamic> detail,
            @JsonKey(name: 'visit_days') List<int> visitDays,
            @JsonKey(name: 'deleted_at') DateTime? deletedAt,
            @JsonKey(name: 'created_at') DateTime createdAt)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MarkerModel():
        return $default(
            _that.id,
            _that.tripId,
            _that.categoryId,
            _that.createdBy,
            _that.name,
            _that.latitude,
            _that.longitude,
            _that.address,
            _that.memo,
            _that.source,
            _that.detail,
            _that.visitDays,
            _that.deletedAt,
            _that.createdAt);
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
            @JsonKey(name: 'trip_id') String tripId,
            @JsonKey(name: 'category_id') String? categoryId,
            @JsonKey(name: 'created_by') String? createdBy,
            String name,
            double latitude,
            double longitude,
            String? address,
            String? memo,
            String source,
            Map<String, dynamic> detail,
            @JsonKey(name: 'visit_days') List<int> visitDays,
            @JsonKey(name: 'deleted_at') DateTime? deletedAt,
            @JsonKey(name: 'created_at') DateTime createdAt)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MarkerModel() when $default != null:
        return $default(
            _that.id,
            _that.tripId,
            _that.categoryId,
            _that.createdBy,
            _that.name,
            _that.latitude,
            _that.longitude,
            _that.address,
            _that.memo,
            _that.source,
            _that.detail,
            _that.visitDays,
            _that.deletedAt,
            _that.createdAt);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _MarkerModel implements MarkerModel {
  const _MarkerModel(
      {required this.id,
      @JsonKey(name: 'trip_id') required this.tripId,
      @JsonKey(name: 'category_id') this.categoryId,
      @JsonKey(name: 'created_by') this.createdBy,
      required this.name,
      required this.latitude,
      required this.longitude,
      this.address,
      this.memo,
      required this.source,
      required final Map<String, dynamic> detail,
      @JsonKey(name: 'visit_days') final List<int> visitDays = const [],
      @JsonKey(name: 'deleted_at') this.deletedAt,
      @JsonKey(name: 'created_at') required this.createdAt})
      : _detail = detail,
        _visitDays = visitDays;
  factory _MarkerModel.fromJson(Map<String, dynamic> json) =>
      _$MarkerModelFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'trip_id')
  final String tripId;
  @override
  @JsonKey(name: 'category_id')
  final String? categoryId;
  @override
  @JsonKey(name: 'created_by')
  final String? createdBy;
  @override
  final String name;
  @override
  final double latitude;
  @override
  final double longitude;
  @override
  final String? address;
  @override
  final String? memo;
  @override
  final String source;
  final Map<String, dynamic> _detail;
  @override
  Map<String, dynamic> get detail {
    if (_detail is EqualUnmodifiableMapView) return _detail;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_detail);
  }

  final List<int> _visitDays;
  @override
  @JsonKey(name: 'visit_days')
  List<int> get visitDays {
    if (_visitDays is EqualUnmodifiableListView) return _visitDays;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_visitDays);
  }

  @override
  @JsonKey(name: 'deleted_at')
  final DateTime? deletedAt;
  @override
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  /// Create a copy of MarkerModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$MarkerModelCopyWith<_MarkerModel> get copyWith =>
      __$MarkerModelCopyWithImpl<_MarkerModel>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$MarkerModelToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _MarkerModel &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.tripId, tripId) || other.tripId == tripId) &&
            (identical(other.categoryId, categoryId) ||
                other.categoryId == categoryId) &&
            (identical(other.createdBy, createdBy) ||
                other.createdBy == createdBy) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.latitude, latitude) ||
                other.latitude == latitude) &&
            (identical(other.longitude, longitude) ||
                other.longitude == longitude) &&
            (identical(other.address, address) || other.address == address) &&
            (identical(other.memo, memo) || other.memo == memo) &&
            (identical(other.source, source) || other.source == source) &&
            const DeepCollectionEquality().equals(other._detail, _detail) &&
            const DeepCollectionEquality()
                .equals(other._visitDays, _visitDays) &&
            (identical(other.deletedAt, deletedAt) ||
                other.deletedAt == deletedAt) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      tripId,
      categoryId,
      createdBy,
      name,
      latitude,
      longitude,
      address,
      memo,
      source,
      const DeepCollectionEquality().hash(_detail),
      const DeepCollectionEquality().hash(_visitDays),
      deletedAt,
      createdAt);

  @override
  String toString() {
    return 'MarkerModel(id: $id, tripId: $tripId, categoryId: $categoryId, createdBy: $createdBy, name: $name, latitude: $latitude, longitude: $longitude, address: $address, memo: $memo, source: $source, detail: $detail, visitDays: $visitDays, deletedAt: $deletedAt, createdAt: $createdAt)';
  }
}

/// @nodoc
abstract mixin class _$MarkerModelCopyWith<$Res>
    implements $MarkerModelCopyWith<$Res> {
  factory _$MarkerModelCopyWith(
          _MarkerModel value, $Res Function(_MarkerModel) _then) =
      __$MarkerModelCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'trip_id') String tripId,
      @JsonKey(name: 'category_id') String? categoryId,
      @JsonKey(name: 'created_by') String? createdBy,
      String name,
      double latitude,
      double longitude,
      String? address,
      String? memo,
      String source,
      Map<String, dynamic> detail,
      @JsonKey(name: 'visit_days') List<int> visitDays,
      @JsonKey(name: 'deleted_at') DateTime? deletedAt,
      @JsonKey(name: 'created_at') DateTime createdAt});
}

/// @nodoc
class __$MarkerModelCopyWithImpl<$Res> implements _$MarkerModelCopyWith<$Res> {
  __$MarkerModelCopyWithImpl(this._self, this._then);

  final _MarkerModel _self;
  final $Res Function(_MarkerModel) _then;

  /// Create a copy of MarkerModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? tripId = null,
    Object? categoryId = freezed,
    Object? createdBy = freezed,
    Object? name = null,
    Object? latitude = null,
    Object? longitude = null,
    Object? address = freezed,
    Object? memo = freezed,
    Object? source = null,
    Object? detail = null,
    Object? visitDays = null,
    Object? deletedAt = freezed,
    Object? createdAt = null,
  }) {
    return _then(_MarkerModel(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      tripId: null == tripId
          ? _self.tripId
          : tripId // ignore: cast_nullable_to_non_nullable
              as String,
      categoryId: freezed == categoryId
          ? _self.categoryId
          : categoryId // ignore: cast_nullable_to_non_nullable
              as String?,
      createdBy: freezed == createdBy
          ? _self.createdBy
          : createdBy // ignore: cast_nullable_to_non_nullable
              as String?,
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      latitude: null == latitude
          ? _self.latitude
          : latitude // ignore: cast_nullable_to_non_nullable
              as double,
      longitude: null == longitude
          ? _self.longitude
          : longitude // ignore: cast_nullable_to_non_nullable
              as double,
      address: freezed == address
          ? _self.address
          : address // ignore: cast_nullable_to_non_nullable
              as String?,
      memo: freezed == memo
          ? _self.memo
          : memo // ignore: cast_nullable_to_non_nullable
              as String?,
      source: null == source
          ? _self.source
          : source // ignore: cast_nullable_to_non_nullable
              as String,
      detail: null == detail
          ? _self._detail
          : detail // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      visitDays: null == visitDays
          ? _self._visitDays
          : visitDays // ignore: cast_nullable_to_non_nullable
              as List<int>,
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
