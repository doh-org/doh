import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../markers/domain/entities/marker.dart';
import '../../../markers/presentation/pages/marker_detail_page.dart';
import '../../../markers/presentation/providers/marker_provider.dart';
import '../../../markers/presentation/widgets/marker_bottom_sheet.dart';
import '../providers/map_provider.dart';
import '../widgets/place_card.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({required this.tripId, super.key});
  final String tripId;

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<TripMarker> _filter(List<TripMarker> markers) {
    if (_query.isEmpty) return markers;
    final q = _query.toLowerCase();
    return markers
        .where(
          (m) =>
              m.name.toLowerCase().contains(q) ||
              (m.address?.toLowerCase().contains(q) ?? false),
        )
        .toList();
  }

  Color _parseCategoryColor(String? hex) {
    if (hex == null) return const Color(0x8095A5A6);
    try {
      return Color(int.parse(hex.replaceFirst('#', ''), radix: 16))
          .withAlpha(128);
    } catch (_) {
      return const Color(0x8095A5A6);
    }
  }

  IconData _categoryIcon(String? name) => switch (name) {
        '카페' => Icons.coffee,
        '음식' || '식당' => Icons.restaurant,
        '관광' => Icons.photo_camera_outlined,
        '숙소' => Icons.hotel_outlined,
        _ => Icons.place_outlined,
      };

  Future<void> _openAddMarkerSheet() async {
    final loc = ref.read(currentLocationProvider).valueOrNull;
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => MarkerBottomSheet(
        tripId: widget.tripId,
        latitude: loc?.latitude ?? 37.5665,
        longitude: loc?.longitude ?? 126.9780,
        initialName: _query.isEmpty ? null : _query,
      ),
    );
    if (mounted) ref.invalidate(markerEntitiesProvider(widget.tripId));
  }

  @override
  Widget build(BuildContext context) {
    final markersAsync = ref.watch(markerEntitiesProvider(widget.tripId));
    final categoriesAsync = ref.watch(categoriesProvider(widget.tripId));

    final allMarkers = markersAsync.valueOrNull ?? [];
    final categories = categoriesAsync.valueOrNull ?? [];
    final categoryMap = {for (final c in categories) c.id: c};
    final filtered = _filter(allMarkers);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Color(0xFF1F2125)),
        title: TextField(
          controller: _controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '지하철역, 카페, 식당 ....',
            hintStyle: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 14,
              color: Color(0xFF8A847B),
            ),
            border: InputBorder.none,
          ),
          onChanged: (v) => setState(() => _query = v),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFFE8505),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          '장소 직접 추가',
          style: TextStyle(
            fontFamily: 'Pretendard',
            color: Colors.white,
          ),
        ),
        onPressed: _openAddMarkerSheet,
      ),
      body: markersAsync.isLoading
          ? const Center(child: CircularProgressIndicator())
          : filtered.isEmpty
              ? const Center(
                  child: Text(
                    '검색 결과가 없습니다',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 14,
                      color: Color(0xFFB2B2B2),
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final m = filtered[i];
                    final cat =
                        m.categoryId != null ? categoryMap[m.categoryId] : null;
                    return PlaceCard(
                      name: m.name,
                      address: m.address,
                      category: cat?.name ?? '기타',
                      categoryColor: _parseCategoryColor(cat?.color),
                      categoryIcon: _categoryIcon(cat?.name),
                      likeCount: 0,
                      onTap: () async {
                        final deleted = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute<bool>(
                            builder: (_) => MarkerDetailPage(marker: m),
                          ),
                        );
                        if (deleted == true) {
                          ref.invalidate(
                            markerEntitiesProvider(widget.tripId),
                          );
                        }
                      },
                    );
                  },
                ),
    );
  }
}
