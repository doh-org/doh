import 'package:doh/core/storage/location_consent_store.dart';
import 'package:doh/features/map/presentation/utils/location_consent_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

// 탭 → ensureLocationConsent → 반환 bool을 onResult로 전달
class _GateHarness extends ConsumerWidget {
  const _GateHarness({required this.onResult});
  final void Function(bool) onResult;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (BuildContext ctx) => ElevatedButton(
            onPressed: () async => onResult(await ensureLocationConsent(ctx, ref)),
            child: const Text('go'),
          ),
        ),
      ),
    );
  }
}

const String _dialogTitle = '위치정보 사용에 동의하시겠어요?';

void main() {
  late LocationConsentStore store;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    store = LocationConsentStore(SharedPreferencesAsync());
  });

  Future<bool?> runGate(WidgetTester tester) async {
    bool? result;
    await tester.pumpWidget(
      ProviderScope(child: _GateHarness(onResult: (bool r) => result = r)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    return result;
  }

  testWidgets('granted → 모달 없이 true', (WidgetTester tester) async {
    await store.set(LocationConsent.granted);
    final bool? result = await runGate(tester);

    expect(find.text(_dialogTitle), findsNothing);
    expect(result, isTrue);
  });

  testWidgets('unset → 모달 노출, [동의] 시 true·granted 저장',
      (WidgetTester tester) async {
    await runGate(tester); // unset 기본값 → 모달
    expect(find.text(_dialogTitle), findsOneWidget);

    await tester.tap(find.text('동의'));
    await tester.pumpAndSettle();

    expect(await store.get(), LocationConsent.granted);
  });

  testWidgets('unset → [동의 안 함] 시 false·denied 저장',
      (WidgetTester tester) async {
    bool? result;
    await tester.pumpWidget(
      ProviderScope(child: _GateHarness(onResult: (bool r) => result = r)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('동의 안 함'));
    await tester.pumpAndSettle();

    expect(result, isFalse);
    expect(await store.get(), LocationConsent.denied);
  });

  testWidgets('denied → 재탭 시 모달 다시 노출(대안 A)',
      (WidgetTester tester) async {
    await store.set(LocationConsent.denied);
    await runGate(tester);

    // 거부 상태여도 모달을 다시 띄운다
    expect(find.text(_dialogTitle), findsOneWidget);
  });
}
