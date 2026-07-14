// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'map_app_store.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$mapAppStoreHash() => r'ba5cb4812d5176cd6ee852ee79718954ce555c38';

/// See also [mapAppStore].
@ProviderFor(mapAppStore)
final mapAppStoreProvider = AutoDisposeProvider<MapAppStore>.internal(
  mapAppStore,
  name: r'mapAppStoreProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$mapAppStoreHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef MapAppStoreRef = AutoDisposeProviderRef<MapAppStore>;
String _$preferredMapAppHash() => r'ef1683e917355e11940a4c926f73ae98b6e16b7c';

/// 고정된 지도 앱. null = 미설정.
///
/// Copied from [PreferredMapApp].
@ProviderFor(PreferredMapApp)
final preferredMapAppProvider =
    AsyncNotifierProvider<PreferredMapApp, MapApp?>.internal(
  PreferredMapApp.new,
  name: r'preferredMapAppProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$preferredMapAppHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$PreferredMapApp = AsyncNotifier<MapApp?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
