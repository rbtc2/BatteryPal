import 'package:flutter/material.dart';
import '../controllers/date_selector_controller.dart';

/// 날짜 선택 탭 위젯
/// 
/// 오늘, 어제, 2일 전 탭과 날짜 선택 버튼을 제공합니다.
class DateSelectorTabs extends StatelessWidget {
  final DateSelectorController controller;

  const DateSelectorTabs({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildTabButton(context, '오늘'),
          const SizedBox(width: 8),
          _buildTabButton(context, '어제'),
          const SizedBox(width: 8),
          _buildTabButton(context, '2일 전'),
          const Spacer(),
          InkWell(
            onTap: () async {
              await controller.showDatePickerDialog(context);
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_today, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    controller.selectedDate != null
                        ? '${controller.selectedDate!.year}.${controller.selectedDate!.month.toString().padLeft(2, '0')}.${controller.selectedDate!.day.toString().padLeft(2, '0')}'
                        : DateTime.now().toString().split(' ')[0].replaceAll('-', '.'),
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(BuildContext context, String label) {
    final tab = DateSelectorController.tabFromString(label);
    final isSelected = controller.selectedTab == tab;
    return InkWell(
      onTap: () {
        controller.selectTab(tab);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? Theme.of(context).colorScheme.primaryContainer
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

