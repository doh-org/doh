// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'map_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$currentLocationHash() => r'f2141b7aabafe6c62484194f19c37fdcfe63bd16';

/// See also [currentLocation].
@ProviderFor(currentLocation)
final currentLocationProvider = AutoDisposeFutureProvider<LatLng>.internal(
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
typedef CurrentLocationRef = AutoDisposeFutureProviderRef<LatLng>;
String _$mapControllerHash() => r'90a9a08051508d91484d022948a61f1fdf1c104f';

/// See also [MapController].
@ProviderFor(MapController)
final mapControllerProvider =
    AutoDisposeNotifierProvider<MapController, GoogleMapController?>.internal(
  MapController.new,
  name: r'mapControllerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$mapControllerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$MapController = AutoDisposeNotifier<GoogleMapController?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
