import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../features/map/presentation/utils/location_terms_text.dart';
import '../../../../shared/widgets/app_back_button.dart';
import '../../../../shared/widgets/legal_document_box.dart';
import '../../utils/legal_documents.dart';

const double _boxHeight = 240; // 읽기 전용 화면이라 가입 화면 박스(180)보다 높게
const Color _requiredBadge = AppColors.folderOrange;
const Color _optionalBadge = AppColors.blue;

/// 더보기 메뉴 '약관 정보'로 진입하는 읽기 전용 약관 화면.
/// 가입 시 필수 동의 2건과 선택 동의인 위치기반서비스 약관 전문을 표시한다.
class LegalInfoPage extends StatelessWidget {
  const LegalInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            _Header(),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(15, 12, 15, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '가입 시 동의한 약관과 선택 약관의 전문입니다.',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.gray,
                      ),
                    ),
                    SizedBox(height: 20),
                    _DocumentSection(
                      badge: '[필수]',
                      badgeColor: _requiredBadge,
                      title: '서비스 이용약관',
                      text: termsOfServiceText,
                    ),
                    SizedBox(height: 24),
                    _DocumentSection(
                      badge: '[필수]',
                      badgeColor: _requiredBadge,
                      title: '개인정보 수집·이용',
                      text: privacyPolicyText,
                    ),
                    SizedBox(height: 24),
                    _DocumentSection(
                      badge: '[선택]',
                      badgeColor: _optionalBadge,
                      title: '위치기반서비스 이용약관',
                      note: '동의하지 않아도 회원가입과 여행 계획 기능을 모두 이용할 수 있습니다.\n'
                          '동의 여부는 설정의 위치 정보 동의에서 언제든 바꿀 수 있습니다.',
                      text: locationServiceTermsText,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 뒤로가기 + 가운데 제목. 설정 화면과 같은 52px 헤더.
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
              '약관 정보',
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

// 배지 + 제목 + (선택 시 안내문) + 원문 박스 한 묶음.
class _DocumentSection extends StatelessWidget {
  const _DocumentSection({
    required this.badge,
    required this.badgeColor,
    required this.title,
    required this.text,
    this.note,
  });

  final String badge; // [필수] | [선택]
  final Color badgeColor;
  final String title;
  final String text;
  final String? note; // 선택 항목의 미동의 시 영향 안내

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Row(
            children: [
              Text(
                badge,
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: badgeColor,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.dark,
                ),
              ),
            ],
          ),
        ),
        if (note != null)
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 6),
            child: Text(
              note!,
              style: const TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.gray,
                height: 1.4,
              ),
            ),
          ),
        const SizedBox(height: 8),
        LegalDocumentBox(text: text, height: _boxHeight),
      ],
    );
  }
}
