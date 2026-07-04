import 'package:flutter/material.dart';

// 지도 상단 칩 줄: 폴더 칩(왼쪽) + "현위치에서 검색"(중앙).
class MapChipBar extends StatefulWidget {
  const MapChipBar({
    required this.tripTitle,
    required this.canSearchHere, // 검색어가 있고 검색 중이 아닐 때만 활성
    required this.onSearchHere,
    required this.onSelectTrip,
    super.key,
  });

  final String? tripTitle;
  final bool canSearchHere;
  final Future<void> Function() onSearchHere;
  final VoidCallback onSelectTrip;

  @override
  State<MapChipBar> createState() => _MapChipBarState();
}

class _MapChipBarState extends State<MapChipBar> {
  bool _pressed = false; // "현위치에서 검색" 누름 표시(주황 테두리)

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 73, left: 20, right: 20),
      child: SizedBox(
        height: 30,
        child: LayoutBuilder(
          builder: (_, BoxConstraints constraints) {
            final double half = constraints.maxWidth / 2;
            return Stack(
              children: [
                // Stack 전체 너비 확보
                SizedBox(width: constraints.maxWidth, height: 30),
                // 현위치에서 검색: 가로 중앙 (아래 레이어)
                Align(
                  alignment: Alignment.center,
                  child: GestureDetector(
                    onTapDown: (_) {
                      if (widget.canSearchHere) {
                        setState(() => _pressed = true);
                      }
                    },
                    onTapUp: (_) => setState(() => _pressed = false),
                    onTapCancel: () => setState(() => _pressed = false),
                    onTap: widget.canSearchHere ? widget.onSearchHere : null,
                    child: IntrinsicWidth(
                      child: Container(
                        height: 30,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: _pressed
                              ? Border.all(
                                  color: const Color(0xFFFE8505), width: 1)
                              : null,
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x1A000000),
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Text(
                          '현위치에서 검색',
                          style: TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1F2125),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // 폴더 칩: 왼쪽, maxWidth = 절반 - 10px (위 레이어)
                Align(
                  alignment: Alignment.centerLeft,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: half - 10),
                    child: GestureDetector(
                      onTap: widget.onSelectTrip,
                      child: Container(
                        height: 30,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x1A000000),
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.folder_outlined,
                                size: 20, color: Color(0xFFFE8505)),
                            const SizedBox(width: 3),
                            Flexible(
                              child: Text(
                                widget.tripTitle ?? '여행 선택',
                                style: const TextStyle(
                                  fontFamily: 'Pretendard',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF1F2125),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
