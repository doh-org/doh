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

  // 버튼 텍스트와 폭 측정에 같은 스타일을 써야 계산이 어긋나지 않음
  static const String _searchLabel = '현위치에서 검색';
  static const TextStyle _searchLabelStyle = TextStyle(
    fontFamily: 'Pretendard',
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: Color(0xFF1F2125),
  );
  static const double _searchHPadding = 10; // 버튼 좌우 패딩
  static const double _pressedBorderWidth = 1; // 누름 테두리(양쪽 1px씩 폭 증가)
  static const double _minGap = 5; // 폴더 칩 ↔ 검색 버튼 최소 간격

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 73, left: 20, right: 20),
      child: SizedBox(
        height: 30,
        child: LayoutBuilder(
          builder: (_, BoxConstraints constraints) {
            // "폴더명이 몇 자든 버튼과 안 겹치려면 칩이 어디까지 커도 되나?"
            // → 버튼 텍스트 실제 폭을 재서 버튼 왼쪽 끝을 계산 (글자 수 하드코딩 대신)
            final TextPainter searchPainter = TextPainter(
              text: const TextSpan(text: _searchLabel, style: _searchLabelStyle),
              textDirection: TextDirection.ltr,
              textScaler: MediaQuery.textScalerOf(context), // 시스템 글꼴 크기 반영
            )..layout();
            // 버튼 폭 = 텍스트 + 좌우 패딩 + 누름 테두리(눌렀을 때 2px 커지는 것까지 포함)
            final double searchWidth = searchPainter.width +
                _searchHPadding * 2 +
                _pressedBorderWidth * 2;
            // 버튼은 가로 중앙 정렬 → 왼쪽 끝 = (전체 폭 - 버튼 폭) / 2
            final double searchLeft =
                (constraints.maxWidth - searchWidth) / 2;
            // 칩 최대 폭: 버튼 왼쪽 끝에서 최소 간격만큼 띄움 (좁은 화면에선 0으로 방어)
            final double chipMaxWidth =
                (searchLeft - _minGap).clamp(0.0, constraints.maxWidth);
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
                          _searchLabel,
                          style: _searchLabelStyle,
                        ),
                      ),
                    ),
                  ),
                ),
                // 폴더 칩: 왼쪽, 버튼 왼쪽 끝 - 5px까지만 (위 레이어)
                Align(
                  alignment: Alignment.centerLeft,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: chipMaxWidth),
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
