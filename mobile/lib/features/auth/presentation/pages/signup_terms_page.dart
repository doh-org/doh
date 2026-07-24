import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/errors/app_exception.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_back_button.dart';
import '../../domain/entities/user.dart';
import '../../utils/legal_documents.dart';
import '../providers/auth_provider.dart';

const Color _accent = Color(0xCC2A6FDB);
const Color _accentDisabled = Color(0x662A6FDB);

/// 회원가입 마지막 단계에서 넘겨받는 가입 확정 값.
/// 약관 동의를 받은 뒤에야 이 값으로 계정을 실제로 생성한다.
class SignupCompletionArgs {
  const SignupCompletionArgs({
    required this.token,
    required this.password,
    required this.nickname,
  });

  final String token; // 코드 확인으로 받은 가입 세션 토큰
  final String password;
  final String nickname;
}

/// 회원가입 4단계: 이용약관·개인정보처리방침 전문을 보여주고
/// 필수 항목을 직접 체크로 동의받은 뒤 계정 생성(completeSignup)을 호출한다.
/// 성공 시 자동 로그인되어 라우터 redirect가 /trips로 보낸다.
class SignupTermsPage extends ConsumerStatefulWidget {
  const SignupTermsPage({required this.args, super.key});

  final SignupCompletionArgs args;

  @override
  ConsumerState<SignupTermsPage> createState() => _SignupTermsPageState();
}

class _SignupTermsPageState extends ConsumerState<SignupTermsPage> {
  bool _agreeTerms = false; // 서비스 이용약관(필수)
  bool _agreePrivacy = false; // 개인정보 수집·이용(필수)
  String? _errorMessage;

  bool get _allAgreed => _agreeTerms && _agreePrivacy;

  // "전체 동의" 토글
  void _toggleAll() {
    final bool next = !_allAgreed;
    setState(() {
      _agreeTerms = next;
      _agreePrivacy = next;
    });
  }

  String _messageFromError(Object error) {
    return switch (error) {
      AppException e => e.message,
      _ => '연결에 실패했습니다. 다시 시도해주세요.',
    };
  }
  // 필수 동의가 모두 끝난 상태에서만 실제 계정 생성 요청.
  Future<void> _onSubmit() async {
    if (!_allAgreed) return;
    setState(() => _errorMessage = null);
    await ref.read(authNotifierProvider.notifier).completeSignup(
          widget.args.token,
          widget.args.password,
          widget.args.nickname,
        );
  }

  @override
  Widget build(BuildContext context) {
    // completeSignup 결과: 에러면 안내, 성공(로그인)은 라우터 redirect가 처리
    ref.listen<AsyncValue<User?>>(authNotifierProvider, (_, next) {
      if (next.hasError) {
        setState(() => _errorMessage = _messageFromError(next.error!));
      }
    });

    final bool submitting = ref.watch(authNotifierProvider).isLoading;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 다른 인증 페이지와 같은 52px 헤더 높이에 공용 뒤로가기 버튼
              SizedBox(
                height: 52,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: AppBackButton(onTap: () => context.pop()),
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                '약관 동의',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 30,
                  fontWeight: FontWeight.w500,
                  color: AppColors.folderOrange,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                '서비스 이용을 위해 아래 약관에 동의해주세요.',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.gray,
                ),
              ),
              const SizedBox(height: 24),
              _ConsentRow(
                label: '약관 전체 동의',
                checked: _allAgreed,
                bold: true,
                onTap: _toggleAll,
              ),
              const Divider(height: 24, color: AppColors.background, thickness: 1),
              _ConsentRow(
                label: '[필수] 서비스 이용약관 동의',
                checked: _agreeTerms,
                onTap: () => setState(() => _agreeTerms = !_agreeTerms),
              ),
              const SizedBox(height: 8),
              const _DocumentBox(text: termsOfServiceText),
              const SizedBox(height: 20),
              _ConsentRow(
                label: '[필수] 개인정보 수집·이용 동의',
                checked: _agreePrivacy,
                onTap: () => setState(() => _agreePrivacy = !_agreePrivacy),
              ),
              const SizedBox(height: 8),
              const _DocumentBox(text: privacyPolicyText),
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
              const SizedBox(height: 20),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  // 필수 동의 전에는 비활성. 요청 중에도 중복 탭 방지.
                  onPressed: (_allAgreed && !submitting) ? _onSubmit : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: AppColors.white,
                    disabledBackgroundColor: _accentDisabled,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(17),
                    ),
                  ),
                  child: submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: AppColors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          '가입 완료',
                          style: TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFFDFDFD),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// 체크박스 + 라벨 한 줄. 탭하면 상태가 토글된다.
class _ConsentRow extends StatelessWidget {
  const _ConsentRow({
    required this.label,
    required this.checked,
    required this.onTap,
    this.bold = false,
  });

  final String label;
  final bool checked;
  final VoidCallback onTap;
  final bool bold; // "전체 동의"만 강조

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque, // 라벨 옆 여백을 눌러도 토글되게
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: checked ? _accent : AppColors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: checked ? _accent : AppColors.gray,
                width: 1.5,
              ),
            ),
            child: checked
                ? const Icon(Icons.check, size: 16, color: AppColors.white)
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 15,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                color: AppColors.dark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 약관 원문을 담는 고정 높이 스크롤 박스
class _DocumentBox extends StatelessWidget {
  const _DocumentBox({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(17),
      ),
      child: Scrollbar(
        child: SingleChildScrollView(
          child: Text(
            text,
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: AppColors.dark,
              height: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}
