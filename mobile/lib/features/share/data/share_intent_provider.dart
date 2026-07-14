import 'dart:async';

import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../utils/share_text_parser.dart';

part 'share_intent_provider.g.dart';

/// 다른 앱에서 "공유"로 넘어온 대기 중 장소명. null = 처리할 공유 없음.
///
/// 앱 루트가 이 값을 구독해, 값이 생기면 여행 선택 화면(/share)으로 보낸다.
/// keepAlive: 공유는 앱 루트에서만 구독하므로, 리스너가 잠깐 없어도
/// 스트림 구독이 끊기지 않도록 살려 둔다.
@Riverpod(keepAlive: true)
class PendingSharedPlace extends _$PendingSharedPlace {
  StreamSubscription<List<SharedMediaFile>>? _sub;

  @override
  String? build() {
    // 웜 상태: 앱 실행 중 공유가 오면 스트림으로 수신
    _sub = ReceiveSharingIntent.instance.getMediaStream().listen(_handle);
    ref.onDispose(() => _sub?.cancel());
    // 콜드 스타트: 공유로 앱이 처음 켜졌다면 최초 1건을 읽는다
    _readInitial();
    return null;
  }

  Future<void> _readInitial() async {
    _handle(await ReceiveSharingIntent.instance.getInitialMedia());
  }

  // 수신 미디어에서 장소명을 뽑아 상태에 싣는다.
  void _handle(List<SharedMediaFile> media) {
    final String? name = _firstPlaceName(media);
    if (name != null) state = name;
    // 처리 여부와 무관하게 reset — 앱 재개(resume) 시 같은 공유가 되살아나는 것 방지
    ReceiveSharingIntent.instance.reset();
  }

  // 처리 완료 후 호출 — 다음 공유를 받을 수 있도록 비운다.
  void consume() => state = null;
}

// text/url 타입 미디어에서 첫 번째로 해석되는 장소명을 돌려준다(없으면 null).
String? _firstPlaceName(List<SharedMediaFile> media) {
  for (final SharedMediaFile m in media) {
    // 네이버 공유는 text/plain → text 또는 url 타입으로 들어온다
    if (m.type != SharedMediaType.text && m.type != SharedMediaType.url) {
      continue;
    }
    final String? name = parseSharedPlaceName(m.path); // path에 실제 텍스트가 담김
    if (name != null) return name;
  }
  return null;
}
