import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../markers/data/repositories/marker_repository_impl.dart';
import '../../../markers/domain/entities/category.dart';
import '../../../markers/domain/entities/marker.dart';
import '../../../markers/presentation/providers/marker_provider.dart';

class MarkerEditChipsSheet extends ConsumerStatefulWidget {
  const MarkerEditChipsSheet({
    required this.marker,
    required this.tripId,
    required this.categories,
    required this.dayCount,
    required this.onSaved,
    required this.isUnsaved,
    super.key,
  });

  final TripMarker marker;
  final String tripId;
  final List<Category> categories;
  final int dayCount;
  final ValueChanged<TripMarker> onSaved;
  final bool isUnsaved;

  @override
  ConsumerState<MarkerEditChipsSheet> createState() =>
      _MarkerEditChipsSheetState();
}

class _MarkerEditChipsSheetState extends ConsumerState<MarkerEditChipsSheet> {
  late String? _selectedCategoryId;
  late Set<int> _selectedDays;
  late TripMarker _savedMarker;

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.marker.categoryId;
    _selectedDays = widget.marker.visitDays.toSet();
    _savedMarker = widget.marker;
  }

  bool get _hasUnsavedChanges {
    final Set<int> savedDays = _savedMarker.visitDays.toSet();
    return _selectedCategoryId != _savedMarker.categoryId ||
        _selectedDays.length != savedDays.length ||
        !_selectedDays.containsAll(savedDays);
  }

  TripMarker get _optimisticMarker => widget.marker.copyWith(
        categoryId: _selectedCategoryId,
        visitDays: _selectedDays.toList()..sort(),
      );

  @override
  void dispose() {
    if (_hasUnsavedChanges) widget.onSaved(_optimisticMarker);
    super.dispose();
  }

  Future<void> _saveExplicit() async {
    if (!_hasUnsavedChanges) return;
    final TripMarker optimistic = _optimisticMarker;
    widget.onSaved(optimistic);
    setState(() => _savedMarker = optimistic);
    if (!widget.isUnsaved) {
      try {
        await ref.read(markerRepositoryProvider).updateMarker(
          widget.tripId,
          widget.marker.id,
          categoryId: optimistic.categoryId,
          clearCategoryId: optimistic.categoryId == null,
          visitDays: optimistic.visitDays,
        );
      } catch (_) {}
      ref.invalidate(markerEntitiesProvider(widget.tripId));
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        12,
        24,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          widget.categories.isEmpty
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
                    itemCount: widget.categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final Category category = widget.categories[i];
                      final bool active = _selectedCategoryId == category.id;
                      return GestureDetector(
                        // 같은 칩 다시 누르면 선택 해제 (토글)
                        onTap: () => setState(() => _selectedCategoryId =
                            active ? null : category.id),
                        child: Container(
                          height: 30,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
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
          if (widget.dayCount > 0) ...[
            const SizedBox(height: 16),
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
                    final String label = i == 0 ? '선택 안함' : 'Day$i';
                    final bool active = i == 0
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
          ],
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _saveExplicit,
            child: Container(
              height: 45, // 기존 30의 1.5배
              width: double.infinity,
              decoration: BoxDecoration(
                color: _hasUnsavedChanges
                    ? const Color(0xCC2A6FDB)
                    : const Color(0xFFD5D5D5),
                borderRadius: BorderRadius.circular(17),
                boxShadow: _hasUnsavedChanges
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
              child: const Text(
                '저장',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
