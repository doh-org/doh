import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/location_consent_store.dart';
import '../widgets/location_consent_dialog.dart';

/// 위치 사용 직전에 통과시키는 단일 관문(앱 자체 동의)
/// 반환 true = 위치 써도 됨, false = 스킵
///
/// 분기:
///   granted → 모달 없이 통과
///   unset/denied → 매번 모달. 거부 후에도 재탭 시 다시 물어 재동의 기회 제공
///
/// 주의: 이 게이트는 우리 약관 동의만 담당
/// 통과(true) 후의 OS 위치권한은 별개 층이라 호출부에서 따로 처리
Future<bool> ensureLocationConsent(BuildContext context, WidgetRef ref) async {
  final LocationConsent current =
      await ref.read(locationConsentPrefProvider.future);
  // 이미 동의 → 모달 없이 통과
  if (current == LocationConsent.granted) return true;
  // 미설정·거부 → 모달로 물음 (await 사이 화면이 사라졌을 수 있어 mounted 확인)
  if (!context.mounted) return false;
  final bool? agreed = await showLocationConsentDialog(context);
  // 바깥 탭(null)은 미동의로 처리
  final LocationConsent next =
      agreed == true ? LocationConsent.granted : LocationConsent.denied;
  await ref.read(locationConsentPrefProvider.notifier).save(next);
  return agreed == true;
}
