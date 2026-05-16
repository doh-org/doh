import 'package:flutter/material.dart';

import '../../domain/entities/trip_route.dart';

class RouteCard extends StatelessWidget {
  const RouteCard({required this.route, super.key});
  final TripRoute route;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Icon(_modeIcon(route.transportMode)),
        title: Text(route.title),
        subtitle: route.description != null ? Text(route.description!) : null,
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }

  IconData _modeIcon(TransportMode mode) => switch (mode) {
        TransportMode.car => Icons.directions_car,
        TransportMode.foot => Icons.directions_walk,
        TransportMode.publictransit => Icons.directions_bus,
        TransportMode.bicycle => Icons.directions_bike,
      };
}
