// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'trip_route.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TripRoute {
  String get id;
  String get tripId;
  String? get createdBy;
  String get title;
  String? get description;
  TransportMode get transportMode;
  DateTime get createdAt;
  DateTime get updatedAt;

  /// Create a copy of TripRoute
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $TripRouteCopyWith<TripRoute> get copyWith =>
      _$TripRouteCopyWithImpl<TripRoute>(this as TripRoute, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is TripRoute &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.tripId, tripId) || other.tripId == tripId) &&
            (identical(other.createdBy, createdBy) ||
                other.createdBy == createdBy) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.transportMode, transportMode) ||
                other.transportMode == transportMode) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @override
  int get hashCode => Object.hash(runtimeType, id, tripId, createdBy, title,
      description, transportMode, createdAt, updatedAt);

  @override
  String toString() {
    return 'TripRoute(id: $id, tripId: $tripId, createdBy: $createdBy, title: $title, description: $description, transportMode: $transportMode, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}

/// @nodoc
abstract mixin class $TripRouteCopyWith<$Res> {
  factory $TripRouteCopyWith(TripRoute value, $Res Function(TripRoute) _then) =
      _$TripRouteCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      String tripId,
      String? createdBy,
      String title,
      String? description,
      TransportMode transportMode,
      DateTime createdAt,
      DateTime updatedAt});
}

/// @nodoc
class _$TripRouteCopyWithImpl<$Res> implements $TripRouteCopyWith<$Res> {
  _$TripRouteCopyWithImpl(this._self, this._then);

  final TripRoute _self;
  final $Res Function(TripRoute) _then;

  /// Create a copy of TripRoute
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? tripId = null,
    Object? createdBy = freezed,
    Object? title = null,
    Object? description = freezed,
    Object? transportMode = null,
    Object? createdAt = null,
    Object? updatedAt = null,
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
      createdBy: freezed == createdBy
          ? _self.createdBy
          : createdBy // ignore: cast_nullable_to_non_nullable
              as String?,
      title: null == title
          ? _self.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _self.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      transportMode: null == transportMode
          ? _self.transportMode
          : transportMode // ignore: cast_nullable_to_non_nullable
              as TransportMode,
      createdAt: null == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _self.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// Adds pattern-matching-related methods to [TripRoute].
extension TripRoutePatterns on TripRoute {
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
    TResult Function(_TripRoute value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _TripRoute() when $default != null:
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
    TResult Function(_TripRoute value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TripRoute():
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
    TResult? Function(_TripRoute value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TripRoute() when $default != null:
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
            String? createdBy,
            String title,
            String? description,
            TransportMode transportMode,
            DateTime createdAt,
            DateTime updatedAt)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _TripRoute() when $default != null:
        return $default(
            _that.id,
            _that.tripId,
            _that.createdBy,
            _that.title,
            _that.description,
            _that.transportMode,
            _that.createdAt,
            _that.updatedAt);
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
            String? createdBy,
            String title,
            String? description,
            TransportMode transportMode,
            DateTime createdAt,
            DateTime updatedAt)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TripRoute():
        return $default(
            _that.id,
            _that.tripId,
            _that.createdBy,
            _that.title,
            _that.description,
            _that.transportMode,
            _that.createdAt,
            _that.updatedAt);
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
            String? createdBy,
            String title,
            String? description,
            TransportMode transportMode,
            DateTime createdAt,
            DateTime updatedAt)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TripRoute() when $default != null:
        return $default(
            _that.id,
            _that.tripId,
            _that.createdBy,
            _that.title,
            _that.description,
            _that.transportMode,
            _that.createdAt,
            _that.updatedAt);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _TripRoute implements TripRoute {
  const _TripRoute(
      {required this.id,
      required this.tripId,
      this.createdBy,
      required this.title,
      this.description,
      required this.transportMode,
      required this.createdAt,
      required this.updatedAt});

  @override
  final String id;
  @override
  final String tripId;
  @override
  final String? createdBy;
  @override
  final String title;
  @override
  final String? description;
  @override
  final TransportMode transportMode;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;

  /// Create a copy of TripRoute
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$TripRouteCopyWith<_TripRoute> get copyWith =>
      __$TripRouteCopyWithImpl<_TripRoute>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _TripRoute &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.tripId, tripId) || other.tripId == tripId) &&
            (identical(other.createdBy, createdBy) ||
                other.createdBy == createdBy) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.transportMode, transportMode) ||
                other.transportMode == transportMode) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @override
  int get hashCode => Object.hash(runtimeType, id, tripId, createdBy, title,
      description, transportMode, createdAt, updatedAt);

  @override
  String toString() {
    return 'TripRoute(id: $id, tripId: $tripId, createdBy: $createdBy, title: $title, description: $description, transportMode: $transportMode, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}

/// @nodoc
abstract mixin class _$TripRouteCopyWith<$Res>
    implements $TripRouteCopyWith<$Res> {
  factory _$TripRouteCopyWith(
          _TripRoute value, $Res Function(_TripRoute) _then) =
      __$TripRouteCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      String tripId,
      String? createdBy,
      String title,
      String? description,
      TransportMode transportMode,
      DateTime createdAt,
      DateTime updatedAt});
}

/// @nodoc
class __$TripRouteCopyWithImpl<$Res> implements _$TripRouteCopyWith<$Res> {
  __$TripRouteCopyWithImpl(this._self, this._then);

  final _TripRoute _self;
  final $Res Function(_TripRoute) _then;

