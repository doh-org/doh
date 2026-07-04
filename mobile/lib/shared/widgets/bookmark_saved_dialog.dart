import 'package:flutter/material.dart';

/// 저장 성공 안내 모달. 실패 모달(UpdateErrorDialog)과 대칭 —
/// 주황 체크 아이콘 + 굵은 메시지. 1.5초 후 자동 닫힘.
class BookmarkSavedDialog extends StatefulWidget {
  const BookmarkSavedDialog({super.key});

  @override
  State<BookmarkSavedDialog> createState() => BookmarkSavedDialogState();
}

class BookmarkSavedDialogState extends State<BookmarkSavedDialog> {
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
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _OrangeCheckIcon(),
            SizedBox(height: 10),
            Text(
              '저장했습니다.',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF070707),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrangeCheckIcon extends StatelessWidget {
  const _OrangeCheckIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: const Color(0xFFFE8505),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Icon(Icons.check, size: 20, color: Colors.white),
    );
  }
}
