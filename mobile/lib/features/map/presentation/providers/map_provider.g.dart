// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'map_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$currentLocationHash() => r'c53e532f230a0e91e548d5530d7fc7858ec95095';

/// See also [currentLocation].
@ProviderFor(currentLocation)
final currentLocationProvider =
    AutoDisposeFutureProvider<({double lat, double lng})>.internal(
  currentLocation,
  name: r'currentLocationProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentLocationHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CurrentLocationRef
    = AutoDisposeFutureProviderRef<({double lat, double lng})>;
String _$mapControllerHash() => r'8f4fe7622688c2c07646f36616ce77ac2da7c568';

/// See also [MapController].
@ProviderFor(MapController)
final mapControllerProvider =
    AutoDisposeNotifierProvider<MapController, NaverMapController?>.internal(
  MapController.new,
  name: r'mapControllerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$mapControllerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$MapController = AutoDisposeNotifier<NaverMapController?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
