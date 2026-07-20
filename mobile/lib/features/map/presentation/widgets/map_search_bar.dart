import 'package:flutter/material.dart';

import '../../../../shared/widgets/app_back_button.dart';

// 지도 상단 검색바. 탭 → 검색 페이지, X → 검색어 해제.
class MapSearchBar extends StatelessWidget {
  const MapSearchBar({
    required this.keyword,
    required this.onBack,
    required this.onTap,
    required this.onClear,
    super.key,
  });

  final String? keyword; // null이면 힌트 표시
  final VoidCallback onBack;
  final VoidCallback onTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 15, left: 15, right: 15),
      child: Row(
        children: [
          AppBackButton(
            onTap: onBack,
            padding: const EdgeInsets.only(right: 12),
          ),
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Color(0xFF8A847B), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        keyword ?? '지하철역, 카페, 식당 ....',
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: keyword != null
                              ? const Color(0xFF1F2125)
                              : const Color(0xFFB2B2B2),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (keyword != null)
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: onClear,
                        child: const Padding(
                          padding: EdgeInsets.only(left: 8),
                          child: Icon(Icons.close,
                              size: 18, color: Color(0xFF8A847B)),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
