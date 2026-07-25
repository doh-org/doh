import 'package:flutter/material.dart';

import '../utils/location_terms_text.dart';

// 기존 지도 다이얼로그(map_navigation.dart)와 톤을 맞춘 상수
const Color _accentBlue = Color(0xCC2A6FDB); // [동의] — 진행 색(길찾기 버튼과 동일)
const Color _iconOrange = Color(0xFFFE8505); // 다이얼로그 공통 아이콘 색
const Color _grayBg = Color(0xFFF1F2F4); // [동의 안 함] 배경

/// 위치정보 사용 동의 모달을 띄운다.
/// 반환 true = 동의, false/null = 미동의(바깥 탭 포함).
Future<bool?> showLocationConsentDialog(BuildContext context) {
  return showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: '닫기',
    barrierColor: Colors.black26,
    pageBuilder: (_, __, ___) => const Align(
      alignment: Alignment.center,
      child: LocationConsentDialog(),
    ),
  );
}

/// 위치 사용 목적·외부앱 전달 고지·약관 링크를 담은 동의 카드
/// 버튼 결과를 Navigator.pop(bool)으로 호출부(게이트)에 리턴
class LocationConsentDialog extends StatelessWidget {
  const LocationConsentDialog({super.key});

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
            const Icon(Icons.my_location, size: 36, color: _iconOrange),
            const SizedBox(height: 12),
            const Text(
              '위치정보 사용에 동의하시겠어요?',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF070707),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const _BodyText(),
            const SizedBox(height: 12),
            // 약관 보기 — 탭 시 전문 스크롤 모달
            GestureDetector(
              onTap: () => showLocationTermsDialog(context),
              child: const Text(
                '위치기반서비스 이용약관 보기',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _accentBlue,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _DialogButton(
                    label: '동의 안 함',
                    bg: _grayBg,
                    textColor: const Color(0xFF070707),
                    onTap: () => Navigator.pop(context, false),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DialogButton(
                    label: '동의',
                    bg: _accentBlue,
                    textColor: Colors.white,
                    onTap: () => Navigator.pop(context, true),
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

// 목적·외부앱 전달·비저장·선택성 고지 문구
class _BodyText extends StatelessWidget {
  const _BodyText();

  @override
  Widget build(BuildContext context) {
    return const Text(
      '현위치 표시와 길찾기에 정확한 위치를 사용해요.\n'
      '네이버지도·카카오맵으로 길찾기 시 현위치가 해당 앱으로 전달돼요.\n'
      '위치는 저장하지 않고 그 순간에만 사용하며, 동의는 선택이에요.',
      style: TextStyle(
        fontFamily: 'Pretendard',
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: Color(0xFF7E7E7E),
        height: 1.5,
      ),
      textAlign: TextAlign.center,
    );
  }
}

/// 위치기반서비스 이용약관 전문을 스크롤 카드로 보여준다.
Future<void> showLocationTermsDialog(BuildContext context) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: '닫기',
    barrierColor: Colors.black26,
    pageBuilder: (_, __, ___) => const Align(
      alignment: Alignment.center,
      child: _LocationTermsCard(),
    ),
  );
}

class _LocationTermsCard extends StatelessWidget {
  const _LocationTermsCard();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 320,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(17),
        ),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Flexible(
              child: Scrollbar(
                child: SingleChildScrollView(
                  child: Text(
                    locationServiceTermsText,
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF1F2125),
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _DialogButton(
              label: '닫기',
              bg: _grayBg,
              textColor: const Color(0xFF070707),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}

// 다이얼로그 하단 버튼 (map_navigation.dart의 버튼 톤 재사용)
class _DialogButton extends StatelessWidget {
  const _DialogButton({
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
