// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'trip_member.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TripMember {
  String get id;
  String get tripId;
  String get userId;
  MemberRole get role;
  DateTime get joinedAt;

  /// Create a copy of TripMember
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $TripMemberCopyWith<TripMember> get copyWith =>
      _$TripMemberCopyWithImpl<TripMember>(this as TripMember, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is TripMember &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.tripId, tripId) || other.tripId == tripId) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.role, role) || other.role == role) &&
            (identical(other.joinedAt, joinedAt) ||
                other.joinedAt == joinedAt));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, id, tripId, userId, role, joinedAt);

  @override
  String toString() {
    return 'TripMember(id: $id, tripId: $tripId, userId: $userId, role: $role, joinedAt: $joinedAt)';
  }
}

/// @nodoc
abstract mixin class $TripMemberCopyWith<$Res> {
  factory $TripMemberCopyWith(
          TripMember value, $Res Function(TripMember) _then) =
      _$TripMemberCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      String tripId,
      String userId,
      MemberRole role,
      DateTime joinedAt});
}

/// @nodoc
class _$TripMemberCopyWithImpl<$Res> implements $TripMemberCopyWith<$Res> {
  _$TripMemberCopyWithImpl(this._self, this._then);

  final TripMember _self;
  final $Res Function(TripMember) _then;

  /// Create a copy of TripMember
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? tripId = null,
    Object? userId = null,
    Object? role = null,
    Object? joinedAt = null,
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
      userId: null == userId
          ? _self.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      role: null == role
          ? _self.role
          : role // ignore: cast_nullable_to_non_nullable
              as MemberRole,
      joinedAt: null == joinedAt
          ? _self.joinedAt
          : joinedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// Adds pattern-matching-related methods to [TripMember].
extension TripMemberPatterns on TripMember {
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
    TResult Function(_TripMember value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _TripMember() when $default != null:
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
    TResult Function(_TripMember value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TripMember():
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
    TResult? Function(_TripMember value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TripMember() when $default != null:
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
    TResult Function(String id, String tripId, String userId, MemberRole role,
            DateTime joinedAt)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _TripMember() when $default != null:
        return $default(
            _that.id, _that.tripId, _that.userId, _that.role, _that.joinedAt);
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
    TResult Function(String id, String tripId, String userId, MemberRole role,
            DateTime joinedAt)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TripMember():
        return $default(
            _that.id, _that.tripId, _that.userId, _that.role, _that.joinedAt);
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
    TResult? Function(String id, String tripId, String userId, MemberRole role,
            DateTime joinedAt)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TripMember() when $default != null:
        return $default(
            _that.id, _that.tripId, _that.userId, _that.role, _that.joinedAt);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _TripMember implements TripMember {
  const _TripMember(
      {required this.id,
      required this.tripId,
      required this.userId,
      required this.role,
      required this.joinedAt});

  @override
  final String id;
  @override
  final String tripId;
  @override
  final String userId;
  @override
  final MemberRole role;
  @override
  final DateTime joinedAt;

  /// Create a copy of TripMember
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$TripMemberCopyWith<_TripMember> get copyWith =>
      __$TripMemberCopyWithImpl<_TripMember>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _TripMember &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.tripId, tripId) || other.tripId == tripId) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.role, role) || other.role == role) &&
            (identical(other.joinedAt, joinedAt) ||
                other.joinedAt == joinedAt));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, id, tripId, userId, role, joinedAt);

  @override
  String toString() {
    return 'TripMember(id: $id, tripId: $tripId, userId: $userId, role: $role, joinedAt: $joinedAt)';
  }
}

/// @nodoc
abstract mixin class _$TripMemberCopyWith<$Res>
    implements $TripMemberCopyWith<$Res> {
  factory _$TripMemberCopyWith(
          _TripMember value, $Res Function(_TripMember) _then) =
      __$TripMemberCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      String tripId,
      String userId,
      MemberRole role,
      DateTime joinedAt});
}

/// @nodoc
class __$TripMemberCopyWithImpl<$Res> implements _$TripMemberCopyWith<$Res> {
  __$TripMemberCopyWithImpl(this._self, this._then);

  final _TripMember _self;
  final $Res Function(_TripMember) _then;

  /// Create a copy of TripMember
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? tripId = null,
    Object? userId = null,
    Object? role = null,
    Object? joinedAt = null,
  }) {
    return _then(_TripMember(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      tripId: null == tripId
          ? _self.tripId
          : tripId // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _self.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      role: null == role
          ? _self.role
          : role // ignore: cast_nullable_to_non_nullable
              as MemberRole,
      joinedAt: null == joinedAt
          ? _self.joinedAt
          : joinedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
mixin _$Invitation {
  String get id;
  String get tripId;
  String? get invitedBy;
  String get email;
  String get status;
  DateTime get expiredAt;
  DateTime get createdAt;

  /// Create a copy of Invitation
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $InvitationCopyWith<Invitation> get copyWith =>
      _$InvitationCopyWithImpl<Invitation>(this as Invitation, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is Invitation &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.tripId, tripId) || other.tripId == tripId) &&
            (identical(other.invitedBy, invitedBy) ||
                other.invitedBy == invitedBy) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.expiredAt, expiredAt) ||
                other.expiredAt == expiredAt) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, id, tripId, invitedBy, email, status, expiredAt, createdAt);

  @override
  String toString() {
    return 'Invitation(id: $id, tripId: $tripId, invitedBy: $invitedBy, email: $email, status: $status, expiredAt: $expiredAt, createdAt: $createdAt)';
  }
}

