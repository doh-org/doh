import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/storage/map_app_store.dart';
import '../../../routes/domain/entities/route_stop.dart';

/// 길안내 한 지점(출발/도착). 좌표·표시명.
class NavPoint {
  const NavPoint({required this.name, required this.lat, required this.lng});
  final String name;
  final double lat;
  final double lng;
}

const String _appPackage = 'com.doh.memotrip';
const String _naverStore =
    'https://play.google.com/store/apps/details?id=com.nhn.android.nmap';
const String _kakaoStore =
    'https://play.google.com/store/apps/details?id=net.daum.android.map';

/// 구간(출발→도착)을 지도 앱으로 안내한다.
/// preferredApp이 없으면 선택 모달 → 앱 미설치 등으로 못 열면 웹/설치 모달.
Future<void> launchNavigation({
  required BuildContext context,
  required TransportMode mode,
  required NavPoint destination,
  required MapApp? preferredApp,
  NavPoint? departure,
}) async {
  final MapApp? app = preferredApp ?? await showMapAppPicker(context);
  if (app == null || !context.mounted) return; // 모달 그냥 닫음 = 실행 취소
  switch (app) {
    case MapApp.naver:
      // 이동수단 → (nmap 앱 스킴 타입, 네이버지도 웹 타입) 매핑
      final (String appType, String webType) = switch (mode) {
        TransportMode.car => ('car', 'car'),
        TransportMode.publictransit => ('public', 'transit'),
        TransportMode.bicycle => ('bicycle', 'bicycle'),
        _ => ('walk', 'walk'), // foot
      };
      await _launchOrFallback(
        context,
        appUri: _naverAppUri(departure, destination, appType),
        webUri: _naverWebUri(departure, destination, webType),
        storeUri: _naverStore,
        appLabel: '네이버 지도',
      );
    case MapApp.kakao:
      await _launchOrFallback(
        context,
        appUri: kakaoRouteAppUri(departure, destination, mode),
        webUri: kakaoRouteWebUri(departure, destination),
        storeUri: _kakaoStore,
        appLabel: '카카오맵',
      );
  }
}

/// 장소(주소) 검색어를 지도 앱 검색 화면으로 연다.
/// preferredApp이 없으면 선택 모달 → 앱 미설치 등으로 못 열면 웹/설치 모달.
Future<void> launchPlaceSearch({
  required BuildContext context,
  required String query,
  required MapApp? preferredApp,
}) async {
  final MapApp? app = preferredApp ?? await showMapAppPicker(context);
  if (app == null || !context.mounted) return; // 모달 그냥 닫음 = 실행 취소
  switch (app) {
    case MapApp.naver:
      await _launchOrFallback(
        context,
        appUri: naverSearchAppUri(query),
        webUri: naverSearchWebUri(query),
        storeUri: _naverStore,
        appLabel: '네이버 지도',
      );
    case MapApp.kakao:
      await _launchOrFallback(
        context,
        appUri: kakaoSearchAppUri(query),
        webUri: kakaoSearchWebUri(query),
        storeUri: _kakaoStore,
        appLabel: '카카오맵',
      );
  }
}

/// 지도 앱 검색어 결정.
/// 기본은 장소명 우선(실제 장소 상세가 뜨도록), 비면 주소 폴백.
/// preferAddress(롱프레스 마커)는 이름이 '새 장소' 같은 임의값일 수 있어
/// 주소 우선, 비면 이름 폴백. 둘 다 없으면 빈 문자열(호출부에서 스킵).
String resolveMapSearchQuery({
  required bool preferAddress,
  required String name,
  String? address,
}) {
  final String n = name.trim();
  final String a = (address ?? '').trim();
  if (preferAddress) return a.isNotEmpty ? a : n;
  return n.isNotEmpty ? n : a;
}

// ── 네이버지도 URI ──────────────────────────────────────────────────────────

// nmap 검색 스킴: nmap://search?query={검색어}&appname={호출 앱}
String naverSearchAppUri(String query) =>
    'nmap://search?query=${Uri.encodeQueryComponent(query)}'
    '&appname=$_appPackage';

// 웹 폴백: 네이버지도 v5 검색 URL
String naverSearchWebUri(String query) =>
    'https://map.naver.com/v5/search/${Uri.encodeComponent(query)}';

String _naverAppUri(NavPoint? dep, NavPoint dest, String type) {
  final StringBuffer sb = StringBuffer(
    'nmap://route/$type?dlat=${dest.lat}&dlng=${dest.lng}'
    '&dname=${Uri.encodeQueryComponent(dest.name)}&appname=$_appPackage',
  );
  if (dep != null) {
    sb.write(
      '&slat=${dep.lat}&slng=${dep.lng}'
      '&sname=${Uri.encodeQueryComponent(dep.name)}',
    );
  }
  return sb.toString();
}

String _naverWebUri(NavPoint? dep, NavPoint dest, String type) {
  final String encDest = Uri.encodeComponent(dest.name);
  // Naver Maps v5 directions: lng,lat,name,PLACE_TYPE,-1 (5 fields required)
  final String destSegment = '${dest.lng},${dest.lat},$encDest,PLACE,-1';
  if (dep == null) {
    return 'https://map.naver.com/v5/directions/-/$destSegment/-/$type'
        '?c=${dest.lng},${dest.lat},15,0,0,0,dh';
  }
  final String encDep = Uri.encodeComponent(dep.name);
  final String depSegment = '${dep.lng},${dep.lat},$encDep,PLACE,-1';
  return 'https://map.naver.com/v5/directions/$depSegment/$destSegment/-/$type'
      '?c=${dest.lng},${dest.lat},15,0,0,0,dh';
}

