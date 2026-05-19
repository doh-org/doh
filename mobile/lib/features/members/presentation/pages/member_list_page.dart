import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/member_repository_impl.dart';
import '../providers/member_provider.dart';
import '../widgets/member_tile.dart';

class MemberListPage extends ConsumerWidget {
  const MemberListPage({required this.tripId, super.key});
  final String tripId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(membersProvider(tripId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('멤버'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_outlined),
            onPressed: () => _showInviteDialog(context, ref),
          ),
        ],
      ),
      body: membersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (members) => ListView.builder(
          itemCount: members.length,
          itemBuilder: (context, i) => MemberTile(member: members[i]),
        ),
      ),
    );
  }

  void _showInviteDialog(BuildContext context, WidgetRef ref) {
    final emailController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('멤버 초대'),
        content: TextField(
          controller: emailController,
          decoration: const InputDecoration(labelText: '이메일'),
          keyboardType: TextInputType.emailAddress,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () async {
              await ref
                  .read(memberRepositoryProvider)
                  .inviteMember(tripId, emailController.text.trim());
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('초대'),
          ),
        ],
      ),
    );
  }
}
