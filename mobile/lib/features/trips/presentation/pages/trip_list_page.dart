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
  bool _searchActive = false;
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _searchActive = !_searchActive;
      if (!_searchActive) {
        _query = '';
        _searchCtrl.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final tripsAsync = ref.watch(tripsProvider);
    final nickname = ref.watch(authNotifierProvider).valueOrNull?.nickname ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF1F2F4),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(nickname: nickname),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                children: [
                  if (_searchActive) ...[
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        autofocus: true,
                        onChanged: (v) => setState(() => _query = v),
                        style: const TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 10,
                          color: Color(0xFF070707),
                        ),
                        decoration: const InputDecoration(
                          border: UnderlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFF1F2125)),
                          ),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFF1F2125)),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFF1F2125)),
                          ),
                          hintText: '폴더 명을 입력하세요.',
                          hintStyle: TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 10,
                            color: Color(0xFFB2B2B2),
                          ),
                          isDense: true,
                          contentPadding: EdgeInsets.only(bottom: 8),
                        ),
                      ),
                    ),
                  ] else
                    const Spacer(),
                  GestureDetector(
                    onTap: _toggleSearch,
                    child: const Padding(
                      padding: EdgeInsets.fromLTRB(10, 20, 10, 20),
                      child: Icon(Icons.search, size: 20, color: AppColors.dark),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.push('/trips/create'),
                    child: const Padding(
                      padding: EdgeInsets.fromLTRB(10, 20, 10, 20),
                      child: Icon(Icons.add, size: 20, color: AppColors.folderOrange),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                color: Colors.white,
                child: tripsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('$e')),
                  data: (trips) {
                    final filtered = _query.isEmpty
                        ? trips
                        : trips.where((t) => t.title.contains(_query)).toList();
                    if (filtered.isEmpty) return const SizedBox.shrink();
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(15, 10, 15, 10),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 20),
                      itemBuilder: (_, i) => TripCard(
                        trip: filtered[i],
                        onTap: () =>
                            context.push('/trips/${filtered[i].id}/map'),
                        onEditTap: () =>
                            context.push('/trips/${filtered[i].id}/edit'),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 헤더: 123px, ⋯ top-right · 닉네임 bottom-left
class _Header extends StatelessWidget {
  const _Header({required this.nickname});
  final String nickname;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 123,
      child: Stack(
        children: [
          const Positioned(
            right: 15,
            top: 7,
            child: Icon(Icons.more_horiz, size: 20, color: AppColors.dark),
          ),
          // 닉네임: 헤더 하단 좌측 (pb-10, px-20)
          Positioned(
            left: 20,
            right: 20,
            bottom: 10,
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontFamily: 'Pretendard'),
                children: [
                  TextSpan(
                    text: nickname,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.folderOrange,
                    ),
                  ),
                  const TextSpan(
                    text: '님의\n',
                    // #3 님의 → Bold 18px
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.dark,
                    ),
                  ),
                  const TextSpan(
                    text: '여행',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
