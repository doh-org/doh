// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'member_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$membersHash() => r'7bd6b69dbfd76593afea177be2bcb29e35070eed';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [members].
@ProviderFor(members)
const membersProvider = MembersFamily();

/// See also [members].
class MembersFamily extends Family<AsyncValue<List<TripMember>>> {
  /// See also [members].
  const MembersFamily();

  /// See also [members].
  MembersProvider call(
    String tripId,
  ) {
    return MembersProvider(
      tripId,
    );
  }

  @override
  MembersProvider getProviderOverride(
    covariant MembersProvider provider,
  ) {
    return call(
      provider.tripId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'membersProvider';
}

/// See also [members].
class MembersProvider extends AutoDisposeFutureProvider<List<TripMember>> {
  /// See also [members].
  MembersProvider(
    String tripId,
  ) : this._internal(
          (ref) => members(
            ref as MembersRef,
            tripId,
          ),
          from: membersProvider,
          name: r'membersProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$membersHash,
          dependencies: MembersFamily._dependencies,
          allTransitiveDependencies: MembersFamily._allTransitiveDependencies,
          tripId: tripId,
        );

  MembersProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.tripId,
  }) : super.internal();

  final String tripId;

  @override
  Override overrideWith(
    FutureOr<List<TripMember>> Function(MembersRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: MembersProvider._internal(
        (ref) => create(ref as MembersRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        tripId: tripId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<TripMember>> createElement() {
    return _MembersProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is MembersProvider && other.tripId == tripId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, tripId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin MembersRef on AutoDisposeFutureProviderRef<List<TripMember>> {
  /// The parameter `tripId` of this provider.
  String get tripId;
}

class _MembersProviderElement
    extends AutoDisposeFutureProviderElement<List<TripMember>> with MembersRef {
  _MembersProviderElement(super.provider);

  @override
  String get tripId => (origin as MembersProvider).tripId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
