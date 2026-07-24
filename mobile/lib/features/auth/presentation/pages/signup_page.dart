import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/errors/app_exception.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_back_button.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../widgets/auth_text_field.dart';

class SignupPage extends ConsumerStatefulWidget {
  const SignupPage({super.key});

  @override
  ConsumerState<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends ConsumerState<SignupPage> {
  final _emailCtrl = TextEditingController();
  String? _errorMessage;
  bool _sending = false; // 코드 발송 중 중복 탭 방지

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  // 1단계: 이메일 검증 → 확인 코드 발송 요청 → 코드 입력 단계로 이동
  Future<void> _onRequestCode() async {
    if (_sending) return;
    final String email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
      setState(() => _errorMessage = '올바른 이메일을 입력해주세요.');
      return;
    }
    setState(() {
      _errorMessage = null;
      _sending = true;
    });
    try {
      await ref.read(authRepositoryProvider).requestSignupCode(email);
      if (!mounted) return;
      // 코드 검증 단계로 이메일 전달 (계정 확정·재발송에 사용)
      context.push('/signup/verify', extra: email);
    } on AppException catch (e) {
      // 이미 가입된 이메일 등 → 서버 메시지 그대로 안내
      if (mounted) setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 비번찾기 페이지와 같은 52px 헤더 높이에 공용 뒤로가기 버튼
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
              const Text(
                '가입할 이메일로 6자리 인증 코드를 보내드립니다.',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.gray,
                ),
              ),
              const SizedBox(height: 28),
              _LabeledField(
                label: '이메일',
                controller: _emailCtrl,
                hintText: 'memotrip@google.com',
                keyboardType: TextInputType.emailAddress,
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
                  onPressed: _sending ? null : _onRequestCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xCC2A6FDB),
                    foregroundColor: AppColors.white,
                    disabledBackgroundColor: const Color(0x662A6FDB),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(17),
                    ),
                  ),
                  child: _sending
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: AppColors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          '인증 코드 받기',
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
  });

  final String label;
  final TextEditingController controller;
  final String hintText;
  final TextInputType keyboardType;

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
          fillColor: AppColors.background,
          focusFillColor: const Color(0xFFFEDFBF),
          borderRadius: 17,
        ),
      ],
    );
  }
}
