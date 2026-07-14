// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'share_intent_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$pendingSharedPlaceHash() =>
    r'72a108903a9e48987c68b5a9b814199188068ffa';

/// 다른 앱에서 "공유"로 넘어온 대기 중 장소명. null = 처리할 공유 없음.
///
/// 앱 루트가 이 값을 구독해, 값이 생기면 여행 선택 화면(/share)으로 보낸다.
/// keepAlive: 공유는 앱 루트에서만 구독하므로, 리스너가 잠깐 없어도
/// 스트림 구독이 끊기지 않도록 살려 둔다.
///
/// Copied from [PendingSharedPlace].
@ProviderFor(PendingSharedPlace)
final pendingSharedPlaceProvider =
    NotifierProvider<PendingSharedPlace, String?>.internal(
  PendingSharedPlace.new,
  name: r'pendingSharedPlaceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$pendingSharedPlaceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$PendingSharedPlace = Notifier<String?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
