import 'package:flutter/material.dart';

// 엿보기 상태에서 화면에 남겨둘 높이(px). 손잡이 + 카테고리 칩 + 장소명 정도 노출
const double _peekVisible = 120;
// 손잡이 근처만 드래그를 받는 영역 높이(px). 본문 스크롤·버튼 탭과 겹치지 않게 좁게 제한
const double _dragZone = 40;
// 이 속도(px/s)를 넘기면 손을 뗀 위치와 무관하게 던진 방향으로 결정
const double _flingVelocity = 700;
const Duration _settleDuration = Duration(milliseconds: 250);

/// 마커 상세시트를 지도 위에 얹는 슬라이드 패널.
/// 모달이 아니라서 지도를 덮는 배리어가 없음 — 지도 팬·줌·탭이 그대로 살아있음.
/// 높이는 자식(상세시트) 내용이 결정. 세 자리를 오감:
///   펼침(0) ↔ 엿보기(지도 탭) → 손잡이를 아래로 끌면 닫힘
class MarkerDetailPanel extends StatefulWidget {
  const MarkerDetailPanel({
    required this.child,
    required this.peeked,
    required this.onPeek,
    required this.onExpand,
    required this.onClose,
    super.key,
  });

  final Widget child;

  /// 아래로 내려 일부만 보이는 상태인지. 부모(MapPage)가 지도 탭·제스처로 켬
  final bool peeked;

  final VoidCallback onPeek;
  final VoidCallback onExpand;
  final VoidCallback onClose;

  @override
  State<MarkerDetailPanel> createState() => _MarkerDetailPanelState();
}

class _MarkerDetailPanelState extends State<MarkerDetailPanel> {
  // 자식의 실제 높이. 엿보기·닫기 위치를 px로 계산하려면 이 값이 필요
  final GlobalKey _contentKey = GlobalKey();
  double _height = 0;

  bool _dragging = false;
  double _dragDy = 0; // 드래그 중인 손가락 위치(아래로 +)

  @override
  void initState() {
    super.initState();
    _scheduleMeasure();
  }

  @override
  void didUpdateWidget(MarkerDetailPanel old) {
    super.didUpdateWidget(old);
    _scheduleMeasure(); // 카테고리·연락처 유무로 내용 높이가 바뀔 수 있음
  }

  // 레이아웃이 끝난 뒤에야 크기를 알 수 있어 다음 프레임으로 미룸
  void _scheduleMeasure() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final RenderBox? box =
          _contentKey.currentContext?.findRenderObject() as RenderBox?;
      final double h = box?.size.height ?? 0;
      if (h <= 0 || h == _height) return;
      setState(() => _height = h);
    });
  }

  // 엿보기 위치 = 아래로 (전체높이 - 남길높이)만큼 내린 지점
  double get _peekDy =>
      (_height - _peekVisible).clamp(0.0, _height).toDouble();

  // 손을 뗐을 때 머물 자리
  double get _restDy => widget.peeked ? _peekDy : 0;

  void _onDragStart(DragStartDetails _) {
    setState(() {
      _dragging = true;
      _dragDy = _restDy; // 지금 보이는 위치에서 이어서 끌기
    });
  }

  void _onDragUpdate(DragUpdateDetails d) {
    setState(() => _dragDy = (_dragDy + d.delta.dy).clamp(0.0, _height));
  }

  void _onDragEnd(DragEndDetails d) {
    final double velocity = d.velocity.pixelsPerSecond.dy;
    final double dy = _dragDy;
    setState(() => _dragging = false);

    // 위로 던짐 → 무조건 펼침
    if (velocity < -_flingVelocity) {
      widget.onExpand();
      return;
    }
    // 아래로 던짐 → 엿보기 아래였으면 시트 닫고, 위였으면 엿보기까지만
    if (velocity > _flingVelocity) {
      dy >= _peekDy ? widget.onClose() : widget.onPeek();
      return;
    }
    // 천천히 놓음 → 손 뗀 위치에서 가장 가까운 자리로
    if (dy > (_peekDy + _height) / 2) {
      widget.onClose();
    } else if (dy > _peekDy / 2) {
      widget.onPeek();
    } else {
      widget.onExpand();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: TweenAnimationBuilder<double>(
        // 드래그 중엔 손가락을 그대로 따라가고(0ms), 놓으면 목적지로 미끄러짐
        tween: Tween<double>(end: _dragging ? _dragDy : _restDy),
        duration: _dragging ? Duration.zero : _settleDuration,
        curve: Curves.easeOut,
        builder: (_, double dy, Widget? child) =>
            Transform.translate(offset: Offset(0, dy), child: child),
        child: Stack(
          children: [
            // 높이를 재려고 키를 씌움. Stack 크기도 이 자식이 결정
            KeyedSubtree(key: _contentKey, child: widget.child),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: _dragZone,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                // 내려가 있을 때 손잡이를 탭하면 다시 펼침
                onTap: widget.peeked ? widget.onExpand : null,
                onVerticalDragStart: _onDragStart,
                onVerticalDragUpdate: _onDragUpdate,
                onVerticalDragEnd: _onDragEnd,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
