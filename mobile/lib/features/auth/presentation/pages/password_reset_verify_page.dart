import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/errors/app_exception.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../widgets/auth_text_field.dart';

// 입력칸 선택(포커스) 시 배경 (로그인 화면과 동일한 peach)
const Color _focusFill = Color(0xFFFEDFBF);

/// 비밀번호 찾기 2단계: 메일로 받은 6자리 코드와 새 비밀번호를 받아 재설정한다.
/// 성공하면 안내 모달 후 로그인 화면으로 보낸다(새 비밀번호로 재로그인).
class PasswordResetVerifyPage extends ConsumerStatefulWidget {
  const PasswordResetVerifyPage({required this.email, super.key});

  /// 1단계에서 코드를 발송한 이메일. 재전송에도 쓴다.
  final String email;

  @override
  ConsumerState<PasswordResetVerifyPage> createState() =>
      _PasswordResetVerifyPageState();
}

class _PasswordResetVerifyPageState
    extends ConsumerState<PasswordResetVerifyPage> {
  final TextEditingController _codeCtrl = TextEditingController();
  final TextEditingController _pwCtrl = TextEditingController();
  final TextEditingController _confirmCtrl = TextEditingController();
  String? _errorMessage;
  bool _submitting = false; // 요청 중 중복 탭 방지
  bool _obscurePw = true;

  @override
  void dispose() {
    _codeCtrl.dispose();
    _pwCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  // 회원가입과 같은 비밀번호 정책 (8자 이상, 대·소문자·숫자)
  bool _isValidPassword(String pw) =>
      pw.length >= 8 &&
      pw.contains(RegExp(r'[A-Z]')) &&
      pw.contains(RegExp(r'[a-z]')) &&
      pw.contains(RegExp(r'[0-9]'));

  Future<void> _onSubmit() async {
    if (_submitting) return;
    final String code = _codeCtrl.text.trim();
    final String pw = _pwCtrl.text;
    // 로컬 검증: 형식 오류는 서버까지 안 가고 즉시 안내
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      setState(() => _errorMessage = '6자리 숫자 코드를 입력해주세요.');
      return;
    }
    if (!_isValidPassword(pw)) {
      setState(() => _errorMessage = '비밀번호는 8자 이상, 대·소문자·숫자를 포함해야 합니다.');
      return;
    }
    if (pw != _confirmCtrl.text) {
      setState(() => _errorMessage = '새 비밀번호가 일치하지 않습니다.');
      return;
    }
    setState(() {
      _errorMessage = null;
      _submitting = true;
    });
    try {
      await ref
          .read(authRepositoryProvider)
          .verifyRecovery(widget.email, code, pw);
      if (!mounted) return;
      await showGeneralDialog<void>(
        context: context,
        barrierDismissible: true,
        barrierLabel: '닫기',
        barrierColor: Colors.black26,
        pageBuilder: (_, __, ___) => const Center(child: _ResetDoneDialog()),
      );
      // 재설정 완료 → 새 비밀번호로 재로그인하도록 로그인 화면으로
      if (mounted) context.go('/login');
    } on AppException catch (e) {
      // 코드 불일치·만료, 정책 위반 등 → 서버 메시지 그대로 안내
      if (mounted) setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // 코드 재전송. 성공 여부와 무관하게 서버가 200을 주므로 안내만 띄운다.
  Future<void> _resend() async {
    if (_submitting) return;
    try {
      await ref.read(authRepositoryProvider).requestRecovery(widget.email);
      if (!mounted) return;
      setState(() => _errorMessage = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('인증 코드를 다시 보냈습니다.')),
      );
    } on AppException catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 80),
              const Text(
                '비밀번호 재설정',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 30,
                  fontWeight: FontWeight.w500,
                  color: AppColors.folderOrange,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '${widget.email} (으)로 보낸\n6자리 인증 코드를 입력해주세요.',
                style: const TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.gray,
                ),
              ),
              const SizedBox(height: 28),
              _fieldLabel('인증 코드'),
              AuthTextField(
                controller: _codeCtrl,
                hintText: '123456',
                keyboardType: TextInputType.number,
                fillColor: AppColors.background,
                focusFillColor: _focusFill,
                borderRadius: 17,
              ),
              const SizedBox(height: 15),
              _fieldLabel('새 비밀번호'),
              AuthTextField(
                controller: _pwCtrl,
                hintText: '새 비밀번호를 입력하세요',
                obscureText: _obscurePw,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePw ? Icons.visibility_off : Icons.visibility,
                    color: AppColors.gray,
                  ),
                  onPressed: () => setState(() => _obscurePw = !_obscurePw),
                ),
                fillColor: AppColors.background,
                focusFillColor: _focusFill,
                borderRadius: 17,
              ),
              const SizedBox(height: 6),
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Text(
                  '8자 이상, 영문 대문자ㆍ소문자ㆍ숫자 포함',
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.folderOrange,
                  ),
                ),
              ),
              const SizedBox(height: 15),
              _fieldLabel('새 비밀번호 재입력'),
              AuthTextField(
                controller: _confirmCtrl,
                hintText: '새 비밀번호를 다시 입력하세요',
                obscureText: true,
                fillColor: AppColors.background,
                focusFillColor: _focusFill,
                borderRadius: 17,
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.error,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _onSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        AppColors.folderOrange.withValues(alpha: 0.8),
                    foregroundColor: AppColors.white,
                    disabledBackgroundColor:
                        AppColors.folderOrange.withValues(alpha: 0.4),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(17),
                    ),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: AppColors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          '비밀번호 재설정',
                          style: TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    '메일이 오지 않았나요? ',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.gray,
                    ),
                  ),
                  GestureDetector(
                    onTap: _resend,
                    child: const Text(
                      '코드 재전송',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppColors.folderOrange,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 4),
      child: Text(
        text,
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

// 재설정 완료 안내 모달. BookmarkSavedDialog와 대칭(문구만 다름), 1.5초 후 자동 닫힘.
class _ResetDoneDialog extends StatefulWidget {
  const _ResetDoneDialog();

  @override
  State<_ResetDoneDialog> createState() => _ResetDoneDialogState();
}

class _ResetDoneDialogState extends State<_ResetDoneDialog> {
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
                color: AppColors.folderOrange,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.check, size: 20, color: Colors.white),
            ),
            const SizedBox(height: 10),
            const Text(
              '비밀번호를 변경했습니다.',
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
