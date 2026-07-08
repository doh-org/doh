import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/errors/app_exception.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_back_button.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../widgets/auth_text_field.dart';

// 입력칸 선택(포커스) 시 배경 (로그인 화면과 동일한 peach)
const Color _focusFill = Color(0xFFFEDFBF);

/// 비밀번호 찾기 1단계: 가입 이메일을 받아 재설정 코드 메일 발송을 요청한다.
/// 성공하면 2단계(코드+새 비번 입력)로 이동한다.
class PasswordResetRequestPage extends ConsumerStatefulWidget {
  const PasswordResetRequestPage({super.key});

  @override
  ConsumerState<PasswordResetRequestPage> createState() =>
      _PasswordResetRequestPageState();
}

class _PasswordResetRequestPageState
    extends ConsumerState<PasswordResetRequestPage> {
  final TextEditingController _emailCtrl = TextEditingController();
  String? _errorMessage;
  bool _sending = false; // 요청 중 중복 탭 방지

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    if (_sending) return;
    final String email = _emailCtrl.text.trim();
    // 로컬 검증: 형식 오류는 서버까지 안 가고 즉시 안내
    if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
      setState(() => _errorMessage = '올바른 이메일을 입력해주세요.');
      return;
    }
    setState(() {
      _errorMessage = null;
      _sending = true;
    });
    try {
      await ref.read(authRepositoryProvider).requestRecovery(email);
      if (!mounted) return;
      // 서버는 이메일 존재 여부와 무관하게 성공을 주므로 바로 코드 입력 단계로
      context.push('/password-reset/verify', extra: email);
    } on AppException catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _sending = false);
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
                '비밀번호 찾기',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 30,
                  fontWeight: FontWeight.w500,
                  color: AppColors.folderOrange,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                '가입한 이메일로 6자리 인증 코드를 보내드립니다.',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.gray,
                ),
              ),
              const SizedBox(height: 28),
              const Padding(
                padding: EdgeInsets.only(left: 8, bottom: 4),
                child: Text(
                  '이메일',
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.dark,
                  ),
                ),
              ),
              AuthTextField(
                controller: _emailCtrl,
                hintText: '이메일을 입력하세요',
                keyboardType: TextInputType.emailAddress,
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
                  onPressed: _sending ? null : _onSubmit,
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
                  child: _sending
                      ? const SizedBox(
                          width: 22,
                          height: 22,
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
                            color: AppColors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: const Text(
                      '로그인으로 돌아가기',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppColors.gray,
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
