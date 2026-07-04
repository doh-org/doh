import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/errors/app_exception.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../domain/entities/user.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_text_field.dart';

class SignupPage extends ConsumerStatefulWidget {
  const SignupPage({super.key});

  @override
  ConsumerState<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends ConsumerState<SignupPage> {
  final _emailCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  final _nicknameCtrl = TextEditingController();
  String? _errorMessage;
  bool _obscurePw = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _pwCtrl.dispose();
    _nicknameCtrl.dispose();
    super.dispose();
  }

  String _messageFromError(Object error) {
    return switch (error) {
      ValidationException e => e.message,
      AuthException e => e.message,
      ConflictException e => e.message,
      NetworkException e => e.message,
      AppException e => e.message,
      _ => '연결에 실패했습니다. 다시 시도해주세요.',
    };
  }

  bool _isValidPassword(String pw) =>
      pw.length >= 8 &&
      pw.contains(RegExp(r'[A-Z]')) &&
      pw.contains(RegExp(r'[a-z]')) &&
      pw.contains(RegExp(r'[0-9]'));

  void _onSignUp() {
    final email = _emailCtrl.text.trim();
    final pw = _pwCtrl.text;
    final nickname = _nicknameCtrl.text.trim();
    if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
      setState(() => _errorMessage = '올바른 이메일을 입력해주세요.');
      return;
    }
    if (!_isValidPassword(pw)) {
      setState(() => _errorMessage = '비밀번호는 8자 이상, 대·소문자·숫자를 포함해야 합니다.');
      return;
    }
    if (nickname.isEmpty) {
      setState(() => _errorMessage = '닉네임을 입력해주세요.');
      return;
    }
    setState(() => _errorMessage = null);
    ref.read(authNotifierProvider.notifier).signUp(email, pw, nickname);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<User?>>(authNotifierProvider, (_, next) {
      if (next.hasError) {
        setState(() => _errorMessage = _messageFromError(next.error!));
      }
    });

    final isLoading = ref.watch(authNotifierProvider).isLoading;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 80),
              const Text(
                '회원가입',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 30,
                  fontWeight: FontWeight.w500,
                  color: AppColors.folderOrange,
                ),
              ),
              const SizedBox(height: 28),
              _LabeledField(
                label: '이메일',
                controller: _emailCtrl,
                hintText: '이메일을 입력하세요',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 15),
              _LabeledField(
                label: '비밀번호',
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
              _LabeledField(
                label: '닉네임',
                controller: _nicknameCtrl,
                hintText: '닉네임을 입력하세요',
              ),
              const SizedBox(height: 8),
              if (_errorMessage != null)
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
              const SizedBox(height: 16),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _onSignUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xCC2A6FDB),
                    foregroundColor: AppColors.white,
                    disabledBackgroundColor: const Color(0x662A6FDB),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(17),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: AppColors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          '회원가입',
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
                    '이미 계정이 있으신가요? ',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.gray,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: const Text(
                      '로그인',
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
}

// 라벨이 박스 위에 붙는 입력 필드. 박스는 AuthTextField 재사용.
class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.controller,
    required this.hintText,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.suffixIcon,
  });

  final String label;
  final TextEditingController controller;
  final String hintText;
  final TextInputType keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 4),
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.dark,
            ),
          ),
        ),
        AuthTextField(
          controller: controller,
          hintText: hintText,
          keyboardType: keyboardType,
          obscureText: obscureText,
          suffixIcon: suffixIcon,
          fillColor: AppColors.background,
          focusFillColor: const Color(0xFFFEDFBF),
          borderRadius: 17,
        ),
      ],
    );
  }
}
