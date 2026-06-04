import 'package:flutter/material.dart';

class PlaceCard extends StatelessWidget {
  const PlaceCard({
    required this.name,
    required this.category,
    required this.categoryColor,
    required this.categoryIcon,
    this.address,
    this.likeCount = 0,
    this.onTap,
    super.key,
  });

  final String name;
  final String category;
  final Color categoryColor;
  final IconData categoryIcon;
  final String? address;
  final int likeCount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(17),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 5,
              offset: Offset(0, 4),
            ),
            BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 5,
              offset: Offset(4, 0),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            // 카테고리 원형 아이콘
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: categoryColor,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Icon(categoryIcon, size: 22, color: Colors.white),
            ),
            const SizedBox(width: 12),
            // 장소 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 카테고리 badge pill
                  Container(
                    height: 15,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    constraints: const BoxConstraints(minWidth: 40),
                    decoration: BoxDecoration(
                      color: categoryColor,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      category,
                      style: const TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    name,
                    style: const TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF070707),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (address != null)
                    Text(
                      address!,
                      style: const TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF7E7E7E),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            // 좋아요 수
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.favorite_border,
                  size: 22,
                  color: Color(0xFF8A847B),
                ),
                const SizedBox(height: 2),
                Text(
                  '$likeCount',
                  style: const TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF757575),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
          ],
        ),
      ),
    );
  }
}
