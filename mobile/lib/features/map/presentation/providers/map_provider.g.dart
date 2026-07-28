// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'map_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$currentLocationHash() => r'd3f889d4f13889c5f0e93b44a5c107be53cf5b53';

/// See also [currentLocation].
@ProviderFor(currentLocation)
final currentLocationProvider = AutoDisposeFutureProvider<NLatLng>.internal(
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
typedef CurrentLocationRef = AutoDisposeFutureProviderRef<NLatLng>;
String _$mapControllerHash() => r'333ebb0b9ccf2253e3d6a86b4353cea151cb4938';

/// See also [MapController].
@ProviderFor(MapController)
final mapControllerProvider =
    NotifierProvider<MapController, NaverMapController?>.internal(
  MapController.new,
  name: r'mapControllerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$mapControllerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$MapController = Notifier<NaverMapController?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