// ── 카카오맵 URI ────────────────────────────────────────────────────────────

// 이동수단 → kakaomap 스킴 by 값. 카카오맵 스킴은 자전거 미지원 → 도보 폴백
String kakaoRouteBy(TransportMode mode) => switch (mode) {
      TransportMode.car => 'CAR',
      TransportMode.publictransit => 'PUBLICTRANSIT',
      _ => 'FOOT', // bicycle, foot
    };

// kakaomap://route?ep={위도},{경도}&by={수단} (+ &sp= 출발지)
String kakaoRouteAppUri(NavPoint? dep, NavPoint dest, TransportMode mode) {
  final StringBuffer sb = StringBuffer(
    'kakaomap://route?ep=${dest.lat},${dest.lng}&by=${kakaoRouteBy(mode)}',
  );
  if (dep != null) sb.write('&sp=${dep.lat},${dep.lng}');
  return sb.toString();
}

// 웹 폴백: map.kakao.com/link/from/{이름,위도,경도}/to/{이름,위도,경도}
String kakaoRouteWebUri(NavPoint? dep, NavPoint dest) {
  final String to =
      '${Uri.encodeComponent(dest.name)},${dest.lat},${dest.lng}';
  if (dep == null) return 'https://map.kakao.com/link/to/$to';
  final String from =
      '${Uri.encodeComponent(dep.name)},${dep.lat},${dep.lng}';
  return 'https://map.kakao.com/link/from/$from/to/$to';
}

// kakaomap 검색 스킴: kakaomap://search?q={검색어}
String kakaoSearchAppUri(String query) =>
    'kakaomap://search?q=${Uri.encodeQueryComponent(query)}';

// 웹 폴백: 카카오맵 검색 링크
String kakaoSearchWebUri(String query) =>
    'https://map.kakao.com/link/search/${Uri.encodeComponent(query)}';

// ── 실행 공통 ──────────────────────────────────────────────────────────────

Future<void> _launchOrFallback(
  BuildContext context, {
  required String appUri,
  required String webUri,
  required String storeUri,
  required String appLabel,
}) async {
  try {
    final bool launched =
        await launchUrl(Uri.parse(appUri), mode: LaunchMode.externalApplication);
    if (launched) return;
  } catch (_) {}
  // 앱 실행 실패 = 미설치로 보고 설치/웹 선택 모달
  if (!context.mounted) return;
  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: '닫기',
    barrierColor: Colors.black26,
    pageBuilder: (_, __, ___) => Align(
      alignment: Alignment.center,
      child: AppNotInstalledDialog(
        appLabel: appLabel,
        webUri: webUri,
        storeUri: storeUri,
      ),
    ),
  );
}

/// 지도 앱 선택 모달. 고정 설정이 없을 때 실행 직전에 띄운다.
/// 반환 null = 사용자가 선택 없이 닫음.
Future<MapApp?> showMapAppPicker(BuildContext context) {
  return showGeneralDialog<MapApp>(
    context: context,
    barrierDismissible: true,
    barrierLabel: '닫기',
    barrierColor: Colors.black26,
    pageBuilder: (_, __, ___) => const Align(
      alignment: Alignment.center,
      child: MapAppPickerDialog(),
    ),
  );
}

/// 네이버지도/카카오맵 중 하나를 고르는 모달.
/// 여기서 고른 값은 이번 실행에만 쓰고 저장하지 않는다(고정은 설정에서).
class MapAppPickerDialog extends StatelessWidget {
  const MapAppPickerDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 300,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(17),
        ),
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.map_outlined, size: 36, color: Color(0xFFFE8505)),
            const SizedBox(height: 12),
            const Text(
              '어떤 지도 앱으로 열까요?',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF070707),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            const Text(
              '설정에서 지도 앱을 고정할 수 있어요.',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF7E7E7E),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _PickerButton(
                    label: '네이버지도',
                    bg: const Color(0xFF03C75A), // 네이버 브랜드 그린
                    textColor: Colors.white,
                    onTap: () => Navigator.pop(context, MapApp.naver),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _PickerButton(
                    label: '카카오맵',
                    bg: const Color(0xFFFEE500), // 카카오 브랜드 옐로우
                    textColor: const Color(0xFF191919),
                    onTap: () => Navigator.pop(context, MapApp.kakao),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PickerButton extends StatelessWidget {
  const _PickerButton({
    required this.label,
    required this.bg,
    required this.textColor,
    required this.onTap,
  });
  final String label;
  final Color bg;
  final Color textColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ),
    );
  }
}

/// 앱 미설치 안내 모달. 지도 웹으로 보기 또는 앱 설치(스토어)로 연결.
class AppNotInstalledDialog extends StatelessWidget {
  const AppNotInstalledDialog({
    required this.appLabel,
    required this.webUri,
    required this.storeUri,
    super.key,
  });
  final String appLabel;
  final String webUri;
  final String storeUri;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 300,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(17),
        ),
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.navigation_outlined,
                size: 36, color: Color(0xFFFE8505)),
            const SizedBox(height: 12),
            Text(
              '$appLabel 앱이 설치되어 있지 않습니다.',
              style: const TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF070707),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      Navigator.pop(context);
                      await launchUrl(
                        Uri.parse(webUri),
                        mode: LaunchMode.externalApplication,
                      );
                    },
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F2F4),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        '웹으로 보기',
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF070707),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      Navigator.pop(context);
                      await launchUrl(
                        Uri.parse(storeUri),
                        mode: LaunchMode.externalApplication,
                      );
                    },
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xCCFE8505),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$appLabel 설치',
                        style: const TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
