// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'marker_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$markersHash() => r'fa1799a23784f0214c2fbfde18d3a33503b7060f';

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

/// See also [markers].
@ProviderFor(markers)
const markersProvider = MarkersFamily();

/// See also [markers].
class MarkersFamily extends Family<AsyncValue<Set<Marker>>> {
  /// See also [markers].
  const MarkersFamily();

  /// See also [markers].
  MarkersProvider call(
    String tripId,
  ) {
    return MarkersProvider(
      tripId,
    );
  }

  @override
  MarkersProvider getProviderOverride(
    covariant MarkersProvider provider,
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
  String? get name => r'markersProvider';
}

/// See also [markers].
class MarkersProvider extends AutoDisposeFutureProvider<Set<Marker>> {
  /// See also [markers].
  MarkersProvider(
    String tripId,
  ) : this._internal(
          (ref) => markers(
            ref as MarkersRef,
            tripId,
          ),
          from: markersProvider,
          name: r'markersProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$markersHash,
          dependencies: MarkersFamily._dependencies,
          allTransitiveDependencies: MarkersFamily._allTransitiveDependencies,
          tripId: tripId,
        );

  MarkersProvider._internal(
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
    FutureOr<Set<Marker>> Function(MarkersRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: MarkersProvider._internal(
        (ref) => create(ref as MarkersRef),
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
  AutoDisposeFutureProviderElement<Set<Marker>> createElement() {
    return _MarkersProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is MarkersProvider && other.tripId == tripId;
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
mixin MarkersRef on AutoDisposeFutureProviderRef<Set<Marker>> {
  /// The parameter `tripId` of this provider.
  String get tripId;
}

class _MarkersProviderElement
    extends AutoDisposeFutureProviderElement<Set<Marker>> with MarkersRef {
  _MarkersProviderElement(super.provider);

  @override
  String get tripId => (origin as MarkersProvider).tripId;
}

String _$markerEntitiesHash() => r'b931d59b706ac999c8195ea3596a040f2417ba1e';

/// See also [markerEntities].
@ProviderFor(markerEntities)
const markerEntitiesProvider = MarkerEntitiesFamily();

/// See also [markerEntities].
class MarkerEntitiesFamily extends Family<AsyncValue<List<TripMarker>>> {
  /// See also [markerEntities].
  const MarkerEntitiesFamily();

  /// See also [markerEntities].
  MarkerEntitiesProvider call(
    String tripId,
  ) {
    return MarkerEntitiesProvider(
      tripId,
    );
  }

  @override
  MarkerEntitiesProvider getProviderOverride(
    covariant MarkerEntitiesProvider provider,
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
  String? get name => r'markerEntitiesProvider';
}

/// See also [markerEntities].
class MarkerEntitiesProvider
    extends AutoDisposeFutureProvider<List<TripMarker>> {
  /// See also [markerEntities].
  MarkerEntitiesProvider(
    String tripId,
  ) : this._internal(
          (ref) => markerEntities(
            ref as MarkerEntitiesRef,
            tripId,
          ),
          from: markerEntitiesProvider,
          name: r'markerEntitiesProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$markerEntitiesHash,
          dependencies: MarkerEntitiesFamily._dependencies,
          allTransitiveDependencies:
              MarkerEntitiesFamily._allTransitiveDependencies,
          tripId: tripId,
        );

  MarkerEntitiesProvider._internal(
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
    FutureOr<List<TripMarker>> Function(MarkerEntitiesRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: MarkerEntitiesProvider._internal(
        (ref) => create(ref as MarkerEntitiesRef),
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
  AutoDisposeFutureProviderElement<List<TripMarker>> createElement() {
    return _MarkerEntitiesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is MarkerEntitiesProvider && other.tripId == tripId;
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
mixin MarkerEntitiesRef on AutoDisposeFutureProviderRef<List<TripMarker>> {
  /// The parameter `tripId` of this provider.
  String get tripId;
}

class _MarkerEntitiesProviderElement
    extends AutoDisposeFutureProviderElement<List<TripMarker>>
    with MarkerEntitiesRef {
  _MarkerEntitiesProviderElement(super.provider);

  @override
  String get tripId => (origin as MarkerEntitiesProvider).tripId;
}

String _$categoriesHash() => r'ce06061ee967bd01b690195431c292066baed780';

/// See also [categories].
@ProviderFor(categories)
const categoriesProvider = CategoriesFamily();

/// See also [categories].
class CategoriesFamily extends Family<AsyncValue<List<Category>>> {
  /// See also [categories].
  const CategoriesFamily();

  /// See also [categories].
  CategoriesProvider call(
    String tripId,
  ) {
    return CategoriesProvider(
      tripId,
    );
  }

  @override
  CategoriesProvider getProviderOverride(
    covariant CategoriesProvider provider,
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
  String? get name => r'categoriesProvider';
}

/// See also [categories].
class CategoriesProvider extends AutoDisposeFutureProvider<List<Category>> {
  /// See also [categories].
  CategoriesProvider(
    String tripId,
  ) : this._internal(
          (ref) => categories(
            ref as CategoriesRef,
            tripId,
          ),
          from: categoriesProvider,
          name: r'categoriesProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$categoriesHash,
          dependencies: CategoriesFamily._dependencies,
          allTransitiveDependencies:
              CategoriesFamily._allTransitiveDependencies,
          tripId: tripId,
        );

  CategoriesProvider._internal(
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
    FutureOr<List<Category>> Function(CategoriesRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: CategoriesProvider._internal(
        (ref) => create(ref as CategoriesRef),
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
  AutoDisposeFutureProviderElement<List<Category>> createElement() {
    return _CategoriesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CategoriesProvider && other.tripId == tripId;
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
mixin CategoriesRef on AutoDisposeFutureProviderRef<List<Category>> {
  /// The parameter `tripId` of this provider.
  String get tripId;
}

class _CategoriesProviderElement
    extends AutoDisposeFutureProviderElement<List<Category>>
    with CategoriesRef {
  _CategoriesProviderElement(super.provider);

  @override
  String get tripId => (origin as CategoriesProvider).tripId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
