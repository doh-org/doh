import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/trip_provider.dart';
import '../widgets/trip_card.dart';

class TripListPage extends ConsumerStatefulWidget {
  const TripListPage({super.key});

  @override
  ConsumerState<TripListPage> createState() => _TripListPageState();
}

class _TripListPageState extends ConsumerState<TripListPage> {
  String _query = '';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tripsAsync = ref.watch(tripsProvider);
    final user = ref.watch(authNotifierProvider).valueOrNull;
    final nickname = user?.nickname ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: SafeArea(
        child: tripsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
          data: (trips) {
            final totalDays = trips
                .where((t) => t.startDate != null && t.endDate != null)
                .fold<int>(
                  0,
                  (sum, t) =>
                      sum + t.endDate!.difference(t.startDate!).inDays + 1,
                );
            final filtered = _query.isEmpty
                ? trips
                : trips
                    .where((t) => t.title.contains(_query))
                    .toList();

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 헤더
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            RichText(
                              text: TextSpan(
                                style: const TextStyle(fontFamily: 'Pretendard'),
                                children: [
                                  TextSpan(
                                    text: nickname,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.folderOrange,
                                    ),
                                  ),
                                  const TextSpan(
                                    text: '님의\n',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: AppColors.dark,
                                    ),
                                  ),
                                  const TextSpan(
                                    text: '여행',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () => context.push('/trips/create'),
                              child: const Icon(
                                Icons.add,
                                size: 28,
                                color: AppColors.folderOrange,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // 검색바
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(17),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x1A000000),
                                offset: Offset(1, 1),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchCtrl,
                            onChanged: (v) => setState(() => _query = v),
                            style: const TextStyle(
                              fontFamily: 'Pretendard',
                              fontSize: 14,
                            ),
                            decoration: const InputDecoration(
                              prefixIcon: Icon(
                                Icons.search,
                                color: AppColors.gray,
                                size: 20,
                              ),
                              hintText: '서울, 제주...',
                              hintStyle: TextStyle(
                                fontFamily: 'Pretendard',
                                fontSize: 14,
                                color: AppColors.gray,
                              ),
                              border: InputBorder.none,
                              contentPadding:
                                  EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // 통계바
                        Row(
                          children: [
                            _StatItem(
                              value: '${trips.length}',
                              label: '여행',
                            ),
                            const SizedBox(width: 24),
                            const _StatItem(value: '-', label: '장소'),
                            const SizedBox(width: 24),
                            _StatItem(value: '$totalDays', label: '일'),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                if (filtered.isEmpty)
                  const SliverFillRemaining(child: SizedBox.shrink())
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    sliver: SliverList.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, i) => TripCard(
                        trip: filtered[i],
                        onTap: () =>
                            context.push('/trips/${filtered[i].id}/map'),
                        onEditTap: () =>
                            context.push('/trips/${filtered[i].id}/edit'),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.black,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: AppColors.gray,
          ),
        ),
      ],
    );
  }
}
