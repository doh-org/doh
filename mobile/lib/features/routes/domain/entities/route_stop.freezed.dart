// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'route_stop.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RouteStop {
  String get markerId;
  String get name;
  double get latitude;
  double get longitude;
  String? get categoryId;
  int get order;
  String? get visitTime; // "HH:MM:SS" 또는 null
  TransportMode? get transportToNext; // null = 미설정
  double? get distanceToNext;
  int? get durationToNext;

  /// Create a copy of RouteStop
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $RouteStopCopyWith<RouteStop> get copyWith =>
      _$RouteStopCopyWithImpl<RouteStop>(this as RouteStop, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is RouteStop &&
            (identical(other.markerId, markerId) ||
                other.markerId == markerId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.latitude, latitude) ||
                other.latitude == latitude) &&
            (identical(other.longitude, longitude) ||
                other.longitude == longitude) &&
            (identical(other.categoryId, categoryId) ||
                other.categoryId == categoryId) &&
            (identical(other.order, order) || other.order == order) &&
            (identical(other.visitTime, visitTime) ||
                other.visitTime == visitTime) &&
            (identical(other.transportToNext, transportToNext) ||
                other.transportToNext == transportToNext) &&
            (identical(other.distanceToNext, distanceToNext) ||
                other.distanceToNext == distanceToNext) &&
            (identical(other.durationToNext, durationToNext) ||
                other.durationToNext == durationToNext));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      markerId,
      name,
      latitude,
      longitude,
      categoryId,
      order,
      visitTime,
      transportToNext,
      distanceToNext,
      durationToNext);

  @override
  String toString() {
    return 'RouteStop(markerId: $markerId, name: $name, latitude: $latitude, longitude: $longitude, categoryId: $categoryId, order: $order, visitTime: $visitTime, transportToNext: $transportToNext, distanceToNext: $distanceToNext, durationToNext: $durationToNext)';
  }
}

/// @nodoc
abstract mixin class $RouteStopCopyWith<$Res> {
  factory $RouteStopCopyWith(RouteStop value, $Res Function(RouteStop) _then) =
      _$RouteStopCopyWithImpl;
  @useResult
  $Res call(
      {String markerId,
      String name,
      double latitude,
      double longitude,
      String? categoryId,
      int order,
      String? visitTime,
      TransportMode? transportToNext,
      double? distanceToNext,
      int? durationToNext});
}

/// @nodoc
class _$RouteStopCopyWithImpl<$Res> implements $RouteStopCopyWith<$Res> {
  _$RouteStopCopyWithImpl(this._self, this._then);

  final RouteStop _self;
  final $Res Function(RouteStop) _then;

