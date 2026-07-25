// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'location_consent_store.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$locationConsentStoreHash() =>
    r'9ec2f5e8ea709349b1cbb1811c774a4d57782e17';

/// See also [locationConsentStore].
@ProviderFor(locationConsentStore)
final locationConsentStoreProvider =
    AutoDisposeProvider<LocationConsentStore>.internal(
  locationConsentStore,
  name: r'locationConsentStoreProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$locationConsentStoreHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef LocationConsentStoreRef = AutoDisposeProviderRef<LocationConsentStore>;
String _$locationConsentPrefHash() =>
    r'e937d5b631a902d99dbb820eabb0cd58d8c703d1';

/// 현재 위치정보 동의 상태. 계정 무관 기기 로컬값이라 keepAlive로 유지.
///
/// Copied from [LocationConsentPref].
@ProviderFor(LocationConsentPref)
final locationConsentPrefProvider =
    AsyncNotifierProvider<LocationConsentPref, LocationConsent>.internal(
  LocationConsentPref.new,
  name: r'locationConsentPrefProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$locationConsentPrefHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$LocationConsentPref = AsyncNotifier<LocationConsent>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
