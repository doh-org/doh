import 'package:flutter/material.dart';

import '../../domain/entities/trip_member.dart';

class MemberTile extends StatelessWidget {
  const MemberTile({required this.member, super.key});
  final TripMember member;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const CircleAvatar(child: Icon(Icons.person)),
      title: Text(member.userId),
      trailing: Chip(
        label: Text(member.role == MemberRole.owner ? 'owner' : 'editor'),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
