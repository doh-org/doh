// 다른 앱(네이버 지도)에서 "공유"로 넘어온 text/plain을 검색용 장소명으로 바꾼다.
//
// 네이버 지도 공유 텍스트는 보통 이런 형태다:
//   [네이버 지도]
//   스타벅스 강남점
//   https://naver.me/xxxxx
//
// 우리는 naver.me 링크를 직접 해석하지 않고(페이지 구조 의존·취약),
// "장소명"만 뽑아 기존 /places/search 프록시로 좌표를 얻는다.

// 줄 안에 섞인 URL 토큰(http/https, naver.me 단축 포함) — 제거 대상.
final RegExp _urlToken = RegExp(r'https?://\S+');

// 줄 맨 앞의 대괄호 헤더 접두사([네이버 지도], [카카오맵] 등) — 앱 이름표라 버린다.
// 앞부분만 떼므로 "[네이버 지도]"(줄 전체)든 "[카카오맵] 스타벅스"(인라인)든 다 처리된다.
final RegExp _leadingBracketHeader = RegExp(r'^\[[^\]]*\]\s*');

/// 공유 텍스트에서 검색용 장소명을 뽑는다. 못 뽑으면 null.
///
/// 규칙: 줄 단위로 훑어 헤더·URL을 걷어내고, 남는 "첫 비어있지 않은 줄"을 장소명으로.
/// (네이버 형식은 장소명이 링크보다 먼저 오므로 첫 줄 우선이 안전)
String? parseSharedPlaceName(String raw) {
  for (final String line in raw.split(RegExp(r'[\r\n]+'))) {
    final String cleaned = _cleanLine(line);
    if (cleaned.isNotEmpty) return cleaned;
  }
  return null;
}

// 한 줄에서 헤더/URL 잡음을 제거한 실제 텍스트를 돌려준다(없으면 빈 문자열).
String _cleanLine(String line) {
  final String s = line.trim();
  // 앞의 "[앱명]" 접두사 제거 → 줄 전체가 헤더면 빈 문자열이 되어 다음 줄로 넘어간다
  final String noHeader = s.replaceFirst(_leadingBracketHeader, '');
  return noHeader.replaceAll(_urlToken, '').trim(); // 줄에 섞인 URL만 제거
}
