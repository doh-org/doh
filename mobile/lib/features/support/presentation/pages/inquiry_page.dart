import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_cursor.dart';
import '../../../../shared/widgets/app_back_button.dart';

const Color _boxBg = AppColors.background; // #F1F2F4
const Color _sendBg = Color(0xCC2A6FDB);

// 문의하기 페이지. 더보기 메뉴 > 문의하기 진입.
// TODO: 전송·사진 첨부는 백엔드/이미지 피커 연동 전 프론트 UI만 구현.
class InquiryPage extends StatefulWidget {
  const InquiryPage({super.key});

  @override
  State<InquiryPage> createState() => _InquiryPageState();
}

class _InquiryPageState extends State<InquiryPage> {
  final TextEditingController _contentCtrl = TextEditingController();
  final List<String> _photos = [];

  @override
  void dispose() {
    _contentCtrl.dispose();
    super.dispose();
  }

  void _addPhoto() {
    // TODO: image_picker 연동(사진 선택 후 _photos에 추가).
  }

  void _send() {
    // TODO: 백엔드 문의 전송 API 연동(내용 + 첨부 사진).
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const _Header(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(15, 12, 15, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _Label('내용'),
                    const SizedBox(height: 4),
                    _ContentBox(controller: _contentCtrl),
                    const SizedBox(height: 24),
                    const _Label('사진 첨부'),
                    const SizedBox(height: 10),
                    for (final String name in _photos) ...[
                      _PhotoChip(label: name),
                      const SizedBox(height: 10),
                    ],
                    _PhotoChip(label: '사진 추가', onTap: _addPhoto),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 0, 15, 15),
              child: _SendButton(onPressed: _send),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 헤더 ──────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: Row(
        children: [
          AppBackButton(
            onTap: () => context.pop(),
            padding: const EdgeInsets.fromLTRB(20, 0, 12, 0),
          ),
          const Expanded(
            child: Text(
              '문의하기',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F1D1A),
              ),
            ),
          ),
          const SizedBox(width: 52),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.dark,
        ),
      ),
    );
  }
}

// ── 내용 입력 박스 ─────────────────────────────────────────────────────────
class _ContentBox extends StatelessWidget {
  const _ContentBox({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: _boxBg,
        borderRadius: BorderRadius.circular(17),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: TextField(
        controller: controller,
        maxLines: null,
        expands: true,
        textAlignVertical: TextAlignVertical.top,
        cursorColor: appCursorColor(),
        style: const TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppColors.dark,
        ),
        decoration: const InputDecoration(
          isCollapsed: true,
          border: InputBorder.none,
          hintText: '내용을 작성해주세요.',
          hintStyle: TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColors.gray,
          ),
        ),
      ),
    );
  }
}

// ── 사진 첨부 칩 ───────────────────────────────────────────────────────────
class _PhotoChip extends StatelessWidget {
  const _PhotoChip({required this.label, this.onTap});
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 140,
        height: 40,
        decoration: BoxDecoration(
          color: _boxBg,
          borderRadius: BorderRadius.circular(17),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: [
            const Icon(Icons.image_outlined, size: 24, color: AppColors.gray),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.gray,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 전송 버튼 ──────────────────────────────────────────────────────────────
class _SendButton extends StatelessWidget {
  const _SendButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _sendBg,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),
        ),
        child: const Text(
          '전송',
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFFFDFDFD),
          ),
        ),
      ),
    );
  }
}
