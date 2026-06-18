import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_cursor.dart';

// 카드/레이아웃 치수 (Figma 133-478)
const double _cardW = 300;
const double _cardH = 200;
const double _radius = 17;
const double _hourW = 76;
const double _minW = 81;
const double _colonW = 21;
const double _gap = 15;
const double _itemExtent = 62;
const double _selectedSize = 45;
const double _unselectedSize = 25;
const Color _ink = Color(0xFF070707); // 선택값
const Color _muted = Color(0xFFB2B2B2); // 이웃값
const int _hourMax = 23;
const int _minMax = 59;

/// 시·분 드럼(휠) 시간 선택 모달. 드래그로 굴리고, 중앙 숫자 탭 시 키보드 입력.
/// 바깥(배리어) 탭 = 현재 값 확정 후 닫힘. 취소(뒤로가기)는 null 반환.
Future<TimeOfDay?> showTimeWheelPicker(
  BuildContext context, {
  required TimeOfDay initial,
}) {
  return showDialog<TimeOfDay>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.3),
    barrierDismissible: false, // 바깥 탭은 직접 처리해 현재 값을 반환
    builder: (_) => _TimeWheelDialog(initial: initial),
  );
}

class _TimeWheelDialog extends StatefulWidget {
  const _TimeWheelDialog({required this.initial});

  final TimeOfDay initial;

  @override
  State<_TimeWheelDialog> createState() => _TimeWheelDialogState();
}

class _TimeWheelDialogState extends State<_TimeWheelDialog> {
  late int _hour = widget.initial.hour;
  late int _minute = widget.initial.minute;
  late int _hourSel = widget.initial.hour; // 휠 raw 선택 인덱스
  late int _minSel = widget.initial.minute;

  late final FixedExtentScrollController _hourCtrl =
      FixedExtentScrollController(initialItem: _hour);
  late final FixedExtentScrollController _minCtrl =
      FixedExtentScrollController(initialItem: _minute);

  final TextEditingController _editCtrl = TextEditingController();
  final FocusNode _editFocus = FocusNode();

  int? _editing; // 0=시, 1=분, null=없음

  @override
  void initState() {
    super.initState();
    _editFocus.addListener(() {
      if (!_editFocus.hasFocus && _editing != null) _commitEdit();
    });
  }

  @override
  void dispose() {
    _hourCtrl.dispose();
    _minCtrl.dispose();
    _editCtrl.dispose();
    _editFocus.dispose();
    super.dispose();
  }

  int _posMod(int v, int n) => ((v % n) + n) % n;

  void _enterEdit(int col) {
    final int cur = col == 0 ? _hour : _minute;
    _editCtrl.text = cur.toString().padLeft(2, '0');
    _editCtrl.selection =
        TextSelection(baseOffset: 0, extentOffset: _editCtrl.text.length);
    setState(() => _editing = col);
    _editFocus.requestFocus();
  }

  void _commitEdit() {
    final int? col = _editing;
    if (col == null) return;
    _editing = null; // 재진입(포커스 해제 콜백) 차단
    final int max = col == 0 ? _hourMax : _minMax;
    final int parsed = int.tryParse(_editCtrl.text) ?? (col == 0 ? _hour : _minute);
    final int value = parsed.clamp(0, max);
    setState(() {
      if (col == 0) {
        _hour = value;
        _hourSel = value;
      } else {
        _minute = value;
        _minSel = value;
      }
    });
    (col == 0 ? _hourCtrl : _minCtrl).jumpToItem(value);
  }

  void _close() {
    if (_editing != null) _commitEdit();
    Navigator.of(context).pop(TimeOfDay(hour: _hour, minute: _minute));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 바깥 탭 = 확정 후 닫힘
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _close,
          ),
        ),
        Center(
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: () {}, // 카드 내부 탭은 닫힘으로 전파하지 않음
              child: Container(
                width: _cardW,
                height: _cardH,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(_radius),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _column(isHour: true),
                    const SizedBox(width: _gap),
                    _colon(),
                    const SizedBox(width: _gap),
                    _column(isHour: false),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _colon() {
    return const SizedBox(
      width: _colonW,
      child: Text(
        ':',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Pretendard',
          fontSize: _selectedSize,
          fontWeight: FontWeight.w600,
          color: _ink,
          height: 1,
        ),
      ),
    );
  }

  Widget _column({required bool isHour}) {
    final double w = isHour ? _hourW : _minW;
    final bool editing = _editing == (isHour ? 0 : 1);
    // 휠을 항상 마운트해 스크롤 컨트롤러 detach를 막는다(입력값 jumpToItem 보장).
    // 입력 TextField는 편집 중인 컬럼에만 생성(공용 _editCtrl/_editFocus 중복 부착 방지).
    return SizedBox(
      width: w,
      height: _cardH,
      child: IndexedStack(
        index: editing ? 1 : 0,
        sizing: StackFit.expand,
        children: [
          _wheel(isHour: isHour),
          editing ? _input(w) : const SizedBox.shrink(),
        ],
      ),
    );
  }

  Widget _wheel({required bool isHour}) {
    final FixedExtentScrollController ctrl = isHour ? _hourCtrl : _minCtrl;
    final int n = isHour ? _hourMax + 1 : _minMax + 1;
    return ListWheelScrollView.useDelegate(
      controller: ctrl,
      itemExtent: _itemExtent,
      diameterRatio: 3,
      physics: const FixedExtentScrollPhysics(),
      onSelectedItemChanged: (i) => setState(() {
        if (isHour) {
          _hourSel = i;
          _hour = _posMod(i, n);
        } else {
          _minSel = i;
          _minute = _posMod(i, n);
        }
      }),
      childDelegate: ListWheelChildBuilderDelegate(
        builder: (ctx, rawIndex) => _wheelItem(isHour: isHour, rawIndex: rawIndex),
      ),
    );
  }

  Widget _wheelItem({required bool isHour, required int rawIndex}) {
    final int n = isHour ? _hourMax + 1 : _minMax + 1;
    final int value = _posMod(rawIndex, n);
    final bool center = rawIndex == (isHour ? _hourSel : _minSel);
    // 탭 영역을 슬롯(itemExtent) 전체 높이로 넓혀 선택을 쉽게.
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (center) {
          _enterEdit(isHour ? 0 : 1);
        } else {
          (isHour ? _hourCtrl : _minCtrl).animateToItem(
            rawIndex,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      },
      child: Center(
        child: Text(
          value.toString().padLeft(2, '0'),
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontSize: center ? _selectedSize : _unselectedSize,
            fontWeight: FontWeight.w600,
            color: center ? _ink : _muted,
            height: 1,
          ),
        ),
      ),
    );
  }

  Widget _input(double w) {
    return Center(
      child: SizedBox(
        width: w,
        child: TextField(
          controller: _editCtrl,
          focusNode: _editFocus,
          autofocus: true,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          cursorColor: appCursorColor(),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(2),
          ],
          onSubmitted: (_) => _commitEdit(),
          style: const TextStyle(
            fontFamily: 'Pretendard',
            fontSize: _selectedSize,
            fontWeight: FontWeight.w600,
            color: _ink,
            height: 1,
          ),
          decoration: const InputDecoration(
            border: InputBorder.none,
            isDense: true,
            counterText: '',
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ),
    );
  }
}
