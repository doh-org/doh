// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'route_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$routesHash() => r'393ce654ef0c3efc0441b92f2951f5a32389a273';

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

/// See also [routes].
@ProviderFor(routes)
const routesProvider = RoutesFamily();

/// See also [routes].
class RoutesFamily extends Family<AsyncValue<List<TripRoute>>> {
  /// See also [routes].
  const RoutesFamily();

  /// See also [routes].
  RoutesProvider call(
    String tripId,
  ) {
    return RoutesProvider(
      tripId,
    );
  }

  @override
  RoutesProvider getProviderOverride(
    covariant RoutesProvider provider,
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
  String? get name => r'routesProvider';
}

/// See also [routes].
class RoutesProvider extends AutoDisposeFutureProvider<List<TripRoute>> {
  /// See also [routes].
  RoutesProvider(
    String tripId,
  ) : this._internal(
          (ref) => routes(
            ref as RoutesRef,
            tripId,
          ),
          from: routesProvider,
          name: r'routesProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$routesHash,
          dependencies: RoutesFamily._dependencies,
          allTransitiveDependencies: RoutesFamily._allTransitiveDependencies,
          tripId: tripId,
        );

  RoutesProvider._internal(
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
    FutureOr<List<TripRoute>> Function(RoutesRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: RoutesProvider._internal(
        (ref) => create(ref as RoutesRef),
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
  AutoDisposeFutureProviderElement<List<TripRoute>> createElement() {
    return _RoutesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is RoutesProvider && other.tripId == tripId;
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
mixin RoutesRef on AutoDisposeFutureProviderRef<List<TripRoute>> {
  /// The parameter `tripId` of this provider.
  String get tripId;
}

class _RoutesProviderElement
    extends AutoDisposeFutureProviderElement<List<TripRoute>> with RoutesRef {
  _RoutesProviderElement(super.provider);

  @override
  String get tripId => (origin as RoutesProvider).tripId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
