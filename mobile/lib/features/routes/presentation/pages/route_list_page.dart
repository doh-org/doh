import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/route_provider.dart';
import '../widgets/route_card.dart';

class RouteListPage extends ConsumerWidget {
  const RouteListPage({required this.tripId, super.key});
  final String tripId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routesAsync = ref.watch(routesProvider(tripId));

    return Scaffold(
      appBar: AppBar(title: const Text('경로')),
      body: routesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (routes) => routes.isEmpty
            ? const Center(child: Text('경로를 추가해보세요'))
            : ListView.builder(
                itemCount: routes.length,
                itemBuilder: (context, i) => RouteCard(route: routes[i]),
              ),
      ),
    );
  }
}