  /// Create a copy of RouteStop
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? markerId = null,
    Object? name = null,
    Object? latitude = null,
    Object? longitude = null,
    Object? categoryId = freezed,
    Object? order = null,
    Object? visitTime = freezed,
    Object? transportToNext = freezed,
    Object? distanceToNext = freezed,
    Object? durationToNext = freezed,
  }) {
    return _then(_self.copyWith(
      markerId: null == markerId
          ? _self.markerId
          : markerId // ignore: cast_nullable_to_non_nullable
              as String,
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
      categoryId: freezed == categoryId
          ? _self.categoryId
          : categoryId // ignore: cast_nullable_to_non_nullable
              as String?,
      order: null == order
          ? _self.order
          : order // ignore: cast_nullable_to_non_nullable
              as int,
      visitTime: freezed == visitTime
          ? _self.visitTime
          : visitTime // ignore: cast_nullable_to_non_nullable
              as String?,
      transportToNext: freezed == transportToNext
          ? _self.transportToNext
          : transportToNext // ignore: cast_nullable_to_non_nullable
              as TransportMode?,
      distanceToNext: freezed == distanceToNext
          ? _self.distanceToNext
          : distanceToNext // ignore: cast_nullable_to_non_nullable
              as double?,
      durationToNext: freezed == durationToNext
          ? _self.durationToNext
          : durationToNext // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// Adds pattern-matching-related methods to [RouteStop].
extension RouteStopPatterns on RouteStop {
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
    TResult Function(_RouteStop value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _RouteStop() when $default != null:
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
    TResult Function(_RouteStop value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RouteStop():
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
    TResult? Function(_RouteStop value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RouteStop() when $default != null:
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
            String markerId,
            String name,
            double latitude,
            double longitude,
            String? categoryId,
            int order,
            String? visitTime,
            TransportMode? transportToNext,
            double? distanceToNext,
            int? durationToNext)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _RouteStop() when $default != null:
        return $default(
            _that.markerId,
            _that.name,
            _that.latitude,
            _that.longitude,
            _that.categoryId,
            _that.order,
            _that.visitTime,
            _that.transportToNext,
            _that.distanceToNext,
            _that.durationToNext);
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
            String markerId,
            String name,
            double latitude,
            double longitude,
            String? categoryId,
            int order,
            String? visitTime,
            TransportMode? transportToNext,
            double? distanceToNext,
            int? durationToNext)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RouteStop():
        return $default(
            _that.markerId,
            _that.name,
            _that.latitude,
            _that.longitude,
            _that.categoryId,
            _that.order,
            _that.visitTime,
            _that.transportToNext,
            _that.distanceToNext,
            _that.durationToNext);
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
            String markerId,
            String name,
            double latitude,
            double longitude,
            String? categoryId,
            int order,
            String? visitTime,
            TransportMode? transportToNext,
            double? distanceToNext,
            int? durationToNext)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RouteStop() when $default != null:
        return $default(
            _that.markerId,
            _that.name,
            _that.latitude,
            _that.longitude,
            _that.categoryId,
            _that.order,
            _that.visitTime,
            _that.transportToNext,
            _that.distanceToNext,
            _that.durationToNext);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _RouteStop implements RouteStop {
  const _RouteStop(
      {required this.markerId,
      required this.name,
      required this.latitude,
      required this.longitude,
      this.categoryId,
      required this.order,
      this.visitTime,
      this.transportToNext,
      this.distanceToNext,
      this.durationToNext});

  @override
  final String markerId;
  @override
  final String name;
  @override
  final double latitude;
  @override
  final double longitude;
  @override
  final String? categoryId;
  @override
  final int order;
  @override
  final String? visitTime;
// "HH:MM:SS" 또는 null
  @override
  final TransportMode? transportToNext;
// null = 미설정
  @override
  final double? distanceToNext;
  @override
  final int? durationToNext;

  /// Create a copy of RouteStop
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$RouteStopCopyWith<_RouteStop> get copyWith =>
      __$RouteStopCopyWithImpl<_RouteStop>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _RouteStop &&
            (identical(other.markerId, markerId) ||
                other.markerId == markerId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.latitude, latitude) ||
                other.latitude == latitude) &&
            (identical(other.longitude, longitude) ||
                other.longitude == longitude) &&
            (identical(other.categoryId, categoryId) ||
                other.categoryId == categoryId) &&
            (identical(other.order, order) || other.order == order) &&
            (identical(other.visitTime, visitTime) ||
                other.visitTime == visitTime) &&
            (identical(other.transportToNext, transportToNext) ||
                other.transportToNext == transportToNext) &&
            (identical(other.distanceToNext, distanceToNext) ||
                other.distanceToNext == distanceToNext) &&
            (identical(other.durationToNext, durationToNext) ||
                other.durationToNext == durationToNext));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      markerId,
      name,
      latitude,
      longitude,
      categoryId,
      order,
      visitTime,
      transportToNext,
      distanceToNext,
      durationToNext);

  @override
  String toString() {
    return 'RouteStop(markerId: $markerId, name: $name, latitude: $latitude, longitude: $longitude, categoryId: $categoryId, order: $order, visitTime: $visitTime, transportToNext: $transportToNext, distanceToNext: $distanceToNext, durationToNext: $durationToNext)';
  }
}

/// @nodoc
abstract mixin class _$RouteStopCopyWith<$Res>
    implements $RouteStopCopyWith<$Res> {
  factory _$RouteStopCopyWith(
          _RouteStop value, $Res Function(_RouteStop) _then) =
      __$RouteStopCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String markerId,
      String name,
      double latitude,
      double longitude,
      String? categoryId,
      int order,
      String? visitTime,
      TransportMode? transportToNext,
      double? distanceToNext,
      int? durationToNext});
}

/// @nodoc
class __$RouteStopCopyWithImpl<$Res> implements _$RouteStopCopyWith<$Res> {
  __$RouteStopCopyWithImpl(this._self, this._then);

  final _RouteStop _self;
  final $Res Function(_RouteStop) _then;

  /// Create a copy of RouteStop
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? markerId = null,
    Object? name = null,
    Object? latitude = null,
    Object? longitude = null,
    Object? categoryId = freezed,
    Object? order = null,
    Object? visitTime = freezed,
    Object? transportToNext = freezed,
    Object? distanceToNext = freezed,
    Object? durationToNext = freezed,
  }) {
    return _then(_RouteStop(
      markerId: null == markerId
          ? _self.markerId
          : markerId // ignore: cast_nullable_to_non_nullable
              as String,
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
      categoryId: freezed == categoryId
          ? _self.categoryId
          : categoryId // ignore: cast_nullable_to_non_nullable
              as String?,
      order: null == order
          ? _self.order
          : order // ignore: cast_nullable_to_non_nullable
              as int,
      visitTime: freezed == visitTime
          ? _self.visitTime
          : visitTime // ignore: cast_nullable_to_non_nullable
              as String?,
      transportToNext: freezed == transportToNext
          ? _self.transportToNext
          : transportToNext // ignore: cast_nullable_to_non_nullable
              as TransportMode?,
      distanceToNext: freezed == distanceToNext
          ? _self.distanceToNext
          : distanceToNext // ignore: cast_nullable_to_non_nullable
              as double?,
      durationToNext: freezed == durationToNext
          ? _self.durationToNext
          : durationToNext // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

// dart format on
