import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';

/// 폴더가 하나도 없어 지도로 못 들어갈 때 띄우는 안내 모달.
/// 자동 닫힘 없음 — + 버튼을 누르면 여행 생성 페이지로 이동, 바깥 탭으로 닫힘.
Future<void> showCreateFolderDialog(BuildContext context) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: '닫기',
    barrierColor: Colors.black26,
    pageBuilder: (_, __, ___) => const Align(
      alignment: Alignment.center,
      child: CreateFolderDialog(),
    ),
  );
}

class CreateFolderDialog extends StatelessWidget {
  const CreateFolderDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 300,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(17),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '여행 폴더 생성하기',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF070707),
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              // + 탭 → 모달을 먼저 닫고 여행 생성 페이지로 이동
              onTap: () {
                // pop 후엔 이 context가 트리에서 빠지므로 라우터를 미리 잡아둔다
                final GoRouter router = GoRouter.of(context);
                Navigator.of(context).pop();
                router.push('/trips/create');
              },
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.folderOrange,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.add, size: 24, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
