import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_cursor.dart';
import '../../../../shared/widgets/app_back_button.dart';
import '../../../../shared/widgets/bookmark_saved_dialog.dart';
import '../../../../shared/widgets/update_error_dialog.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user.dart';
import '../providers/auth_provider.dart';

const Color _fieldBg = AppColors.background; // 평소: 회색 #F1F2F4
const Color _focusBg = Color(0x80FEC181); // 눌렀을 때(포커스): 주황
const Color _saveBg = Color(0xCC2A6FDB);

// 계정 정보 페이지. 더보기 메뉴 > 계정 정보 진입.
class AccountInfoPage extends ConsumerStatefulWidget {
  const AccountInfoPage({super.key});

  @override
  ConsumerState<AccountInfoPage> createState() => _AccountInfoPageState();
}

class _AccountInfoPageState extends ConsumerState<AccountInfoPage> {
  final TextEditingController _currentPwCtrl = TextEditingController();
  final TextEditingController _newPwCtrl = TextEditingController();
  final TextEditingController _confirmPwCtrl = TextEditingController();
  bool _saving = false; // 저장 중 중복 탭 방지

  @override
  void dispose() {
    _currentPwCtrl.dispose();
    _newPwCtrl.dispose();
    _confirmPwCtrl.dispose();
    super.dispose();
  }

  bool get _pwMismatch =>
      _confirmPwCtrl.text.isNotEmpty && _newPwCtrl.text != _confirmPwCtrl.text;

  // 비밀번호 변경. 백엔드가 현재 비밀번호 재인증 → 불일치면 서버 메시지 표시.
  Future<void> _save() async {
    if (_saving) return;
    final String current = _currentPwCtrl.text;
    final String next = _newPwCtrl.text;

    // 로컬 검증: 빈 값·재입력 불일치는 서버까지 안 가고 즉시 안내
    if (current.isEmpty || next.isEmpty) {
      await showUpdateErrorDialog(context, '비밀번호를 모두 입력해주세요.');
      return;
    }
    if (next != _confirmPwCtrl.text) {
      await showUpdateErrorDialog(context, '새 비밀번호가 일치하지 않습니다.');
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(authRepositoryProvider).changePassword(current, next);
      if (!mounted) return;
      _currentPwCtrl.clear();
      _newPwCtrl.clear();
      _confirmPwCtrl.clear();
      await showGeneralDialog<void>(
        context: context,
        barrierDismissible: true,
        barrierLabel: '닫기',
        barrierColor: Colors.black26,
        pageBuilder: (_, __, ___) => const Center(child: BookmarkSavedDialog()),
      );
    } on AppException catch (e) {
      // 현재 비번 불일치·정책 위반 등 → 서버 메시지 그대로 안내
      if (mounted) await showUpdateErrorDialog(context, e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmWithdraw() async {
    final bool? ok = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '닫기',
      barrierColor: Colors.black26,
      pageBuilder: (_, __, ___) => const Center(child: _WithdrawDialog()),
    );
    if (ok != true) return;

    final bool deleted =
        await ref.read(authNotifierProvider.notifier).withdraw();
    // 성공 → 상태 null → 라우터 redirect가 /login으로 이동시킨다.
    // 실패 → 세션 유지된 채 실패 안내.
    if (!deleted && mounted) {
      await showUpdateErrorDialog(context, '탈퇴에 실패했습니다.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? user = ref.watch(authNotifierProvider).valueOrNull;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _Header(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(15, 12, 15, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoField(label: '닉네임', value: user?.nickname ?? ''),
                    const SizedBox(height: 20),
                    _InfoField(label: '이메일', value: user?.email ?? ''),
                    const SizedBox(height: 20),
                    _PasswordField(
                      label: '기존 비밀번호',
                      controller: _currentPwCtrl,
                    ),
                    const SizedBox(height: 20),
                    _PasswordField(
                      label: '새 비밀번호',
                      controller: _newPwCtrl,
                      helper: '8자 이상, 영문 대문자ㆍ소문자ㆍ숫자 포함',
                      onChanged: () => setState(() {}),
                    ),
                    const SizedBox(height: 20),
                    _PasswordField(
                      label: '새 비밀번호 재입력',
                      controller: _confirmPwCtrl,
                      error: _pwMismatch ? '비밀번호가 일치하지 않습니다.' : null,
                      onChanged: () => setState(() {}),
                    ),
                    const SizedBox(height: 16),
                    _WithdrawLink(onTap: _confirmWithdraw),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 0, 15, 15),
              child: _SaveButton(onPressed: _save),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 헤더 ──────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
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
              '계정 정보',
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

// ── 읽기 전용 필드(닉네임·이메일) ─────────────────────────────────────────────
class _InfoField extends StatelessWidget {
  const _InfoField({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label),
        const SizedBox(height: 4),
        Container(
          height: 50,
          width: double.infinity,
          decoration: BoxDecoration(
            color: _fieldBg,
            borderRadius: BorderRadius.circular(17),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.gray,
            ),
          ),
        ),
      ],
    );
  }
}

// ── 비밀번호 입력 필드 ─────────────────────────────────────────────────────
// 평소 회색, 눌렀을 때(포커스) 주황으로 바뀐다. 스트록 없음.
class _PasswordField extends StatefulWidget {
  const _PasswordField({
    required this.label,
    required this.controller,
    this.helper,
    this.error,
    this.onChanged,
  });
  final String label;
  final TextEditingController controller;
  final String? helper;
  final String? error;
  final VoidCallback? onChanged;

  @override
  State<_PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
  final FocusNode _focusNode = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (_focused != _focusNode.hasFocus) {
      setState(() => _focused = _focusNode.hasFocus);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool hasError = widget.error != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(widget.label),
        const SizedBox(height: 4),
        Container(
          height: 50,
          decoration: BoxDecoration(
            color: _focused ? _focusBg : _fieldBg,
            borderRadius: BorderRadius.circular(17),
          ),
          padding: const EdgeInsets.only(left: 16, right: 12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  obscureText: true,
                  cursorColor: appCursorColor(),
                  onChanged: widget.onChanged == null
                      ? null
                      : (_) => widget.onChanged!(),
                  style: const TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                    color: AppColors.dark,
                  ),
                  decoration: const InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.edit_outlined, size: 20, color: AppColors.gray),
            ],
          ),
        ),
        if (widget.helper != null)
          _FieldHint(widget.helper!, color: AppColors.folderOrange),
        if (hasError) _FieldHint(widget.error!, color: AppColors.error),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);
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

