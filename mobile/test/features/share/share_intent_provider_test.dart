import 'dart:async';

import 'package:doh/features/share/data/share_intent_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

// getInitialMedia/스트림 이벤트가 async로 반영되므로 마이크로태스크를 한 번 흘린다.
Future<void> _tick() => Future<void>.delayed(Duration.zero);

SharedMediaFile _text(String s) =>
    SharedMediaFile(path: s, type: SharedMediaType.text);

void main() {
  test('콜드 스타트 초기 공유 → 장소명 상태', () async {
    ReceiveSharingIntent.setMockValues(
      initialMedia: [_text('[네이버 지도]\n경복궁\nhttps://naver.me/x')],
      mediaStream: const Stream.empty(),
    );
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.listen(pendingSharedPlaceProvider, (_, __) {}); // build 구독 시작

    await _tick();
    expect(container.read(pendingSharedPlaceProvider), '경복궁');
  });

  test('웜 공유 스트림 수신 → 상태 갱신', () async {
    final controller = StreamController<List<SharedMediaFile>>();
    ReceiveSharingIntent.setMockValues(
      initialMedia: [],
      mediaStream: controller.stream,
    );
    final container = ProviderContainer();
    addTearDown(container.dispose);
    addTearDown(controller.close);
    container.listen(pendingSharedPlaceProvider, (_, __) {});

    await _tick();
    expect(container.read(pendingSharedPlaceProvider), isNull);

    controller.add([_text('스타벅스 강남점 https://naver.me/x')]);
    await _tick();
    expect(container.read(pendingSharedPlaceProvider), '스타벅스 강남점');
  });

  test('consume → 대기 공유 비움', () async {
    ReceiveSharingIntent.setMockValues(
      initialMedia: [_text('경복궁')],
      mediaStream: const Stream.empty(),
    );
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.listen(pendingSharedPlaceProvider, (_, __) {});

    await _tick();
    expect(container.read(pendingSharedPlaceProvider), '경복궁');

    container.read(pendingSharedPlaceProvider.notifier).consume();
    expect(container.read(pendingSharedPlaceProvider), isNull);
  });

  test('장소명 없는 링크만 공유 → 상태 null 유지', () async {
    ReceiveSharingIntent.setMockValues(
      initialMedia: [_text('https://naver.me/x')],
      mediaStream: const Stream.empty(),
    );
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.listen(pendingSharedPlaceProvider, (_, __) {});

    await _tick();
    expect(container.read(pendingSharedPlaceProvider), isNull);
  });
}
