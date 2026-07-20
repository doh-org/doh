import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_cursor.dart';
import '../../../markers/data/repositories/marker_repository_impl.dart';
import '../../../markers/domain/entities/category.dart';
import '../../../markers/domain/entities/marker.dart';
import '../../../markers/presentation/providers/marker_provider.dart';
import '../../../../shared/widgets/update_error_dialog.dart';
import '../../domain/entities/place.dart';

class PlaceAddSheet extends ConsumerStatefulWidget {
  const PlaceAddSheet({
    required this.tripId,
    required this.latitude,
    required this.longitude,
    required this.dayCount,
    this.initialName,
    this.initialAddress,
    this.place,
    this.source = MarkerSource.longpress,
    super.key,
  });

  final String tripId;
  final double latitude;
  final double longitude;
  final int dayCount;
  final String? initialName;
  final String? initialAddress;
  final Place? place;
  final MarkerSource source;

  @override
  ConsumerState<PlaceAddSheet> createState() => _PlaceAddSheetState();
}

class _PlaceAddSheetState extends ConsumerState<PlaceAddSheet> {
  late final TextEditingController _nameCtrl;
  String? _selectedCategoryId;
  final Set<int> _selectedDays = {};
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(
      text: widget.place?.title ?? widget.initialName ?? '',
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      await ref.read(markerRepositoryProvider).createMarker(
            tripId: widget.tripId,
            name: _nameCtrl.text.trim(),
            latitude: widget.latitude,
            longitude: widget.longitude,
            categoryId: _selectedCategoryId,
            address: widget.place?.address ?? widget.initialAddress,
            detail: widget.place?.toDetail(),
            source: widget.source,
            visitDays: _selectedDays.toList()..sort(),
          );
      ref.invalidate(markerEntitiesProvider(widget.tripId));
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) showUpdateErrorDialog(context, '저장에 실패했습니다.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider(widget.tripId));

    // isScrollControlled: true 모달이 이미 키보드 위에 위치시켜 줌
    // → 여기서 viewInsets 추가 패딩 불필요 (이중 적용 방지)
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 드래그 핸들
          Center(
            child: Container(
              width: 82,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFECEBE7),
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 장소 이름 입력
          const Text(
            '장소명',
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFFB2B2B2),
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _nameCtrl,
            autofocus: widget.place == null,
            cursorColor: appCursorColor(),
            decoration: InputDecoration(
              hintText: '장소 이름',
              hintStyle: const TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Color(0xFFB2B2B2),
              ),
              filled: true,
              fillColor: const Color(0xFFF1F2F4),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(17),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(17),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(17),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1F2125),
            ),
          ),
          const SizedBox(height: 16),

          // 카테고리 선택
          const Text(
            '카테고리',
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFFB2B2B2),
            ),
          ),
          const SizedBox(height: 6),
          categoriesAsync.when(
            data: (cats) => cats.isEmpty
                ? const Text(
                    '카테고리 없음',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 13,
                      color: Color(0xFFB2B2B2),
                    ),
                  )
                : SizedBox(
                    height: 30,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: cats.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final Category category = cats[i];
                        final bool active = _selectedCategoryId == category.id;
                        return GestureDetector(
                          // 같은 칩 다시 누르면 선택 해제 (토글)
                          onTap: () => setState(() =>
                              _selectedCategoryId = active ? null : category.id),
                          child: Container(
                            height: 30,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              // 방문 날짜 칩과 동일: 회색 배경, 선택 시 주황
                              color: active
                                  ? const Color(0xCCFE8505)
                                  : const Color(0xFFF1F2F4),
                              borderRadius: BorderRadius.circular(25),
                              boxShadow: active
                                  ? const [
                                      BoxShadow(
                                        color: Color(0x4D000000),
                                        blurRadius: 4,
                                        offset: Offset(1, 1),
                                      )
                                    ]
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              category.name,
                              style: TextStyle(
                                fontFamily: 'Pretendard',
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: active
                                    ? Colors.white
                                    : const Color(0xFF1F2125),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
            loading: () => const SizedBox(
              height: 24,
              child: Center(
                child: SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 16),

          // Day 선택 (선택사항)
          if (widget.dayCount > 0) ...[
            const Text(
              '방문 날짜',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFFB2B2B2),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: SizedBox(
                height: 30,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  itemCount: widget.dayCount + 1,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (_, i) {
                  final label = i == 0 ? '선택 안함' : 'Day$i';
                  final active = i == 0
                      ? _selectedDays.isEmpty
                      : _selectedDays.contains(i);
                  return GestureDetector(
                    onTap: () => setState(() {
                      if (i == 0) {
                        _selectedDays.clear();
                      } else if (_selectedDays.contains(i)) {
                        _selectedDays.remove(i);
                      } else {
                        _selectedDays.add(i);
                      }
                    }),
                    child: Container(
                      width: i == 0 ? 72 : 60,
                      height: 30,
                      decoration: BoxDecoration(
                        color: active
                            ? const Color(0xCCFE8505)
                            : const Color(0xFFF1F2F4),
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: active
                            ? const [
                                BoxShadow(
                                  color: Color(0x4D000000),
                                  blurRadius: 4,
                                  offset: Offset(1, 1),
                                )
                              ]
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        label,
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: active
                              ? Colors.white
                              : const Color(0xFF1F2125),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            ),
            const SizedBox(height: 16),
          ],

          // 저장 버튼
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: _loading ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFE8505),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(17),
                ),
              ),
              child: _loading
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text(
                      '저장',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
