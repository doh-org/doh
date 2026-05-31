// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'marker.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TripMarker {
  String get id;
  String get tripId;
  String? get categoryId;
  String? get createdBy;
  String get name;
  double get latitude;
  double get longitude;
  String? get address;
  String? get memo;
  MarkerSource get source;
  Map<String, dynamic> get detail;
  DateTime? get visitTime;
  DateTime? get deletedAt;
  DateTime get createdAt;

  /// Create a copy of TripMarker
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $TripMarkerCopyWith<TripMarker> get copyWith =>
      _$TripMarkerCopyWithImpl<TripMarker>(this as TripMarker, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is TripMarker &&
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
            (identical(other.visitTime, visitTime) ||
                other.visitTime == visitTime) &&
            (identical(other.deletedAt, deletedAt) ||
                other.deletedAt == deletedAt) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

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
      visitTime,
      deletedAt,
      createdAt);

  @override
  String toString() {
    return 'TripMarker(id: $id, tripId: $tripId, categoryId: $categoryId, createdBy: $createdBy, name: $name, latitude: $latitude, longitude: $longitude, address: $address, memo: $memo, source: $source, detail: $detail, visitTime: $visitTime, deletedAt: $deletedAt, createdAt: $createdAt)';
  }
}

/// @nodoc
abstract mixin class $TripMarkerCopyWith<$Res> {
  factory $TripMarkerCopyWith(
          TripMarker value, $Res Function(TripMarker) _then) =
      _$TripMarkerCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      String tripId,
      String? categoryId,
      String? createdBy,
      String name,
      double latitude,
      double longitude,
      String? address,
      String? memo,
      MarkerSource source,
      Map<String, dynamic> detail,
      DateTime? visitTime,
      DateTime? deletedAt,
      DateTime createdAt});
}

/// @nodoc
class _$TripMarkerCopyWithImpl<$Res> implements $TripMarkerCopyWith<$Res> {
  _$TripMarkerCopyWithImpl(this._self, this._then);

  final TripMarker _self;
  final $Res Function(TripMarker) _then;

  /// Create a copy of TripMarker
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
    Object? visitTime = freezed,
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
              as MarkerSource,
      detail: null == detail
          ? _self.detail
          : detail // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      visitTime: freezed == visitTime
          ? _self.visitTime
          : visitTime // ignore: cast_nullable_to_non_nullable
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

/// Adds pattern-matching-related methods to [TripMarker].
extension TripMarkerPatterns on TripMarker {
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
    TResult Function(_TripMarker value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _TripMarker() when $default != null:
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
    TResult Function(_TripMarker value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TripMarker():
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
    TResult? Function(_TripMarker value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TripMarker() when $default != null:
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
            String tripId,
            String? categoryId,
            String? createdBy,
            String name,
            double latitude,
            double longitude,
            String? address,
            String? memo,
            MarkerSource source,
            Map<String, dynamic> detail,
            DateTime? visitTime,
            DateTime? deletedAt,
            DateTime createdAt)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _TripMarker() when $default != null:
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
            _that.visitTime,
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
            String tripId,
            String? categoryId,
            String? createdBy,
            String name,
            double latitude,
            double longitude,
            String? address,
            String? memo,
            MarkerSource source,
            Map<String, dynamic> detail,
            DateTime? visitTime,
            DateTime? deletedAt,
            DateTime createdAt)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TripMarker():
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
            _that.visitTime,
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
            String tripId,
            String? categoryId,
            String? createdBy,
            String name,
            double latitude,
            double longitude,
            String? address,
            String? memo,
            MarkerSource source,
            Map<String, dynamic> detail,
            DateTime? visitTime,
            DateTime? deletedAt,
            DateTime createdAt)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TripMarker() when $default != null:
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
            _that.visitTime,
            _that.deletedAt,
            _that.createdAt);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _TripMarker implements TripMarker {
  const _TripMarker(
      {required this.id,
      required this.tripId,
      this.categoryId,
      this.createdBy,
      required this.name,
      required this.latitude,
      required this.longitude,
      this.address,
      this.memo,
      required this.source,
      required final Map<String, dynamic> detail,
      this.visitTime,
      this.deletedAt,
      required this.createdAt})
      : _detail = detail;

  @override
  final String id;
  @override
  final String tripId;
  @override
  final String? categoryId;
  @override
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
  final MarkerSource source;
  final Map<String, dynamic> _detail;
  @override
  Map<String, dynamic> get detail {
    if (_detail is EqualUnmodifiableMapView) return _detail;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_detail);
  }

  @override
  final DateTime? visitTime;
  @override
  final DateTime? deletedAt;
  @override
  final DateTime createdAt;

  /// Create a copy of TripMarker
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$TripMarkerCopyWith<_TripMarker> get copyWith =>
      __$TripMarkerCopyWithImpl<_TripMarker>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _TripMarker &&
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
            (identical(other.visitTime, visitTime) ||
                other.visitTime == visitTime) &&
            (identical(other.deletedAt, deletedAt) ||
                other.deletedAt == deletedAt) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

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
      visitTime,
      deletedAt,
      createdAt);

  @override
  String toString() {
    return 'TripMarker(id: $id, tripId: $tripId, categoryId: $categoryId, createdBy: $createdBy, name: $name, latitude: $latitude, longitude: $longitude, address: $address, memo: $memo, source: $source, detail: $detail, visitTime: $visitTime, deletedAt: $deletedAt, createdAt: $createdAt)';
  }
}

/// @nodoc
abstract mixin class _$TripMarkerCopyWith<$Res>
    implements $TripMarkerCopyWith<$Res> {
  factory _$TripMarkerCopyWith(
          _TripMarker value, $Res Function(_TripMarker) _then) =
      __$TripMarkerCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      String tripId,
      String? categoryId,
      String? createdBy,
      String name,
      double latitude,
      double longitude,
      String? address,
      String? memo,
      MarkerSource source,
      Map<String, dynamic> detail,
      DateTime? visitTime,
      DateTime? deletedAt,
      DateTime createdAt});
}

/// @nodoc
class __$TripMarkerCopyWithImpl<$Res> implements _$TripMarkerCopyWith<$Res> {
  __$TripMarkerCopyWithImpl(this._self, this._then);

  final _TripMarker _self;
  final $Res Function(_TripMarker) _then;

  /// Create a copy of TripMarker
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
    Object? visitTime = freezed,
    Object? deletedAt = freezed,
    Object? createdAt = null,
  }) {
    return _then(_TripMarker(
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
              as MarkerSource,
      detail: null == detail
          ? _self._detail
          : detail // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      visitTime: freezed == visitTime
          ? _self.visitTime
          : visitTime // ignore: cast_nullable_to_non_nullable
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
