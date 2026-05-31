import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/repositories/trip_repository_impl.dart';
import '../providers/trip_provider.dart';

class TripCreatePage extends ConsumerStatefulWidget {
  const TripCreatePage({this.tripId, super.key});
  final String? tripId;

  @override
  ConsumerState<TripCreatePage> createState() => _TripCreatePageState();
}

class _TripCreatePageState extends ConsumerState<TripCreatePage> {
  final _titleCtrl = TextEditingController();
  int _colorIndex = 0;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _loading = false;

  bool get _isEdit => widget.tripId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) _loadExisting();
  }

  Future<void> _loadExisting() async {
    // tripsProvider 캐시에서 먼저 탐색, 없으면 네트워크 요청
    final cached = ref.read(tripsProvider).valueOrNull;
    final found = cached?.where((t) => t.id == widget.tripId);
    final trip = (found != null && found.isNotEmpty)
        ? found.first
        : await ref.read(tripRepositoryProvider).getTrip(widget.tripId!);
    if (!mounted) return;
    final idx = AppColors.coverColorHexes.indexOf(trip.coverColor ?? '');
    setState(() {
      _titleCtrl.text = trip.title;
      _startDate = trip.startDate;
      _endDate = trip.endDate;
      _colorIndex = idx >= 0 ? idx : 0;
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  String _nightsLabel() {
    if (_startDate == null) return '';
    final end = _endDate ?? _startDate!;
    final nights = end.difference(_startDate!).inDays;
    if (nights == 0) return '1일';
    return '$nights박 ${nights + 1}일';
  }

  Future<void> _submit() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    if (_startDate == null) return;
    final effectiveEnd = _endDate ?? _startDate;
    setState(() => _loading = true);
    try {
      final repo = ref.read(tripRepositoryProvider);
      final colorHex = AppColors.coverColorHexes[_colorIndex];
      if (_isEdit) {
        await repo.updateTrip(
          widget.tripId!,
          title: _titleCtrl.text.trim(),
          startDate: _startDate,
          endDate: effectiveEnd,
          coverColor: colorHex,
        );
      } else {
        await repo.createTrip(
          title: _titleCtrl.text.trim(),
          startDate: _startDate,
          endDate: effectiveEnd,
          coverColor: colorHex,
        );
      }
      ref.invalidate(tripsProvider);
      // TODO: 지도 화면으로 이동해야 함. 지도 구현 완료 후 변경 필요.
      if (mounted) context.go('/trips');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pageTitle = _isEdit ? '여행 수정' : '여행 추가';
    // ⑮ CTA 텍스트: 생성 "여행 생성", 수정 "수정 완료"
    final ctaLabel = _isEdit ? '수정 완료' : '여행 생성';

    return Scaffold(
      backgroundColor: Colors.white, // #0 배경 #FFFFFF
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: AppColors.dark),
        title: Text(
          pageTitle,
          style: const TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F1D1A),
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            // 커버 미리보기
            Container(
              height: 130,
              decoration: BoxDecoration(
                color: AppColors.coverColors[_colorIndex],
                borderRadius: BorderRadius.circular(17),
              ),
              // ⑯ 커버 텍스트: 좌측 하단
              alignment: Alignment.bottomLeft,
              padding: const EdgeInsets.fromLTRB(20, 0, 0, 20),
              child: Text(
                _titleCtrl.text.isEmpty ? '새 여행' : _titleCtrl.text,
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: (_colorIndex == 0 || _colorIndex == 4) ? const Color(0xFF000000) : Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 10),
            // ⑰⑱ 색상 팔레트: 오른쪽 정렬, gap 7px, 갤러리 아이콘
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ...List.generate(
                  AppColors.coverColors.length,
                  (i) => GestureDetector(
                    onTap: () => setState(() => _colorIndex = i),
                    child: Container(
                      width: 15,
                      height: 15,
                      margin: const EdgeInsets.only(right: 7),
                      decoration: BoxDecoration(
                        color: AppColors.coverColors[i],
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                // ⑱ 갤러리 아이콘 (v0: 비활성)
                const Icon(
                  Icons.photo_library_outlined,
                  size: 15,
                  color: AppColors.gray,
                ),
              ],
            ),
            const SizedBox(height: 24),
            // 여행 이름
            const _Label(label: '여행 이름', required: true),
            const SizedBox(height: 8),
            Stack(
              children: [
                Theme(
                  data: Theme.of(context).copyWith(
                    textSelectionTheme: const TextSelectionThemeData(
                      selectionHandleColor: AppColors.primary,
                      selectionColor: Color(0x33FF8830),
                    ),
                  ),
                  child: TextField(
                    controller: _titleCtrl,
                    maxLength: 14,
                    onChanged: (_) => setState(() {}),
                    cursorColor: AppColors.dark,
                    style: const TextStyle(fontFamily: 'Pretendard', fontSize: 14),
                    decoration: const InputDecoration(
                      counterText: '',
                      hintText: '서울 맛집 여행, 수원 가을 여행...',
                      hintStyle: TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 14,
                        color: Color(0xFFB2B2B2),
                      ),
                      filled: true,
                      fillColor: Color(0xFFF1F2F4),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(17)),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.fromLTRB(10, 20, 64, 20),
                    ),
                  ),
                ),
                Positioned(
                  right: 16,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Text(
                      '${_titleCtrl.text.length}/14',
                      style: const TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: AppColors.folderOrange,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // 여행 기간
            Row(
              children: [
                const _Label(label: '여행 기간', required: true),
                const Spacer(),
                if (_startDate != null)
                  Text(
                    _nightsLabel(),
                    style: const TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.folderOrange,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            // ⑳ 달력 컨테이너 그림자
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(17),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x4D000000),
                    offset: Offset(1, 1),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: TableCalendar(
                firstDay: DateTime(2020),
                lastDay: DateTime(2030),
                focusedDay: _startDate ?? DateTime.now(),
                rangeStartDay: _startDate,
                rangeEndDay: _endDate,
                rangeSelectionMode: RangeSelectionMode.enforced,
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2125),
                  ),
                ),
                // #31 요일 SemiBold 10px
                daysOfWeekHeight: 33,
                daysOfWeekStyle: const DaysOfWeekStyle(
                  weekdayStyle: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray,
                  ),
                  weekendStyle: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray,
                  ),
                ),
                // #33 날짜 행 높이
                rowHeight: 38,
                calendarStyle: CalendarStyle(
                  defaultTextStyle: const TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1F1D1A),
                  ),
                  weekendTextStyle: const TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1F1D1A),
                  ),
                  outsideTextStyle: const TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.gray,
                  ),
                  rangeStartDecoration: const BoxDecoration(
                    color: AppColors.folderOrange,
                    shape: BoxShape.circle,
                  ),
                  rangeStartTextStyle: const TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  rangeEndDecoration: const BoxDecoration(
                    color: AppColors.folderOrange,
                    shape: BoxShape.circle,
                  ),
                  rangeEndTextStyle: const TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  rangeHighlightColor: AppColors.folderOrange.withAlpha(51),
                  withinRangeTextStyle: const TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1F1D1A),
                  ),
                  todayDecoration: BoxDecoration(
                    color: AppColors.folderOrange.withAlpha(80),
                    shape: BoxShape.circle,
                  ),
                ),
                // ⑲ 날짜 셀 일·토 색상
                // ⑲ 일·토 헤더 + 날짜 색상
                calendarBuilders: CalendarBuilders(
                  dowBuilder: (context, day) {
                    const names = ['일', '월', '화', '수', '목', '금', '토'];
                    final text = names[day.weekday % 7];
                    final color = day.weekday == DateTime.sunday
                        ? const Color.fromRGBO(229, 46, 1, 0.8)
                        : day.weekday == DateTime.saturday
                            ? const Color.fromRGBO(42, 111, 219, 0.8)
                            : AppColors.gray;
                    return Center(
                      child: Text(
                        text,
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 12,
                          color: color,
                        ),
                      ),
                    );
                  },
                  defaultBuilder: (context, day, _) {
                    final color = _weekdayColor(day.weekday);
                    if (color == null) return null;
                    return Center(
                      child: Text(
                        '${day.day}',
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 12,
                          color: color,
                        ),
                      ),
                    );
                  },
                  outsideBuilder: (context, day, _) {
                    final color = _weekdayColor(day.weekday);
                    if (color == null) return null;
                    return Center(
                      child: Text(
                        '${day.day}',
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 12,
                          color: color.withAlpha(100),
                        ),
                      ),
                    );
                  },
                  rangeStartBuilder: (context, day, _) => Center(
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: AppColors.folderOrange,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${day.day}',
                        style: const TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  rangeEndBuilder: (context, day, _) => Center(
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: AppColors.folderOrange,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${day.day}',
                        style: const TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                onRangeSelected: (start, end, _) {
                  setState(() {
                    _startDate = start;
                    _endDate = end;
                  });
                },
              ),
            ),
            const SizedBox(height: 24),
            // ㉑ CTA 버튼 그림자
            Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(17),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x4D000000),
                    offset: Offset(1, 1),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xCC2A6FDB),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(17),
                  ),
                ),
                child: _loading
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        ctaLabel,
                        style: const TextStyle(
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
    );
  }

  Color? _weekdayColor(int weekday) {
    if (weekday == DateTime.sunday) {
      return const Color.fromRGBO(229, 46, 1, 0.8);
    }
    if (weekday == DateTime.saturday) {
      return const Color.fromRGBO(42, 111, 219, 0.8);
    }
    return null;
  }
}

class _Label extends StatelessWidget {
  const _Label({required this.label, this.required = false});
  final String label;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1F2125),
        ),
        children: [
          TextSpan(text: label),
          if (required)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: AppColors.folderOrange),
            ),
        ],
      ),
    );
  }
}
