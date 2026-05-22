import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/marker_repository_impl.dart';
import '../../domain/entities/marker.dart';
import '../../domain/repositories/marker_repository.dart';

class MarkerDetailPage extends ConsumerWidget {
  const MarkerDetailPage({required this.marker, super.key});
  final TripMarker marker;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(marker.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              await ref
                  .read(markerRepositoryProvider)
                  .deleteMarker(marker.id);
              if (context.mounted) Navigator.pop(context, true);
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (marker.address != null) ...[
            ListTile(
              leading: const Icon(Icons.location_on_outlined),
              title: Text(marker.address!),
              contentPadding: EdgeInsets.zero,
            ),
          ],
          if (marker.memo != null) ...[
            ListTile(
              leading: const Icon(Icons.notes),
              title: Text(marker.memo!),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ],
      ),
    );
  }
}