/// @nodoc
abstract mixin class $InvitationCopyWith<$Res> {
  factory $InvitationCopyWith(
          Invitation value, $Res Function(Invitation) _then) =
      _$InvitationCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      String tripId,
      String? invitedBy,
      String email,
      String status,
      DateTime expiredAt,
      DateTime createdAt});
}

/// @nodoc
class _$InvitationCopyWithImpl<$Res> implements $InvitationCopyWith<$Res> {
  _$InvitationCopyWithImpl(this._self, this._then);

  final Invitation _self;
  final $Res Function(Invitation) _then;

  /// Create a copy of Invitation
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? tripId = null,
    Object? invitedBy = freezed,
    Object? email = null,
    Object? status = null,
    Object? expiredAt = null,
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
      invitedBy: freezed == invitedBy
          ? _self.invitedBy
          : invitedBy // ignore: cast_nullable_to_non_nullable
              as String?,
      email: null == email
          ? _self.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      expiredAt: null == expiredAt
          ? _self.expiredAt
          : expiredAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      createdAt: null == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// Adds pattern-matching-related methods to [Invitation].
extension InvitationPatterns on Invitation {
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
    TResult Function(_Invitation value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Invitation() when $default != null:
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
    TResult Function(_Invitation value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Invitation():
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
    TResult? Function(_Invitation value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Invitation() when $default != null:
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
    TResult Function(String id, String tripId, String? invitedBy, String email,
            String status, DateTime expiredAt, DateTime createdAt)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Invitation() when $default != null:
        return $default(_that.id, _that.tripId, _that.invitedBy, _that.email,
            _that.status, _that.expiredAt, _that.createdAt);
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
    TResult Function(String id, String tripId, String? invitedBy, String email,
            String status, DateTime expiredAt, DateTime createdAt)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Invitation():
        return $default(_that.id, _that.tripId, _that.invitedBy, _that.email,
            _that.status, _that.expiredAt, _that.createdAt);
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
    TResult? Function(String id, String tripId, String? invitedBy, String email,
            String status, DateTime expiredAt, DateTime createdAt)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Invitation() when $default != null:
        return $default(_that.id, _that.tripId, _that.invitedBy, _that.email,
            _that.status, _that.expiredAt, _that.createdAt);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _Invitation implements Invitation {
  const _Invitation(
      {required this.id,
      required this.tripId,
      this.invitedBy,
      required this.email,
      required this.status,
      required this.expiredAt,
      required this.createdAt});

  @override
  final String id;
  @override
  final String tripId;
  @override
  final String? invitedBy;
  @override
  final String email;
  @override
  final String status;
  @override
  final DateTime expiredAt;
  @override
  final DateTime createdAt;

  /// Create a copy of Invitation
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$InvitationCopyWith<_Invitation> get copyWith =>
      __$InvitationCopyWithImpl<_Invitation>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _Invitation &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.tripId, tripId) || other.tripId == tripId) &&
            (identical(other.invitedBy, invitedBy) ||
                other.invitedBy == invitedBy) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.expiredAt, expiredAt) ||
                other.expiredAt == expiredAt) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, id, tripId, invitedBy, email, status, expiredAt, createdAt);

  @override
  String toString() {
    return 'Invitation(id: $id, tripId: $tripId, invitedBy: $invitedBy, email: $email, status: $status, expiredAt: $expiredAt, createdAt: $createdAt)';
  }
}

/// @nodoc
abstract mixin class _$InvitationCopyWith<$Res>
    implements $InvitationCopyWith<$Res> {
  factory _$InvitationCopyWith(
          _Invitation value, $Res Function(_Invitation) _then) =
      __$InvitationCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      String tripId,
      String? invitedBy,
      String email,
      String status,
      DateTime expiredAt,
      DateTime createdAt});
}

/// @nodoc
class __$InvitationCopyWithImpl<$Res> implements _$InvitationCopyWith<$Res> {
  __$InvitationCopyWithImpl(this._self, this._then);

  final _Invitation _self;
  final $Res Function(_Invitation) _then;

  /// Create a copy of Invitation
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? tripId = null,
    Object? invitedBy = freezed,
    Object? email = null,
    Object? status = null,
    Object? expiredAt = null,
    Object? createdAt = null,
  }) {
    return _then(_Invitation(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      tripId: null == tripId
          ? _self.tripId
          : tripId // ignore: cast_nullable_to_non_nullable
              as String,
      invitedBy: freezed == invitedBy
          ? _self.invitedBy
          : invitedBy // ignore: cast_nullable_to_non_nullable
              as String?,
      email: null == email
          ? _self.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      expiredAt: null == expiredAt
          ? _self.expiredAt
          : expiredAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      createdAt: null == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

// dart format on
