import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_cursor.dart';
import '../../data/repositories/marker_repository_impl.dart';
import '../../domain/entities/marker.dart';
import '../../domain/repositories/marker_repository.dart';
import '../providers/marker_provider.dart';
import 'category_chip.dart';

class MarkerBottomSheet extends ConsumerStatefulWidget {
  const MarkerBottomSheet({
    required this.tripId,
    required this.latitude,
    required this.longitude,
    this.initialName,
    super.key,
  });

  final String tripId;
  final double latitude;
  final double longitude;
  final String? initialName;

  @override
  ConsumerState<MarkerBottomSheet> createState() => _MarkerBottomSheetState();
}

class _MarkerBottomSheetState extends ConsumerState<MarkerBottomSheet> {
  late final TextEditingController _nameController;
  String? _selectedCategoryId;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_nameController.text.trim().isEmpty) return;

    setState(() => _loading = true);
    try {
      await ref.read(markerRepositoryProvider).createMarker(
            tripId: widget.tripId,
            name: _nameController.text.trim(),
            latitude: widget.latitude,
            longitude: widget.longitude,
            categoryId: _selectedCategoryId,
            source: MarkerSource.longpress,
          );
      ref.invalidate(markerEntitiesProvider(widget.tripId));
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider(widget.tripId));

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _nameController,
            cursorColor: appCursorColor(),
            decoration: const InputDecoration(labelText: '장소 이름'),
            autofocus: true,
          ),
          const SizedBox(height: 12),
          categoriesAsync.when(
            data: (categories) => Wrap(
              spacing: 8,
              children: categories
                  .map((c) => CategoryChip(
                        category: c,
                        selected: _selectedCategoryId == c.id,
                        onSelected: (_) =>
                            setState(() => _selectedCategoryId = c.id),
                      ))
                  .toList(),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('저장'),
            ),
          ),
        ],
      ),
    );
  }
}
