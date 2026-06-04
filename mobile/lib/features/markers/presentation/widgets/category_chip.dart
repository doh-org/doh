import 'package:flutter/material.dart';

import '../../domain/entities/category.dart';

class CategoryChip extends StatelessWidget {
  const CategoryChip({
    required this.category,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final Category category;
  final bool selected;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    final color = Color(
      int.parse(category.color.replaceFirst('#', '0xFF')),
    );

    return FilterChip(
      label: Text(category.name),
      selected: selected,
      selectedColor: color.withOpacity(0.2),
      checkmarkColor: color,
      onSelected: onSelected,
    );
  }
}
