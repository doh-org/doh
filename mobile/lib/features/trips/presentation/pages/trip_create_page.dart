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
    final trip = await ref
        .read(tripRepositoryProvider)
        .getTrip(widget.tripId!);
    if (!mounted) return;
    setState(() {
      _titleCtrl.text = trip.title;
      _startDate = trip.startDate;
      _endDate = trip.endDate;
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  String _nightsLabel() {
    if (_startDate == null || _endDate == null) return '';
    final nights = _endDate!.difference(_startDate!).inDays;
    return '${nights}박 ${nights + 1}일';
  }

  Future<void> _submit() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    if (_startDate == null || _endDate == null) return;

    setState(() => _loading = true);
    try {
      final repo = ref.read(tripRepositoryProvider);
      final colorHex = AppColors.coverColorHexes[_colorIndex];

      if (_isEdit) {
        await repo.updateTrip(
          widget.tripId!,
          title: _titleCtrl.text.trim(),
          startDate: _startDate,
          endDate: _endDate,
          coverColor: colorHex,
        );
      } else {
        await repo.createTrip(
          title: _titleCtrl.text.trim(),
          startDate: _startDate,
          endDate: _endDate,
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
    final title = _isEdit ? '여행 수정' : '여행 추가';
    final ctaLabel = _isEdit ? '수정 완료' : '이 여행에 추가';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: AppColors.dark),
        title: Text(
          title,
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
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            // 커버 미리보기
            Container(
              height: 130,
              decoration: BoxDecoration(
                color: AppColors.coverColors[_colorIndex],
                borderRadius: BorderRadius.circular(17),
              ),
              alignment: Alignment.center,
              child: Text(
                _titleCtrl.text.isEmpty ? '새 여행' : _titleCtrl.text,
                style: const TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // 색상 팔레트
            Row(
              children: List.generate(
                AppColors.coverColors.length,
                (i) => GestureDetector(
                  onTap: () => setState(() => _colorIndex = i),
                  child: Container(
                    width: 15,
                    height: 15,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: AppColors.coverColors[i],
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // 여행 이름
            _Label(label: '여행 이름', required: true),
            const SizedBox(height: 8),
            Stack(
              children: [
                TextField(
                  controller: _titleCtrl,
                  maxLength: 14,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 12,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: '서울 맛집 여행, 수원 가을 여행...',
                    hintStyle: const TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 12,
                      color: Color(0xFFB2B2B2),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF1F2F4),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(17),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.fromLTRB(16, 20, 64, 20),
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
                _Label(label: '여행 기간', required: true),
                const Spacer(),
                if (_startDate != null && _endDate != null)
                  Text(
                    _nightsLabel(),
                    style: const TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.folderOrange,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(17),
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
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                calendarStyle: CalendarStyle(
                  rangeStartDecoration: const BoxDecoration(
                    color: AppColors.folderOrange,
                    shape: BoxShape.circle,
                  ),
                  rangeEndDecoration: const BoxDecoration(
                    color: AppColors.folderOrange,
                    shape: BoxShape.circle,
                  ),
                  withinRangeDecoration: BoxDecoration(
                    color: AppColors.folderOrange.withAlpha(51),
                    shape: BoxShape.rectangle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: AppColors.folderOrange.withAlpha(80),
                    shape: BoxShape.circle,
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
            // CTA
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xCC2A6FDB),
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
