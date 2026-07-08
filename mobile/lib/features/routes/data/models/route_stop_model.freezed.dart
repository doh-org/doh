// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'route_stop_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RouteStopModel {
  @JsonKey(name: 'id', readValue: _readMarkerId)
  String get markerId;
  String get name;
  double get latitude;
  double get longitude;
  @JsonKey(name: 'category_id')
  String? get categoryId;
  int get order;
  @JsonKey(name: 'visit_time')
  String? get visitTime;
  @JsonKey(name: 'transport_to_next')
  String? get transportToNext;
  @JsonKey(name: 'distance_to_next')
  double? get distanceToNext;
  @JsonKey(name: 'duration_to_next')
  int? get durationToNext;

  /// Create a copy of RouteStopModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $RouteStopModelCopyWith<RouteStopModel> get copyWith =>
      _$RouteStopModelCopyWithImpl<RouteStopModel>(
          this as RouteStopModel, _$identity);

  /// Serializes this RouteStopModel to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is RouteStopModel &&
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

  @JsonKey(includeFromJson: false, includeToJson: false)
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
    return 'RouteStopModel(markerId: $markerId, name: $name, latitude: $latitude, longitude: $longitude, categoryId: $categoryId, order: $order, visitTime: $visitTime, transportToNext: $transportToNext, distanceToNext: $distanceToNext, durationToNext: $durationToNext)';
  }
}

/// @nodoc
abstract mixin class $RouteStopModelCopyWith<$Res> {
  factory $RouteStopModelCopyWith(
          RouteStopModel value, $Res Function(RouteStopModel) _then) =
      _$RouteStopModelCopyWithImpl;
  @useResult
  $Res call(
      {@JsonKey(name: 'id', readValue: _readMarkerId) String markerId,
      String name,
      double latitude,
      double longitude,
      @JsonKey(name: 'category_id') String? categoryId,
      int order,
      @JsonKey(name: 'visit_time') String? visitTime,
      @JsonKey(name: 'transport_to_next') String? transportToNext,
      @JsonKey(name: 'distance_to_next') double? distanceToNext,
      @JsonKey(name: 'duration_to_next') int? durationToNext});
}

/// @nodoc
class _$RouteStopModelCopyWithImpl<$Res>
    implements $RouteStopModelCopyWith<$Res> {
  _$RouteStopModelCopyWithImpl(this._self, this._then);

  final RouteStopModel _self;
  final $Res Function(RouteStopModel) _then;

  /// Create a copy of RouteStopModel
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
              as String?,
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

/// Adds pattern-matching-related methods to [RouteStopModel].
extension RouteStopModelPatterns on RouteStopModel {
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
    TResult Function(_RouteStopModel value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _RouteStopModel() when $default != null:
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
    TResult Function(_RouteStopModel value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RouteStopModel():
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
    TResult? Function(_RouteStopModel value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RouteStopModel() when $default != null:
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
            @JsonKey(name: 'id', readValue: _readMarkerId) String markerId,
            String name,
            double latitude,
            double longitude,
            @JsonKey(name: 'category_id') String? categoryId,
            int order,
            @JsonKey(name: 'visit_time') String? visitTime,
            @JsonKey(name: 'transport_to_next') String? transportToNext,
            @JsonKey(name: 'distance_to_next') double? distanceToNext,
            @JsonKey(name: 'duration_to_next') int? durationToNext)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _RouteStopModel() when $default != null:
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
            @JsonKey(name: 'id', readValue: _readMarkerId) String markerId,
            String name,
            double latitude,
            double longitude,
            @JsonKey(name: 'category_id') String? categoryId,
            int order,
            @JsonKey(name: 'visit_time') String? visitTime,
            @JsonKey(name: 'transport_to_next') String? transportToNext,
            @JsonKey(name: 'distance_to_next') double? distanceToNext,
            @JsonKey(name: 'duration_to_next') int? durationToNext)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RouteStopModel():
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
            @JsonKey(name: 'id', readValue: _readMarkerId) String markerId,
            String name,
            double latitude,
            double longitude,
            @JsonKey(name: 'category_id') String? categoryId,
            int order,
            @JsonKey(name: 'visit_time') String? visitTime,
            @JsonKey(name: 'transport_to_next') String? transportToNext,
            @JsonKey(name: 'distance_to_next') double? distanceToNext,
            @JsonKey(name: 'duration_to_next') int? durationToNext)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RouteStopModel() when $default != null:
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
@JsonSerializable()
class _RouteStopModel implements RouteStopModel {
  const _RouteStopModel(
      {@JsonKey(name: 'id', readValue: _readMarkerId) required this.markerId,
      required this.name,
      required this.latitude,
      required this.longitude,
      @JsonKey(name: 'category_id') this.categoryId,
      required this.order,
      @JsonKey(name: 'visit_time') this.visitTime,
      @JsonKey(name: 'transport_to_next') this.transportToNext,
      @JsonKey(name: 'distance_to_next') this.distanceToNext,
      @JsonKey(name: 'duration_to_next') this.durationToNext});
  factory _RouteStopModel.fromJson(Map<String, dynamic> json) =>
      _$RouteStopModelFromJson(json);

  @override
  @JsonKey(name: 'id', readValue: _readMarkerId)
  final String markerId;
  @override
  final String name;
  @override
  final double latitude;
  @override
  final double longitude;
  @override
  @JsonKey(name: 'category_id')
  final String? categoryId;
  @override
  final int order;
  @override
  @JsonKey(name: 'visit_time')
  final String? visitTime;
  @override
  @JsonKey(name: 'transport_to_next')
  final String? transportToNext;
  @override
  @JsonKey(name: 'distance_to_next')
  final double? distanceToNext;
  @override
  @JsonKey(name: 'duration_to_next')
  final int? durationToNext;

  /// Create a copy of RouteStopModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$RouteStopModelCopyWith<_RouteStopModel> get copyWith =>
      __$RouteStopModelCopyWithImpl<_RouteStopModel>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$RouteStopModelToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _RouteStopModel &&
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

  @JsonKey(includeFromJson: false, includeToJson: false)
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
    return 'RouteStopModel(markerId: $markerId, name: $name, latitude: $latitude, longitude: $longitude, categoryId: $categoryId, order: $order, visitTime: $visitTime, transportToNext: $transportToNext, distanceToNext: $distanceToNext, durationToNext: $durationToNext)';
  }
}

/// @nodoc
abstract mixin class _$RouteStopModelCopyWith<$Res>
    implements $RouteStopModelCopyWith<$Res> {
  factory _$RouteStopModelCopyWith(
          _RouteStopModel value, $Res Function(_RouteStopModel) _then) =
      __$RouteStopModelCopyWithImpl;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'id', readValue: _readMarkerId) String markerId,
      String name,
      double latitude,
      double longitude,
      @JsonKey(name: 'category_id') String? categoryId,
      int order,
      @JsonKey(name: 'visit_time') String? visitTime,
      @JsonKey(name: 'transport_to_next') String? transportToNext,
      @JsonKey(name: 'distance_to_next') double? distanceToNext,
      @JsonKey(name: 'duration_to_next') int? durationToNext});
}

/// @nodoc
class __$RouteStopModelCopyWithImpl<$Res>
    implements _$RouteStopModelCopyWith<$Res> {
  __$RouteStopModelCopyWithImpl(this._self, this._then);

  final _RouteStopModel _self;
  final $Res Function(_RouteStopModel) _then;

  /// Create a copy of RouteStopModel
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
    return _then(_RouteStopModel(
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
              as String?,
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
