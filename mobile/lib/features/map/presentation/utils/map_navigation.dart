import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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

/// 구간(출발→도착)을 네이버지도 앱으로 안내한다.
/// 앱 미설치 등으로 못 열면 웹/설치 모달을 띄운다.
Future<void> launchNavigation({
  required BuildContext context,
  required TransportMode mode,
  required NavPoint destination,
  NavPoint? departure,
}) async {
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
}

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

/// 앱 미설치 안내 모달. 네이버 지도 웹 또는 앱 설치(스토어)로 연결.
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
                        '네이버 지도 웹',
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
