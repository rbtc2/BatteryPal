import 'package:flutter/material.dart';
import '../../../models/models.dart';

/// 충전 그래프 테마 선택 다이얼로그
class ChargingGraphThemeDialog extends StatefulWidget {
  final ChargingGraphTheme initialTheme;
  final ValueChanged<ChargingGraphTheme> onThemeSelected;

  const ChargingGraphThemeDialog({
    super.key,
    required this.initialTheme,
    required this.onThemeSelected,
  });

  static void show(
    BuildContext context,
    ChargingGraphTheme initialTheme,
    ValueChanged<ChargingGraphTheme> onThemeSelected,
  ) {
    showDialog(
      context: context,
      builder: (context) => ChargingGraphThemeDialog(
        initialTheme: initialTheme,
        onThemeSelected: onThemeSelected,
      ),
    );
  }

  @override
  State<ChargingGraphThemeDialog> createState() => _ChargingGraphThemeDialogState();
}

class _ChargingGraphThemeDialogState extends State<ChargingGraphThemeDialog> {
  late ChargingGraphTheme _selectedTheme;

  @override
  void initState() {
    super.initState();
    _selectedTheme = widget.initialTheme;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.palette),
          SizedBox(width: 8),
          Text('충전 그래프 테마'),
        ],
      ),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '테마 선택',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              // 모든 테마 옵션
              ...ChargingGraphTheme.values.map((theme) {
                final isSelected = _selectedTheme == theme;
                
                return Column(
                  children: [
                    ListTile(
                      title: Text(theme.displayName),
                      subtitle: Text(theme.description),
                      leading: Icon(
                        isSelected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                      contentPadding: EdgeInsets.zero,
                      onTap: () {
                        setState(() {
                          _selectedTheme = theme;
                        });
                      },
                    ),
                    if (theme != ChargingGraphTheme.values.last)
                      const SizedBox(height: 8),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        TextButton(
          onPressed: () {
            widget.onThemeSelected(_selectedTheme);
            Navigator.of(context).pop();
          },
          child: const Text('확인'),
        ),
      ],
    );
  }
}

