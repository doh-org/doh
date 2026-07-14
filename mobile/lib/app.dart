import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/share/data/share_intent_provider.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    // 외부 앱 공유가 들어오면(대기 장소명 생김) 여행 선택 화면으로 이동.
    // listen이 provider를 살려 두어 콜드/웜 공유 수신 구독이 유지된다.
    ref.listen(pendingSharedPlaceProvider, (_, String? name) {
      if (name != null) router.go('/share');
    });

    return MaterialApp.router(
      title: 'Doh',
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}
