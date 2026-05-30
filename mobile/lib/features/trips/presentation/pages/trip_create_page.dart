import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/repositories/trip_repository_impl.dart';
import '../../domain/repositories/trip_repository.dart';

class TripCreatePage extends ConsumerStatefulWidget {
  const TripCreatePage({super.key});

  @override
  ConsumerState<TripCreatePage> createState() => _TripCreatePageState();
}

class _TripCreatePageState extends ConsumerState<TripCreatePage> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty) return;

    setState(() => _loading = true);
    try {
      final trip = await ref.read(tripRepositoryProvider).createTrip(
            title: _titleController.text.trim(),
            description: _descController.text.trim().isEmpty
                ? null
                : _descController.text.trim(),
          );
      if (mounted) context.go('/trips/${trip.id}/map');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('새 여행')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: '여행 이름'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(labelText: '설명 (선택)'),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('만들기'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
