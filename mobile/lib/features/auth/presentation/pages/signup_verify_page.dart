import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/errors/app_exception.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_back_button.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../utils/password_policy.dart';
import '../widgets/auth_text_field.dart';
import 'signup_terms_page.dart';

const Color _focusFill = Color(0xFFFEDFBF);
const Color _accent = Color(0xCC2A6FDB);
const Color _accentDisabled = Color(0x662A6FDB);

/// 회원가입 2·3단계: 메일로 받은 6자리 코드를 확인한 뒤 비밀번호·닉네임을 설정한다.
/// 코드 확인 성공 시 가입 세션 토큰을 받아 보관하고, 그 토큰으로 계정 설정을 완료한다.
/// 완료되면 자동 로그인되어 라우터 redirect가 /trips로 보낸다.
class SignupVerifyPage extends ConsumerStatefulWidget {
  const SignupVerifyPage({required this.email, super.key});

  /// 1단계에서 코드를 발송한 이메일. 코드 확인·재발송에 쓴다.
  final String email;

  @override
  ConsumerState<SignupVerifyPage> createState() => _SignupVerifyPageState();
}

class _SignupVerifyPageState extends ConsumerState<SignupVerifyPage> {
  final TextEditingController _codeCtrl = TextEditingController();
  final TextEditingController _pwCtrl = TextEditingController();
  final TextEditingController _confirmCtrl = TextEditingController();
  final TextEditingController _nicknameCtrl = TextEditingController();
  String? _errorMessage;
  // 재전송 안내(성공·429 모두)는 "코드 재전송" 링크 바로 아랫줄에 표시
  String? _resendMessage;
  bool _verifying = false; // 코드 확인 요청 중 중복 탭 방지
  bool _obscurePw = true;

  // 코드 확인 성공 시 받는 가입 세션 토큰. 비번·닉네임 설정에만 사용
  // null = 아직 미확인. 코드는 1회용이라 확인 후 입력칸을 닫음
  String? _signupToken;

  bool get _codeVerified => _signupToken != null;

  @override
  void dispose() {
    _codeCtrl.dispose();
    _pwCtrl.dispose();
    _confirmCtrl.dispose();
    _nicknameCtrl.dispose();
    super.dispose();
  }

  // 코드 즉시 확인. 성공하면 가입 세션 토큰을 받아 보관하고 코드칸 닫음
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
      _resendMessage = null; // 새 시도 시작 → 이전 재전송 안내 제거
      _verifying = true;
    });
    try {
      final String token =
          await ref.read(authRepositoryProvider).verifySignup(widget.email, code);
      if (mounted) setState(() => _signupToken = token);
    } on AppException catch (e) {
      // 코드 불일치·만료 등 → 서버 메시지 그대로 안내
      if (mounted) setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  // 검증 통과 시 약관 동의 단계로 이동
  void _onSubmit() {
    final String? token = _signupToken;
    final String pw = _pwCtrl.text;
    final String nickname = _nicknameCtrl.text.trim();
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
      setState(() => _errorMessage = '비밀번호가 일치하지 않습니다.');
      return;
    }
    if (nickname.isEmpty) {
      setState(() => _errorMessage = '닉네임을 입력해주세요.');
      return;
    }
    setState(() => _errorMessage = null);
    // 검증된 값을 약관 페이지로 넘겨, 동의 후 그쪽에서 completeSignup 호출
    context.push(
      '/signup/terms',
      extra: SignupCompletionArgs(
        token: token,
        password: pw,
        nickname: nickname,
      ),
    );
  }

  // 코드 재전송. 안내는 "코드 재전송" 링크 아랫줄(_resendMessage)에 표시
  Future<void> _resend() async {
    if (_verifying) return;
    try {
      await ref.read(authRepositoryProvider).resendSignup(widget.email);
      if (!mounted) return;
      setState(() {
        _resendMessage = '인증 코드를 다시 보냈습니다.';
        _errorMessage = null;
        // 새 코드가 발송되면 기존 확인 상태는 무효 → 처음부터 다시
        _signupToken = null;
        _codeCtrl.clear();
      });
    } on AppException catch (e) {
      if (mounted) setState(() => _resendMessage = e.message);
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
              // 다른 페이지와 같은 52px 헤더 높이에 공용 뒤로가기 버튼
              SizedBox(
                height: 52,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: AppBackButton(onTap: () => context.pop()),
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                '회원가입',
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
                    // 확인 완료 후엔 코드가 소모된 상태라 수정 불가로 닫음
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
              _fieldLabel('비밀번호'),
              AuthTextField(
                controller: _pwCtrl,
                hintText: '비밀번호를 입력하세요',
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
                  '영문 대소문자ㆍ숫자 | 8자 이상',
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.folderOrange,
                  ),
                ),
              ),
              const SizedBox(height: 15),
              _fieldLabel('비밀번호 재입력'),
              AuthTextField(
                controller: _confirmCtrl,
                hintText: '비밀번호를 다시 입력하세요',
                obscureText: true,
                fillColor: AppColors.background,
                focusFillColor: _focusFill,
                borderRadius: 17,
              ),
              const SizedBox(height: 15),
              _fieldLabel('닉네임'),
              AuthTextField(
                controller: _nicknameCtrl,
                hintText: '닉네임을 입력하세요',
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
                  onPressed: _onSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: AppColors.white,
                    disabledBackgroundColor: _accentDisabled,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(17),
                    ),
                  ),
                  child: const Text(
                    '다음',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFFDFDFD),
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
              // 재전송 안내는 링크 바로 아랫줄에 가운데 정렬로 표시
              if (_resendMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  _resendMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.error,
                  ),
                ),
              ],
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
          color: verified ? AppColors.background : _accent,
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
