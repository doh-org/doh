import 'package:flutter/material.dart';

/// 안내(성공·정보) 모달. 실패 모달(showUpdateErrorDialog)과 대칭 —
/// 주황 체크 아이콘 + 굵은 메시지. 1.5초 후 자동 닫힘, 바깥 탭으로도 닫힘.
/// BookmarkSavedDialog와 같은 서식이되, 메시지를 인자로 받아 재사용한다.
Future<void> showInfoDialog(BuildContext context, String message) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: '닫기',
    barrierColor: Colors.black26,
    pageBuilder: (_, __, ___) => Align(
      alignment: Alignment.center,
      child: InfoDialog(message: message),
    ),
  );
}

class InfoDialog extends StatefulWidget {
  const InfoDialog({required this.message, super.key});

  final String message;

  @override
  State<InfoDialog> createState() => _InfoDialogState();
}

class _InfoDialogState extends State<InfoDialog> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 300,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(17),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: const Color(0xFFFE8505),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.check, size: 20, color: Colors.white),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                widget.message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF070707),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
