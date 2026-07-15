import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/errors/app_exception.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_back_button.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../utils/password_policy.dart';
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
  bool _submitting = false; // 재설정 요청 중 중복 탭 방지
  bool _verifying = false; // 코드 확인 요청 중 중복 탭 방지
  bool _obscurePw = true;

  // 코드 확인 성공 시 받는 recovery 세션 토큰. 비밀번호 재설정에만 쓴다.
  // null = 아직 미확인. 코드는 1회용이라 확인 후 입력칸을 잠근다.
  String? _recoveryToken;

  bool get _codeVerified => _recoveryToken != null;

  @override
  void dispose() {
    _codeCtrl.dispose();
    _pwCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }


  // 코드 즉시 확인. 성공하면 recovery 세션 토큰을 받아 보관하고 코드칸을 잠근다.
  Future<void> _onVerifyCode() async {
    if (_verifying || _codeVerified) return;
    final String code = _codeCtrl.text.trim();
    // 로컬 검증: 형식 오류는 서버까지 안 가고 즉시 안내 (1회용 코드 소모 방지)
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      setState(() => _errorMessage = '6자리 숫자 코드를 입력해주세요.');
      return;
    }
    setState(() {
      _errorMessage = null;
      _verifying = true;
    });
    try {
      final String token = await ref
          .read(authRepositoryProvider)
          .verifyRecoveryCode(widget.email, code);
      if (mounted) setState(() => _recoveryToken = token);
    } on AppException catch (e) {
      // 코드 불일치·만료 등 → 서버 메시지 그대로 안내
      if (mounted) setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  Future<void> _onSubmit() async {
    if (_submitting) return;
    final String? token = _recoveryToken;
    final String pw = _pwCtrl.text;
    // 로컬 검증: 형식 오류는 서버까지 안 가고 즉시 안내
    if (token == null) {
      setState(() => _errorMessage = '인증코드 확인을 먼저 진행해주세요.');
      return;
    }
    if (!isValidPassword(pw)) {
      setState(() => _errorMessage = passwordPolicyMessage);
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
          .resetRecoveryPassword(token, pw);
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
      // 세션 만료·정책 위반 등 → 서버 메시지 그대로 안내
      if (mounted) setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // 코드 재전송. 안내는 기존 인라인 문구 자리(_errorMessage)에 표시,
  // 429(재전송 제한 초과)도 같은 자리에 서버 문구 그대로.
  Future<void> _resend() async {
    if (_submitting || _verifying) return;
    try {
      await ref.read(authRepositoryProvider).requestRecovery(widget.email);
      if (!mounted) return;
      setState(() {
        _errorMessage = '인증 코드를 다시 보냈습니다.';
        // 새 코드가 발송되면 기존 확인 상태는 무효 → 처음부터 다시
        _recoveryToken = null;
        _codeCtrl.clear();
      });
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
              // 다른 페이지(계정 정보)와 같은 52px 헤더 높이에 공용 뒤로가기 버튼
              SizedBox(
                height: 52,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: AppBackButton(onTap: () => context.pop()),
                ),
              ),
              const SizedBox(height: 28),
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
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    // 확인 완료 후엔 코드가 소모된 상태라 수정 불가로 잠근다
                    child: AbsorbPointer(
                      absorbing: _codeVerified,
                      child: Opacity(
                        opacity: _codeVerified ? 0.5 : 1,
                        child: AuthTextField(
                          controller: _codeCtrl,
                          hintText: '123456',
                          keyboardType: TextInputType.number,
                          fillColor: AppColors.background,
                          focusFillColor: _focusFill,
                          borderRadius: 17,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _VerifyCodeButton(
                    verified: _codeVerified,
                    verifying: _verifying,
                    onTap: _onVerifyCode,
                  ),
                ],
              ),
              if (_codeVerified) ...[
                const SizedBox(height: 6),
                const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Text(
                    '인증코드가 확인되었습니다.',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.folderOrange,
                    ),
                  ),
                ),
              ],
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
                  '8자 이상, 영문 대문자ㆍ소문자ㆍ숫자 포함 (한글 불가)',
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

// 인증코드 옆 "확인" 버튼. 확인 중 스피너, 완료 후 체크로 바뀌고 비활성화.
class _VerifyCodeButton extends StatelessWidget {
  const _VerifyCodeButton({
    required this.verified,
    required this.verifying,
    required this.onTap,
  });

  final bool verified;
  final bool verifying;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (verified || verifying) ? null : onTap,
      child: Container(
        width: 72,
        height: 50, // AuthTextField 높이와 맞춤
        decoration: BoxDecoration(
          color: verified
              ? AppColors.background
              : AppColors.folderOrange.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(17),
        ),
        alignment: Alignment.center,
        child: verifying
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  color: AppColors.white,
                  strokeWidth: 2,
                ),
              )
            : verified
                ? const Icon(Icons.check, size: 22, color: AppColors.folderOrange)
                : const Text(
                    '확인',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                    ),
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
