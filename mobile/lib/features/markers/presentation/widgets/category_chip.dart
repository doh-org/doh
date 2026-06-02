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
    final Color base;
    try {
      base = Color(int.parse(category.color.replaceFirst('#', '0xFF')));
    } catch (_) {
      return const SizedBox.shrink();
    }

    final bgColor = selected ? base : base.withAlpha(0x80);
    final textColor = selected ? Colors.white : const Color(0xFF1F2125);

    return GestureDetector(
      onTap: () => onSelected(!selected),
      child: Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(25),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Color(0x4D000000),
                    blurRadius: 4,
                    offset: Offset(1, 1),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          category.name,
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
      ),
    );
  }
}