class _FieldHint extends StatelessWidget {
  const _FieldHint(this.text, {required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 6),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }
}

// ── 회원탈퇴 링크 ──────────────────────────────────────────────────────────
class _WithdrawLink extends StatelessWidget {
  const _WithdrawLink({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '회원탈퇴',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.gray,
              ),
            ),
            SizedBox(width: 3),
            Icon(Icons.logout, size: 20, color: AppColors.gray),
          ],
        ),
      ),
    );
  }
}

// ── 저장 버튼 ──────────────────────────────────────────────────────────────
class _SaveButton extends StatelessWidget {
  const _SaveButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _saveBg,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),
        ),
        child: const Text(
          '저장',
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

// ── 회원 탈퇴 확인 다이얼로그 ────────────────────────────────────────────────
class _WithdrawDialog extends StatelessWidget {
  const _WithdrawDialog();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 300,
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(17),
        ),
        child: Column(
          children: [
            const Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.priority_high, size: 30, color: AppColors.error),
                  SizedBox(height: 20),
                  Text(
                    '탈퇴하시겠습니까?',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF070707),
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    '되돌릴 수 없는 작업입니다.',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.error,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _DialogButton(
                    label: '취소',
                    bg: const Color(0xFFD5D5D5),
                    textColor: const Color(0xFF070707),
                    onTap: () => Navigator.pop(context, false),
                  ),
                  const SizedBox(width: 20),
                  _DialogButton(
                    label: '삭제',
                    bg: const Color(0xCCEC2113),
                    textColor: Colors.white,
                    onTap: () => Navigator.pop(context, true),
                  ),
                ],
              ),
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
        width: 120,
        height: 40,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ),
    );
  }
}
