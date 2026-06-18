import 'package:flutter/material.dart';

import '../../../routes/domain/entities/route_stop.dart';

const Color _orange = Color(0xFFFE8505);
const Color _orangeChip = Color(0xFFFEC181);
const Color _grayChip = Color(0xFFF1F2F4);
const Color _ink = Color(0xFF1F2125);

const List<TransportMode> _transportOrder = [
  TransportMode.car,
  TransportMode.publictransit,
  TransportMode.bicycle,
  TransportMode.foot,
];

String transportLabel(TransportMode m) => switch (m) {
      TransportMode.car => '차량',
      TransportMode.publictransit => '대중교통',
      TransportMode.bicycle => '자전거',
      TransportMode.foot => '도보',
    };

/// 경로 편집 항목: 마커 카드 + 그 마커의 이동수단 카드(페어).
/// 선택 시 마커 박스를 메인 오렌지로 채우고 이동수단 선택기를 펼친다.
/// 펼침은 왼쪽→오른쪽으로 reveal(ClipRect + widthFactor).
/// 마지막 stop은 이동수단 카드 없음(showTransport=false).
class RouteStopCard extends StatefulWidget {
  const RouteStopCard({
    required this.stop,
    required this.selected,
    required this.showTransport,
    required this.categoryName,
    required this.categoryColor,
    required this.onSelectToggle,
    required this.onTimeTap,
    required this.onTransportSelected,
    this.onNavigate,
    super.key,
  });

  final RouteStop stop;
  final bool selected;
  final bool showTransport;
  final String? categoryName;
  final Color categoryColor;
  final VoidCallback onSelectToggle;
  final VoidCallback onTimeTap;
  final ValueChanged<TransportMode> onTransportSelected;

  /// 다음 stop으로 길안내 실행. null이면 비활성(이동수단 미설정·마지막 stop).
  final VoidCallback? onNavigate;

  @override
  State<RouteStopCard> createState() => _RouteStopCardState();
}

class _RouteStopCardState extends State<RouteStopCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _reveal;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      value: widget.selected ? 1 : 0,
    );
    _reveal = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
  }

  @override
  void didUpdateWidget(RouteStopCard old) {
    super.didUpdateWidget(old);
    if (widget.selected != old.selected) {
      widget.selected ? _controller.forward() : _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _timeLabel {
    final String? t = widget.stop.visitTime;
    if (t == null || t.length < 5) return '--:--';
    return t.substring(0, 5);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _markerCard(),
        if (widget.showTransport) ...[
          const SizedBox(height: 8),
          _selector(),
        ],
      ],
    );
  }

  // 펼침/접힘 전환을 왼쪽→오른쪽 reveal로 표현.
  Widget _selector() {
    return AnimatedBuilder(
      animation: _reveal,
      builder: (context, _) {
        if (_reveal.value == 0) return _collapsedSelector();
        return ClipRect(
          child: Align(
            alignment: Alignment.centerLeft,
            widthFactor: _reveal.value,
            child: _expandedSelector(),
          ),
        );
      },
    );
  }

  Widget _markerCard() {
    final bool selected = widget.selected;
    final Color fg = selected ? Colors.white : _ink;
    return GestureDetector(
      onTap: widget.onSelectToggle,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: selected ? _orange : Colors.white,
          borderRadius: BorderRadius.circular(17),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0D000000), blurRadius: 10, offset: Offset(4, 0)),
            BoxShadow(
                color: Color(0x0D000000), blurRadius: 10, offset: Offset(0, 4)),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            GestureDetector(
              onTap: widget.onTimeTap,
              behavior: HitTestBehavior.opaque,
              child: Text(
                _timeLabel,
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: fg,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.stop.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
            ),
            const SizedBox(width: 8),
            _categoryChip(),
          ],
        ),
      ),
    );
  }

  Widget _categoryChip() {
    const Color fg = Colors.white;
    return Container(
      height: 20,
      constraints: const BoxConstraints(minWidth: 50),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: widget.selected ? Colors.transparent : widget.categoryColor,
        border: widget.selected
            ? Border.all(color: Colors.white, width: 1)
            : null,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Text(
        widget.categoryName ?? '기타',
        style: const TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }

  // 펼침: 4개 이동수단 세그먼트. 선택값은 오렌지 칩.
  Widget _expandedSelector() {
    return Container(
      decoration: BoxDecoration(
        color: _grayChip,
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        children: _transportOrder.map(_segment).toList(),
      ),
    );
  }

  Widget _segment(TransportMode m) {
    final bool on = widget.stop.transportToNext == m;
    return Expanded(
      child: GestureDetector(
        onTap: () => widget.onTransportSelected(m),
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: on ? _orangeChip : Colors.transparent,
            borderRadius: BorderRadius.circular(17),
          ),
          child: Text(
            transportLabel(m),
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _ink,
            ),
          ),
        ),
      ),
    );
  }

  // 접힘: 선택값 칩 + 편집 아이콘. 탭 시 펼침.
  Widget _collapsedSelector() {
    final TransportMode? m = widget.stop.transportToNext;
    return GestureDetector(
      onTap: widget.onSelectToggle,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Container(
            height: 30,
            constraints: const BoxConstraints(minWidth: 60),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: m == null ? _grayChip : _orangeChip,
              borderRadius: BorderRadius.circular(17),
            ),
            child: Text(
              m == null ? '이동수단' : transportLabel(m),
              style: const TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _ink,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: widget.onNavigate,
            behavior: HitTestBehavior.opaque,
            child: Icon(
              Icons.directions,
              size: 25,
              color:
                  widget.onNavigate == null ? const Color(0xFFB2B2B2) : _orange,
            ),
          ),
        ],
      ),
    );
  }
}
