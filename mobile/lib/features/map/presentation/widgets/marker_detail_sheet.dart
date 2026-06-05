import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../markers/data/repositories/marker_repository_impl.dart';
import '../../../markers/domain/entities/category.dart';
import '../../../markers/domain/entities/marker.dart';
import '../../../markers/presentation/providers/marker_provider.dart';
import '../../../trips/presentation/providers/trip_provider.dart';
import 'marker_edit_chips_sheet.dart';

class MarkerDetailSheet extends ConsumerStatefulWidget {
  const MarkerDetailSheet({
    required this.marker,
    required this.tripId,
    required this.allMarkers,
    this.isLiked = false,
    super.key,
  });

  final TripMarker marker;
  final String tripId;
  final List<TripMarker> allMarkers;
  final bool isLiked;

  @override
  ConsumerState<MarkerDetailSheet> createState() => _MarkerDetailSheetState();
}

class _MarkerDetailSheetState extends ConsumerState<MarkerDetailSheet> {
  int _transportIndex = 0;
  String? _departureId;
  late String _destinationId;
  late TripMarker _marker;
  late final TextEditingController _nameCtrl;
  bool _editingName = false;
  bool _saved = true;
  late bool _isLiked;

  static const _transportLabels = ['차량', '대중교통', '자전거', '도보'];
  static const _transportIcons = [
    Icons.directions_car,
    Icons.subway,
    Icons.directions_bike,
    Icons.directions_walk,
  ];

