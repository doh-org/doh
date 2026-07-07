import 'package:flutter/material.dart';

import '../../../markers/domain/entities/marker.dart';

/// 출발지/목적지 교환. null(현위치)도 값 그대로 반대편에 넘긴다.
/// (이전엔 출발지가 현위치일 때 목적지에 마커 id를 되채워 넣는 버그가 있었다)
({String? departureId, String? destinationId}) swapRoutePoints({
  required String? departureId,
  required String? destinationId,
}) =>
    (departureId: destinationId, destinationId: departureId);

// 출발지/목적지 섹션. 타일 탭 → Day별 마커 picker 시트.
class RouteSection extends StatelessWidget {
  const RouteSection({
    required this.allMarkers,
    required this.departureId,
    required this.destinationId,
    required this.onDepartureChanged,
    required this.onDestinationChanged,
    required this.onSwap,
    super.key,
  });

  final List<TripMarker> allMarkers;
  final String? departureId; // null = 현위치
  final String? destinationId; // null = 현위치 (스왑으로만 도달)
  final ValueChanged<String?> onDepartureChanged;
  final ValueChanged<String?> onDestinationChanged;
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
        height: 48,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F2F4),
          borderRadius: BorderRadius.circular(17),
        ),
        padding: const EdgeInsets.only(left: 15, right: 65, top: 4, bottom: 4),
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
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFB2B2B2),
                    ),
                  ),
                  Text(
                    name,
                    style: const TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 15,
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

// Day별로 묶어 보여주는 출발지/목적지 선택 시트
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
  final ValueChanged<String?> onDestinationChanged;

  @override
  Widget build(BuildContext context) {
    // Day → 마커 목록. 방문일 없는 마커는 null 키(미정)로 묶는다.
    final Map<int?, List<TripMarker>> grouped = {};
    for (final TripMarker m in allMarkers) {
      if (m.visitDays.isEmpty) {
        grouped.putIfAbsent(null, () => []).add(m);
      } else {
        for (final int d in m.visitDays) {
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
                    for (final int day in days) ...[
                      Padding(
                        padding:
                            const EdgeInsets.only(left: 15, top: 10, bottom: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Day ',
                              style: TextStyle(
                                fontFamily: 'Pretendard',
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF7E7E7E),
                              ),
                            ),
                            Text(
                              '$day',
                              style: const TextStyle(
                                fontFamily: 'Pretendard',
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFFFE8505),
                              ),
                            ),
                          ],
                        ),
                      ),
                      for (final TripMarker m in grouped[day]!)
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
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF7E7E7E),
                          ),
                        ),
                      ),
                      for (final TripMarker m in grouped[null]!)
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
            fontSize: 15,
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
