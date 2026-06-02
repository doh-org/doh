import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../markers/data/repositories/marker_repository_impl.dart';
import '../../../markers/domain/entities/category.dart';
import '../../../markers/domain/entities/marker.dart';
import '../../../markers/presentation/widgets/category_chip.dart';

class MarkerEditChipsSheet extends ConsumerStatefulWidget {
  const MarkerEditChipsSheet({
    required this.marker,
    required this.tripId,
    required this.categories,
    required this.dayCount,
    required this.onSaved,
    super.key,
  });

  final TripMarker marker;
  final String tripId;
  final List<Category> categories;
  final int dayCount;
  final ValueChanged<TripMarker> onSaved;

  @override
  ConsumerState<MarkerEditChipsSheet> createState() =>
      _MarkerEditChipsSheetState();
}

class _MarkerEditChipsSheetState extends ConsumerState<MarkerEditChipsSheet> {
  late String? _selectedCategoryId;
  late Set<int> _selectedDays;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.marker.categoryId;
    _selectedDays = widget.marker.visitDays.toSet();
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      final updated = await ref.read(markerRepositoryProvider).updateMarker(
            widget.tripId,
            widget.marker.id,
            categoryId: _selectedCategoryId,
            clearCategoryId: _selectedCategoryId == null,
            visitDays: _selectedDays.toList()..sort(),
          );
      if (mounted) {
        widget.onSaved(updated);
        Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('저장에 실패했습니다.')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
              fontSize: 12,
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
                    fontSize: 12,
                    color: Color(0xFFB2B2B2),
                  ),
                )
              : SizedBox(
                  height: 30,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: widget.categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) => CategoryChip(
                      category: widget.categories[i],
                      selected: _selectedCategoryId == widget.categories[i].id,
                      onSelected: (_) => setState(() =>
                          _selectedCategoryId =
                              _selectedCategoryId == widget.categories[i].id
                                  ? null
                                  : widget.categories[i].id),
                    ),
                  ),
                ),
          if (widget.dayCount > 0) ...[
            const SizedBox(height: 16),
            const Text(
              '방문 날짜',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 12,
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
                            fontSize: 11,
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
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: _loading ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xCC2A6FDB),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(17),
                ),
              ),
              child: _loading
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      '저장',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 14,
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
