import 'package:doh/features/map/presentation/providers/map_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('setController 후 다른 시점에 read해도 같은 notifier를 준다', () async {
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);

    final MapController first = container.read(mapControllerProvider.notifier);
    // 프레임 경계 흉내 — autoDispose였다면 이 사이에 폐기된다
    await Future<void>.delayed(const Duration(milliseconds: 50));
    final MapController second = container.read(mapControllerProvider.notifier);

    expect(identical(first, second), isTrue,
        reason: '인스턴스가 바뀌면 보관 중이던 NaverMapController가 유실된다');
  });
}