  /// Create a copy of TripRoute
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? tripId = null,
    Object? createdBy = freezed,
    Object? title = null,
    Object? description = freezed,
    Object? transportMode = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_TripRoute(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      tripId: null == tripId
          ? _self.tripId
          : tripId // ignore: cast_nullable_to_non_nullable
              as String,
      createdBy: freezed == createdBy
          ? _self.createdBy
          : createdBy // ignore: cast_nullable_to_non_nullable
              as String?,
      title: null == title
          ? _self.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _self.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      transportMode: null == transportMode
          ? _self.transportMode
          : transportMode // ignore: cast_nullable_to_non_nullable
              as TransportMode,
      createdAt: null == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _self.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
mixin _$RouteWaypoint {
  String get id;
  String get routeId;
  String get markerId;
  int get order;

  /// Create a copy of RouteWaypoint
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $RouteWaypointCopyWith<RouteWaypoint> get copyWith =>
      _$RouteWaypointCopyWithImpl<RouteWaypoint>(
          this as RouteWaypoint, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is RouteWaypoint &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.routeId, routeId) || other.routeId == routeId) &&
            (identical(other.markerId, markerId) ||
                other.markerId == markerId) &&
            (identical(other.order, order) || other.order == order));
  }

  @override
  int get hashCode => Object.hash(runtimeType, id, routeId, markerId, order);

  @override
  String toString() {
    return 'RouteWaypoint(id: $id, routeId: $routeId, markerId: $markerId, order: $order)';
  }
}

/// @nodoc
abstract mixin class $RouteWaypointCopyWith<$Res> {
  factory $RouteWaypointCopyWith(
          RouteWaypoint value, $Res Function(RouteWaypoint) _then) =
      _$RouteWaypointCopyWithImpl;
  @useResult
  $Res call({String id, String routeId, String markerId, int order});
}

/// @nodoc
class _$RouteWaypointCopyWithImpl<$Res>
    implements $RouteWaypointCopyWith<$Res> {
  _$RouteWaypointCopyWithImpl(this._self, this._then);

  final RouteWaypoint _self;
  final $Res Function(RouteWaypoint) _then;

  /// Create a copy of RouteWaypoint
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? routeId = null,
    Object? markerId = null,
    Object? order = null,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      routeId: null == routeId
          ? _self.routeId
          : routeId // ignore: cast_nullable_to_non_nullable
              as String,
      markerId: null == markerId
          ? _self.markerId
          : markerId // ignore: cast_nullable_to_non_nullable
              as String,
      order: null == order
          ? _self.order
          : order // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// Adds pattern-matching-related methods to [RouteWaypoint].
extension RouteWaypointPatterns on RouteWaypoint {
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
    TResult Function(_RouteWaypoint value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _RouteWaypoint() when $default != null:
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
    TResult Function(_RouteWaypoint value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RouteWaypoint():
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
    TResult? Function(_RouteWaypoint value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RouteWaypoint() when $default != null:
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
    TResult Function(String id, String routeId, String markerId, int order)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _RouteWaypoint() when $default != null:
        return $default(_that.id, _that.routeId, _that.markerId, _that.order);
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
    TResult Function(String id, String routeId, String markerId, int order)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RouteWaypoint():
        return $default(_that.id, _that.routeId, _that.markerId, _that.order);
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
    TResult? Function(String id, String routeId, String markerId, int order)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RouteWaypoint() when $default != null:
        return $default(_that.id, _that.routeId, _that.markerId, _that.order);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _RouteWaypoint implements RouteWaypoint {
  const _RouteWaypoint(
      {required this.id,
      required this.routeId,
      required this.markerId,
      required this.order});

  @override
  final String id;
  @override
  final String routeId;
  @override
  final String markerId;
  @override
  final int order;

  /// Create a copy of RouteWaypoint
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$RouteWaypointCopyWith<_RouteWaypoint> get copyWith =>
      __$RouteWaypointCopyWithImpl<_RouteWaypoint>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _RouteWaypoint &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.routeId, routeId) || other.routeId == routeId) &&
            (identical(other.markerId, markerId) ||
                other.markerId == markerId) &&
            (identical(other.order, order) || other.order == order));
  }

  @override
  int get hashCode => Object.hash(runtimeType, id, routeId, markerId, order);

  @override
  String toString() {
    return 'RouteWaypoint(id: $id, routeId: $routeId, markerId: $markerId, order: $order)';
  }
}

/// @nodoc
abstract mixin class _$RouteWaypointCopyWith<$Res>
    implements $RouteWaypointCopyWith<$Res> {
  factory _$RouteWaypointCopyWith(
          _RouteWaypoint value, $Res Function(_RouteWaypoint) _then) =
      __$RouteWaypointCopyWithImpl;
  @override
  @useResult
  $Res call({String id, String routeId, String markerId, int order});
}

/// @nodoc
class __$RouteWaypointCopyWithImpl<$Res>
    implements _$RouteWaypointCopyWith<$Res> {
  __$RouteWaypointCopyWithImpl(this._self, this._then);

  final _RouteWaypoint _self;
  final $Res Function(_RouteWaypoint) _then;

  /// Create a copy of RouteWaypoint
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? routeId = null,
    Object? markerId = null,
    Object? order = null,
  }) {
    return _then(_RouteWaypoint(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      routeId: null == routeId
          ? _self.routeId
          : routeId // ignore: cast_nullable_to_non_nullable
              as String,
      markerId: null == markerId
          ? _self.markerId
          : markerId // ignore: cast_nullable_to_non_nullable
              as String,
      order: null == order
          ? _self.order
          : order // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

// dart format on
