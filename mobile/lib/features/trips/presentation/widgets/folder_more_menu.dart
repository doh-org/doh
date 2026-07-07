import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

const double _menuWidth = 180.0;
const double _itemHeight = 62.5;
const Color _defaultBg = AppColors.background; // 평소: 회색
const Color _pressBg = Color(0xFFFEDFBF); // 눌렀을 때: 주황
const Color _divider = AppColors.white;

// ⋯ 더보기 버튼. 탭 시 자기 위치 아래에 설정 메뉴를 띄운다.
class FolderMoreButton extends StatelessWidget {
  const FolderMoreButton({super.key});

  void _open(BuildContext context) {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final Offset origin = box.localToGlobal(Offset.zero);
    final double screenW = MediaQuery.of(context).size.width;
    final double top = origin.dy + box.size.height + 5;
    final double right = screenW - (origin.dx + box.size.width);

    showGeneralDialog<void>(
      context: context,
      barrierColor: Colors.transparent,
      barrierDismissible: true,
      barrierLabel: '더보기',
      transitionDuration: const Duration(milliseconds: 120),
      pageBuilder: (_, __, ___) => _MoreMenu(top: top, right: right),
      transitionBuilder: (_, anim, __, child) => FadeTransition(
        opacity: anim,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _open(context),
      behavior: HitTestBehavior.opaque,
      child: const Icon(Icons.more_horiz, size: 20, color: AppColors.dark),
    );
  }
}

class _MoreMenu extends ConsumerWidget {
  const _MoreMenu({required this.top, required this.right});

  final double top;
  final double right;

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    Navigator.of(context).pop();
    await ref.read(authNotifierProvider.notifier).logout();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Stack(
      children: [
        Positioned(
          top: top,
          right: right,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: _menuWidth,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(17),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1A000000),
                    offset: Offset(0, 4),
                    blurRadius: 12,
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _MenuItem(
                      label: '약관 정보', onTap: () => Navigator.pop(context)),
                  const _MenuDivider(),
                  _MenuItem(
                    label: '로그아웃',
                    onTap: () => _logout(context, ref),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// 평소 회색, 누르면 주황으로 바뀌는 메뉴 항목.
class _MenuItem extends StatefulWidget {
  const _MenuItem({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  State<_MenuItem> createState() => _MenuItemState();
}

class _MenuItemState extends State<_MenuItem> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onTap,
      child: Container(
        height: _itemHeight,
        width: double.infinity,
        color: _pressed ? _pressBg : _defaultBg,
        alignment: Alignment.center,
        child: Text(
          widget.label,
          style: const TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColors.dark,
          ),
        ),
      ),
    );
  }
}

class _MenuDivider extends StatelessWidget {
  const _MenuDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, thickness: 1, color: _divider);
  }
}
