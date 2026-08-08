// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'route_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$dayStopsHash() => r'300dd3d1b82c23d920bfce5c27d4b5cc20a5bd82';

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

/// tripId·day의 stop 목록을 sort 기준으로 반환.
/// markerEntities(tripId)를 구독해 마커 목록이 무효화되면 함께 재조회된다.
///
/// Copied from [dayStops].
@ProviderFor(dayStops)
const dayStopsProvider = DayStopsFamily();

/// tripId·day의 stop 목록을 sort 기준으로 반환.
/// markerEntities(tripId)를 구독해 마커 목록이 무효화되면 함께 재조회된다.
///
/// Copied from [dayStops].
class DayStopsFamily extends Family<AsyncValue<List<RouteStop>>> {
  /// tripId·day의 stop 목록을 sort 기준으로 반환.
  /// markerEntities(tripId)를 구독해 마커 목록이 무효화되면 함께 재조회된다.
  ///
  /// Copied from [dayStops].
  const DayStopsFamily();

  /// tripId·day의 stop 목록을 sort 기준으로 반환.
  /// markerEntities(tripId)를 구독해 마커 목록이 무효화되면 함께 재조회된다.
  ///
  /// Copied from [dayStops].
  DayStopsProvider call(
    String tripId,
    int day,
    RouteSort sort,
  ) {
    return DayStopsProvider(
      tripId,
      day,
      sort,
    );
  }

  @override
  DayStopsProvider getProviderOverride(
    covariant DayStopsProvider provider,
  ) {
    return call(
      provider.tripId,
      provider.day,
      provider.sort,
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
  String? get name => r'dayStopsProvider';
}

/// tripId·day의 stop 목록을 sort 기준으로 반환.
/// markerEntities(tripId)를 구독해 마커 목록이 무효화되면 함께 재조회된다.
///
/// Copied from [dayStops].
class DayStopsProvider extends AutoDisposeFutureProvider<List<RouteStop>> {
  /// tripId·day의 stop 목록을 sort 기준으로 반환.
  /// markerEntities(tripId)를 구독해 마커 목록이 무효화되면 함께 재조회된다.
  ///
  /// Copied from [dayStops].
  DayStopsProvider(
    String tripId,
    int day,
    RouteSort sort,
  ) : this._internal(
          (ref) => dayStops(
            ref as DayStopsRef,
            tripId,
            day,
            sort,
          ),
          from: dayStopsProvider,
          name: r'dayStopsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$dayStopsHash,
          dependencies: DayStopsFamily._dependencies,
          allTransitiveDependencies: DayStopsFamily._allTransitiveDependencies,
          tripId: tripId,
          day: day,
          sort: sort,
        );

  DayStopsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.tripId,
    required this.day,
    required this.sort,
  }) : super.internal();

  final String tripId;
  final int day;
  final RouteSort sort;

  @override
  Override overrideWith(
    FutureOr<List<RouteStop>> Function(DayStopsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: DayStopsProvider._internal(
        (ref) => create(ref as DayStopsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        tripId: tripId,
        day: day,
        sort: sort,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<RouteStop>> createElement() {
    return _DayStopsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is DayStopsProvider &&
        other.tripId == tripId &&
        other.day == day &&
        other.sort == sort;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, tripId.hashCode);
    hash = _SystemHash.combine(hash, day.hashCode);
    hash = _SystemHash.combine(hash, sort.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin DayStopsRef on AutoDisposeFutureProviderRef<List<RouteStop>> {
  /// The parameter `tripId` of this provider.
  String get tripId;

  /// The parameter `day` of this provider.
  int get day;

  /// The parameter `sort` of this provider.
  RouteSort get sort;
}

class _DayStopsProviderElement
    extends AutoDisposeFutureProviderElement<List<RouteStop>> with DayStopsRef {
  _DayStopsProviderElement(super.provider);

  @override
  String get tripId => (origin as DayStopsProvider).tripId;
  @override
  int get day => (origin as DayStopsProvider).day;
  @override
  RouteSort get sort => (origin as DayStopsProvider).sort;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
