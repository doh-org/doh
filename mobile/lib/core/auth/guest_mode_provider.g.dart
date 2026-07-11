// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'guest_mode_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$guestModeHash() => r'20fb306202f665890b173550d1df8488800473eb';

/// 게스트(로그인 없이) 모드 여부. true면 라우터가 앱 진입을 허용하고,
/// repository provider들이 로컬 구현으로 스왑된다.
///
/// Copied from [GuestMode].
@ProviderFor(GuestMode)
final guestModeProvider = NotifierProvider<GuestMode, bool>.internal(
  GuestMode.new,
  name: r'guestModeProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$guestModeHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$GuestMode = Notifier<bool>;
String _$guestNicknameHash() => r'2944bda751915ddb2a293e88af16522096597023';

/// 게스트 표시용 닉네임. 계정 정보 페이지에서 수정, 목록 인사말 등에 표시.
///
/// Copied from [GuestNickname].
@ProviderFor(GuestNickname)
final guestNicknameProvider =
    AsyncNotifierProvider<GuestNickname, String>.internal(
  GuestNickname.new,
  name: r'guestNicknameProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$guestNicknameHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$GuestNickname = AsyncNotifier<String>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
