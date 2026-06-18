import 'package:flutter/material.dart';

/// 저장·변경(update) 실패 안내 모달. Figma 138:496.
/// 성공 모달(BookmarkSavedDialog)과 대칭 — 빨간 X 아이콘 + 굵은 메시지.
/// 1.5초 후 자동 닫힘, 바깥 탭으로도 닫힘.
Future<void> showUpdateErrorDialog(BuildContext context, String message) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: '닫기',
    barrierColor: Colors.black26,
    pageBuilder: (_, __, ___) => Align(
      alignment: Alignment.center,
      child: UpdateErrorDialog(message: message),
    ),
  );
}

class UpdateErrorDialog extends StatefulWidget {
  const UpdateErrorDialog({required this.message, super.key});

  final String message;

  @override
  State<UpdateErrorDialog> createState() => _UpdateErrorDialogState();
}

class _UpdateErrorDialogState extends State<UpdateErrorDialog> {
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
                color: const Color(0xFFEC2113),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.close, size: 20, color: Colors.white),
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