  @override
  void initState() {
    super.initState();
    _marker = widget.marker;
    _destinationId = widget.marker.id;
    _nameCtrl = TextEditingController(text: widget.marker.name);
    _isLiked = widget.isLiked;
    _saved = widget.allMarkers.any((m) => m.id == widget.marker.id);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty || name == _marker.name) return;
    try {
      final updated = await ref.read(markerRepositoryProvider).updateMarker(
            widget.tripId, _marker.id, name: name,
          );
      setState(() => _marker = updated);
      ref.invalidate(markerEntitiesProvider(widget.tripId));
    } catch (_) {}
  }

  Future<void> _toggleBookmark() async {
    if (!_saved) return;
    final ok = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '닫기',
      barrierColor: Colors.black26,
      pageBuilder: (ctx, _, __) => Align(
        alignment: const Alignment(0, 0.5),
        child: _DeleteConfirmDialog(name: _marker.name),
      ),
    );
    if (ok == true && mounted) {
      await ref.read(markerRepositoryProvider).deleteMarker(widget.tripId, _marker.id);
      ref.invalidate(markerEntitiesProvider(widget.tripId));
      if (mounted) Navigator.pop(context);
    }
  }

  String? _detail(String key) {
    final v = _marker.detail[key];
    if (v == null || v.toString().isEmpty) return null;
    return v.toString();
  }

  void _showEditSheet(
    BuildContext context,
    List<Category> categories,
    int dayCount,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MarkerEditChipsSheet(
        marker: _marker,
        tripId: widget.tripId,
        categories: categories,
        dayCount: dayCount,
        onSaved: (updated) {
          setState(() => _marker = updated);
          ref.invalidate(markerEntitiesProvider(widget.tripId));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider(widget.tripId));
    final tripAsync = ref.watch(tripDetailNotifierProvider(widget.tripId));
    final categories = categoriesAsync.valueOrNull ?? [];
    final trip = tripAsync.valueOrNull;

    final category = _marker.categoryId != null
        ? categories.where((c) => c.id == _marker.categoryId).firstOrNull
        : null;

    final dayCount = (trip?.startDate != null && trip?.endDate != null)
        ? trip!.endDate!.difference(trip.startDate!).inDays + 1
        : 0;

    final address =
        _detail('naver_address') ?? _marker.address ?? '정보 없음';
    final phone = _detail('naver_phone');

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(50)),
        boxShadow: [
          BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 10,
              offset: Offset(4, 0)),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 드래그 핸들
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 9),
                width: 82,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFECEBE7),
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 카테고리 + Day 배지
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: GestureDetector(
                onTap: () => _showEditSheet(context, categories, dayCount),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _InfoChip(
                      label: category?.name ?? '없음',
                      color: category != null
                          ? Color(int.parse(
                                  category.color.replaceFirst('#', '0xFF')))
                              .withValues(alpha: 0.5)
                          : const Color(0x808A847B),
                    ),
                    if (dayCount > 0) ...[
                      if (_marker.visitDays.isEmpty) ...[
                        const SizedBox(width: 6),
                        const _InfoChip(
                          label: '미정',
                          color: Color(0x808A847B),
                        ),
                      ] else
                        for (final d in _marker.visitDays) ...[
                          const SizedBox(width: 6),
                          _InfoChip(
                            label: 'Day$d',
                            color: const Color(0xCCFE8505),
                          ),
                        ],
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // 장소명 + 북마크/좋아요
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _editingName
                        ? TextField(
                            controller: _nameCtrl,
                            autofocus: true,
                            cursorColor: const Color(0xFFFE8505),
                            onSubmitted: (_) {
                              setState(() => _editingName = false);
                              _saveName();
                            },
                            style: const TextStyle(
                              fontFamily: 'Pretendard',
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF070707),
                            ),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          )
                        : GestureDetector(
                            onTap: () => setState(() => _editingName = true),
                            child: Text(
                              _nameCtrl.text,
                              style: const TextStyle(
                                fontFamily: 'Pretendard',
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF070707),
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _toggleBookmark,
                    child: Icon(
                      _saved ? Icons.bookmark : Icons.bookmark_border,
                      size: 25,
                      color: _saved
                          ? const Color(0xFFFE8505)
                          : const Color(0xFFD5D5D5),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () => setState(() => _isLiked = !_isLiked),
                    child: Icon(
                      _isLiked ? Icons.favorite : Icons.favorite_border,
                      size: 25,
                      color: _isLiked
                          ? const Color(0xFFFE8505)
                          : const Color(0xFFD5D5D5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 상세정보 (주소, 연락처)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Column(
                children: [
                  _InfoRow(icon: Icons.location_on_outlined, label: '주소', value: address),
                  if (phone != null) ...[
                    const SizedBox(height: 12),
                    _InfoRow(
                      icon: Icons.phone_outlined,
                      label: '연락처',
                      value: phone,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 출발지/목적지
            _RouteSection(
              allMarkers: widget.allMarkers,
              departureId: _departureId,
              destinationId: _destinationId,
              onDepartureChanged: (id) => setState(() => _departureId = id),
              onDestinationChanged: (id) => setState(() => _destinationId = id),
              onSwap: () => setState(() {
                final tmp = _departureId;
                _departureId = _destinationId;
                _destinationId = tmp ?? widget.marker.id;
              }),
            ),
            const SizedBox(height: 16),

            // 이동수단 탭
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                children: List.generate(4, (i) {
                  final active = _transportIndex == i;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: i < 3 ? 6 : 0),
                      child: GestureDetector(
                        onTap: () => setState(() => _transportIndex = i),
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: active
                                ? const Color(0xFFFE8505)
                                : const Color(0xFFF1F2F4),
                            borderRadius: BorderRadius.circular(17),
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
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _transportIcons[i],
                                size: 15,
                                color: active
                                    ? const Color(0xFFFDFDFD)
                                    : const Color(0xFF1F2125),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _transportLabels[i],
                                style: TextStyle(
                                  fontFamily: 'Pretendard',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: active
                                      ? const Color(0xFFFDFDFD)
                                      : const Color(0xFF1F2125),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 16),

            // 길찾기 버튼 (scope out — 표시만)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Container(
                height: 48,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xCC2A6FDB),
                  borderRadius: BorderRadius.circular(17),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x4D000000),
                      blurRadius: 4,
                      offset: Offset(1, 1),
                    )
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.directions, size: 20, color: Color(0xFFFDFDFD)),
                    SizedBox(width: 8),
                    Text(
                      '길찾기',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFFDFDFD),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// 상세정보 행 위젯
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: const Color(0xFFB2B2B2)),
        const SizedBox(width: 5),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFB2B2B2),
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                style: const TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1F2125),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// 출발지/목적지 섹션
class _RouteSection extends StatelessWidget {
  const _RouteSection({
    required this.allMarkers,
    required this.departureId,
    required this.destinationId,
    required this.onDepartureChanged,
    required this.onDestinationChanged,
    required this.onSwap,
  });

  final List<TripMarker> allMarkers;
  final String? departureId;
  final String destinationId;
  final ValueChanged<String?> onDepartureChanged;
  final ValueChanged<String> onDestinationChanged;
  final VoidCallback onSwap;

  String _name(String? id) {
    if (id == null) return '현위치';
    return allMarkers
            .where((m) => m.id == id)
            .map((m) => m.name)
            .firstOrNull ??
        '알 수 없음';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Stack(
        children: [
          Column(
            children: [
              _RouteTile(
                label: '출발지',
                name: _name(departureId),
                dotColor: const Color(0xFF2A6FDB),
                onTap: () => _showPicker(context, true),
              ),
              const SizedBox(height: 10),
              _RouteTile(
                label: '목적지',
                name: _name(destinationId),
                dotColor: const Color(0xFFFE8505),
                onTap: () => _showPicker(context, false),
              ),
            ],
          ),
          // 스위치 버튼: 두 타일 위에 겹쳐서 배치 (Figma: left=270 within 360px screen → right=0, w=75)
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: 75,
            child: Center(
              child: GestureDetector(
                onTap: onSwap,
                child: Container(
                  width: 35,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x29000000),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.swap_vert,
                    size: 20,
                    color: Color(0xFF1F2125),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPicker(BuildContext ctx, bool isDeparture) {
    showModalBottomSheet<void>(
      context: ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _RoutePickerSheet(
        allMarkers: allMarkers,
        isDeparture: isDeparture,
        onDepartureChanged: onDepartureChanged,
        onDestinationChanged: onDestinationChanged,
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 20,
      constraints: const BoxConstraints(minWidth: 50),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _RouteTile extends StatelessWidget {
  const _RouteTile({
    required this.label,
    required this.name,
    required this.dotColor,
    required this.onTap,
  });
  final String label;
  final String name;
  final Color dotColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 45,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F2F4),
          borderRadius: BorderRadius.circular(17),
        ),
        padding: const EdgeInsets.only(left: 15, right: 65, top: 5, bottom: 5),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFB2B2B2),
                    ),
                  ),
                  Text(
                    name,
                    style: const TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F2125),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down,
              size: 20,
              color: Color(0xFF7E7E7E),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoutePickerSheet extends StatelessWidget {
  const _RoutePickerSheet({
    required this.allMarkers,
    required this.isDeparture,
    required this.onDepartureChanged,
    required this.onDestinationChanged,
  });

  final List<TripMarker> allMarkers;
  final bool isDeparture;
  final ValueChanged<String?> onDepartureChanged;
  final ValueChanged<String> onDestinationChanged;

  @override
  Widget build(BuildContext context) {
    final Map<int?, List<TripMarker>> grouped = {};
    for (final m in allMarkers) {
      if (m.visitDays.isEmpty) {
        grouped.putIfAbsent(null, () => []).add(m);
      } else {
        for (final d in m.visitDays) {
          grouped.putIfAbsent(d, () => []).add(m);
        }
      }
    }
    final List<int> days = grouped.keys.whereType<int>().toList()..sort();

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.4,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF1F2F4),
          borderRadius: BorderRadius.vertical(top: Radius.circular(17)),
          boxShadow: [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 10,
              spreadRadius: 10,
              offset: Offset(4, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 8, bottom: 4),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF7E7E7E),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isDeparture)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(15, 5, 15, 5),
                        child: _PickerItem(
                          name: '현위치',
                          onTap: () {
                            Navigator.pop(context);
                            onDepartureChanged(null);
                          },
                        ),
                      ),
                    for (final day in days) ...[
                      Padding(
                        padding: const EdgeInsets.only(left: 15, top: 10, bottom: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Day ',
                              style: TextStyle(
                                fontFamily: 'Pretendard',
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF7E7E7E),
                              ),
                            ),
                            Text(
                              '$day',
                              style: const TextStyle(
                                fontFamily: 'Pretendard',
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFFFE8505),
                              ),
                            ),
                          ],
                        ),
                      ),
                      for (final m in grouped[day]!)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(15, 5, 15, 5),
                          child: _PickerItem(
                            name: m.name,
                            onTap: () {
                              Navigator.pop(context);
                              if (isDeparture) {
                                onDepartureChanged(m.id);
                              } else {
                                onDestinationChanged(m.id);
                              }
                            },
                          ),
                        ),
                    ],
                    if (grouped.containsKey(null)) ...[
                      const Padding(
                        padding: EdgeInsets.only(left: 15, top: 10, bottom: 2),
                        child: Text(
                          '미정',
                          style: TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF7E7E7E),
                          ),
                        ),
                      ),
                      for (final m in grouped[null]!)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(15, 5, 15, 5),
                          child: _PickerItem(
                            name: m.name,
                            onTap: () {
                              Navigator.pop(context);
                              if (isDeparture) {
                                onDepartureChanged(m.id);
                              } else {
                                onDestinationChanged(m.id);
                              }
                            },
                          ),
                        ),
                    ],
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PickerItem extends StatelessWidget {
  const _PickerItem({required this.name, required this.onTap});
  final String name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 45,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(17),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        alignment: Alignment.centerLeft,
        child: Text(
          name,
          style: const TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F2125),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _DeleteConfirmDialog extends StatelessWidget {
  const _DeleteConfirmDialog({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 300,
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(17),
        ),
        child: Column(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.delete_outline, size: 30, color: Color(0xFFEC2113)),
                  const SizedBox(height: 20),
                  const Text(
                    '삭제하시겠습니까?',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF070707),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    name,
                    style: const TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xCCEC2113),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context, false),
                    child: Container(
                      width: 120,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD5D5D5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        '취소',
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF070707),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  GestureDetector(
                    onTap: () => Navigator.pop(context, true),
                    child: Container(
                      width: 120,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xCCEC2113),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        '삭제',
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
