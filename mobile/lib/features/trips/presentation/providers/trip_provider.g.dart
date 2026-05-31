// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trip_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$tripsHash() => r'36596348c5afca8d0f69962fcf4e3bf0012a5022';

/// See also [trips].
@ProviderFor(trips)
final tripsProvider = AutoDisposeFutureProvider<List<Trip>>.internal(
  trips,
  name: r'tripsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$tripsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TripsRef = AutoDisposeFutureProviderRef<List<Trip>>;
String _$tripDetailNotifierHash() =>
    r'847373c3d12ba9386342ffa828f2c64411b541f4';

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

abstract class _$TripDetailNotifier
    extends BuildlessAutoDisposeAsyncNotifier<Trip> {
  late final String tripId;

  FutureOr<Trip> build(
    String tripId,
  );
}

/// See also [TripDetailNotifier].
@ProviderFor(TripDetailNotifier)
const tripDetailNotifierProvider = TripDetailNotifierFamily();

/// See also [TripDetailNotifier].
class TripDetailNotifierFamily extends Family<AsyncValue<Trip>> {
  /// See also [TripDetailNotifier].
  const TripDetailNotifierFamily();

  /// See also [TripDetailNotifier].
  TripDetailNotifierProvider call(
    String tripId,
  ) {
    return TripDetailNotifierProvider(
      tripId,
    );
  }

  @override
  TripDetailNotifierProvider getProviderOverride(
    covariant TripDetailNotifierProvider provider,
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
  String? get name => r'tripDetailNotifierProvider';
}

/// See also [TripDetailNotifier].
class TripDetailNotifierProvider
    extends AutoDisposeAsyncNotifierProviderImpl<TripDetailNotifier, Trip> {
  /// See also [TripDetailNotifier].
  TripDetailNotifierProvider(
    String tripId,
  ) : this._internal(
          () => TripDetailNotifier()..tripId = tripId,
          from: tripDetailNotifierProvider,
          name: r'tripDetailNotifierProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$tripDetailNotifierHash,
          dependencies: TripDetailNotifierFamily._dependencies,
          allTransitiveDependencies:
              TripDetailNotifierFamily._allTransitiveDependencies,
          tripId: tripId,
        );

  TripDetailNotifierProvider._internal(
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
  FutureOr<Trip> runNotifierBuild(
    covariant TripDetailNotifier notifier,
  ) {
    return notifier.build(
      tripId,
    );
  }

  @override
  Override overrideWith(TripDetailNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: TripDetailNotifierProvider._internal(
        () => create()..tripId = tripId,
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
  AutoDisposeAsyncNotifierProviderElement<TripDetailNotifier, Trip>
      createElement() {
    return _TripDetailNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TripDetailNotifierProvider && other.tripId == tripId;
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
mixin TripDetailNotifierRef on AutoDisposeAsyncNotifierProviderRef<Trip> {
  /// The parameter `tripId` of this provider.
  String get tripId;
}

class _TripDetailNotifierProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<TripDetailNotifier, Trip>
    with TripDetailNotifierRef {
  _TripDetailNotifierProviderElement(super.provider);

  @override
  String get tripId => (origin as TripDetailNotifierProvider).tripId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
