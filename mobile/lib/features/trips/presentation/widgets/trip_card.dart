import 'package:flutter/material.dart';

import '../../domain/entities/trip.dart';

class TripCard extends StatelessWidget {
  const TripCard({required this.trip, required this.onTap, super.key});
  final Trip trip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(trip.title),
        subtitle: trip.description != null ? Text(trip.description!) : null,
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
