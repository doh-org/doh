import 'package:flutter/material.dart';

class DayFilterBar extends StatelessWidget {
  const DayFilterBar({
    required this.selectedDay,
    required this.dayCount,
    required this.onDaySelected,
    super.key,
  });

  final int selectedDay;
  final int dayCount;
  final ValueChanged<int> onDaySelected;

  @override
  Widget build(BuildContext context) {
    final labels = ['미정', ...List.generate(dayCount, (i) => 'Day${i + 1}')];

    return SizedBox(
        height: 30,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: labels.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final selected = selectedDay == i;
            return GestureDetector(
              onTap: () => onDaySelected(i),
              child: Container(
                width: 60,
                height: 30,
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xCCFE8505)
                      : const Color(0xFFF1F2F4),
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
                  labels[i],
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: selected ? Colors.white : const Color(0xFF1F2125),
                  ),
                ),
              ),
            );
          },
        ),
      );
  }
}
