import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/trip_provider.dart';
import '../widgets/trip_card.dart';

class TripListPage extends ConsumerWidget {
  const TripListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripsAsync = ref.watch(tripsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('내 여행')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/trips/create'),
        child: const Icon(Icons.add),
      ),
      body: tripsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (trips) => trips.isEmpty
            ? const Center(child: Text('여행을 추가해보세요'))
            : ListView.builder(
                itemCount: trips.length,
                itemBuilder: (context, i) => TripCard(
                  trip: trips[i],
                  onTap: () => context.push('/trips/${trips[i].id}/map'),
                ),
              ),
      ),
    );
  }
}
