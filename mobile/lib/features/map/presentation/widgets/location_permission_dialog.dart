import 'package:flutter/material.dart';

const Color _iconOrange = Color(0xFFFE8505);
const Color _accentOrange = Color(0xCCFE8505); // [설정 열기]
const Color _grayBg = Color(0xFFF1F2F4); // [닫기]

/// OS 위치 권한이 거부됐을 때 설정으로 안내하는 모달
/// 반환 true = 설정 열기 선택(호출부가 OS 설정을 연다), false/null = 닫기
/// 앱 자체 동의(우리 약관)와 OS 권한(안드로이드)은 별개 층
Future<bool?> showLocationPermissionDialog(BuildContext context) {
  return showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: '닫기',
    barrierColor: Colors.black26,
    pageBuilder: (_, __, ___) => const Align(
      alignment: Alignment.center,
      child: LocationPermissionDialog(),
    ),
  );
}

class LocationPermissionDialog extends StatelessWidget {
  const LocationPermissionDialog({super.key});

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.location_off_outlined,
                size: 36, color: _iconOrange),
            const SizedBox(height: 12),
            const Text(
              '위치 권한이 꺼져 있어요',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF070707),
              ),
              textAlign: TextAlign.left,
            ),
            const SizedBox(height: 8),
            const Text(
              '현위치를 사용하려면 설정에서\n위치 권한을 허용해주세요.',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF7E7E7E),
                height: 1.5,
              ),
              textAlign: TextAlign.left,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _DialogButton(
                    label: '닫기',
                    bg: _grayBg,
                    textColor: const Color(0xFF070707),
                    onTap: () => Navigator.pop(context, false),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DialogButton(
                    label: '설정 열기',
                    bg: _accentOrange,
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
