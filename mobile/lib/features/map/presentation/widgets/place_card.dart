import 'package:flutter/material.dart';

class PlaceCard extends StatelessWidget {
  const PlaceCard({
    required this.name,
    required this.category,
    required this.categoryColor,
    required this.categoryIcon,
    this.address,
    // v0 제외: 마커 좋아요(찜) 기능 — 추후 복구
    // this.likeCount = 0,
    // this.isLiked = false,
    this.onTap,
    // this.onLikeTap,
    super.key,
  });

  final String name;
  final String category;
  final Color categoryColor;
  final IconData categoryIcon;
  final String? address;
  // v0 제외: 마커 좋아요(찜) 기능 — 추후 복구
  // final int likeCount;
  // final bool isLiked;
  final VoidCallback? onTap;
  // final VoidCallback? onLikeTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        height: 80,
        child: Stack(
          children: [
            // 카드 배경
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(17),
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x1A000000),
                        blurRadius: 5,
                        offset: Offset(0, 4)),
                    BoxShadow(
                        color: Color(0x0D000000),
                        blurRadius: 5,
                        offset: Offset(4, 0)),
                  ],
                ),
              ),
            ),

            // 카테고리 원 (left-13.5 top-15 size-50)
            Positioned(
              left: 13.5,
              top: 15,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: categoryColor,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Icon(categoryIcon, size: 20, color: Colors.white),
              ),
            ),

            // 카테고리 배지 (left-74 top-13 h-16 w-40)
            Positioned(
              left: 74,
              top: 13,
              child: Container(
                height: 16,
                width: 40,
                decoration: BoxDecoration(
                  color: categoryColor,
                  borderRadius: BorderRadius.circular(25),
                ),
                alignment: Alignment.center,
                child: Text(
                  category,
                  style: const TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                    height: 1.0, // 기본 줄높이가 박스보다 커서 중앙이 어긋나는 것 보정
                  ),
                ),
              ),
            ),

            // 장소명 (left-74 top-31)
            Positioned(
              left: 74,
              top: 31,
              right: 50,
              child: Text(
                name,
                style: const TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF070707),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // 부연 (left-74 top-53)
            Positioned(
              left: 74,
              top: 53,
              right: 50,
              child: Text(
                address ?? category,
                style: const TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF7E7E7E),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // v0 제외: 마커 좋아요(찜) 버튼 — 하트 토글 + 좋아요 수 표시. 추후 복구
            // Positioned(
            //   right: 15,
            //   top: 0,
            //   bottom: 0,
            //   child: GestureDetector(
            //     onTap: onLikeTap,
            //     behavior: HitTestBehavior.opaque,
            //     child: Column(
            //       mainAxisAlignment: MainAxisAlignment.center,
            //       children: [
            //         Icon(
            //           isLiked ? Icons.favorite : Icons.favorite_border,
            //           size: 25,
            //           color: isLiked
            //               ? const Color(0xFFFE8505)
            //               : const Color(0xFFD5D5D5),
            //         ),
            //         if (likeCount > 0)
            //           Text(
            //             '$likeCount',
            //             style: const TextStyle(
            //               fontFamily: 'Pretendard',
            //               fontSize: 13,
            //               fontWeight: FontWeight.w500,
            //               color: Color(0xFF757575),
            //             ),
            //           ),
            //       ],
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}
