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
    // 초기 테마가 스켈레톤 테마인 경우, 구현된 테마로 변경
    if (_isThemeImplemented(widget.initialTheme)) {
      _selectedTheme = widget.initialTheme;
    } else {
      // 기본값으로 ECG 테마 사용
      _selectedTheme = ChargingGraphTheme.ecg;
    }
  }

  /// 테마가 구현 완료되었는지 확인
  bool _isThemeImplemented(ChargingGraphTheme theme) {
    switch (theme) {
      case ChargingGraphTheme.ecg:
      case ChargingGraphTheme.spectrum:
      case ChargingGraphTheme.wave:
      case ChargingGraphTheme.particle:
      case ChargingGraphTheme.dna:
        return true;
    }
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
                final isImplemented = _isThemeImplemented(theme);
                
                return Column(
                  children: [
                    ListTile(
                      title: Text(
                        theme.displayName,
                        style: TextStyle(
                          color: isImplemented
                              ? null
                              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                      subtitle: Text(
                        isImplemented
                            ? theme.description
                            : '${theme.description} (준비 중)',
                        style: TextStyle(
                          color: isImplemented
                              ? null
                              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                      leading: Icon(
                        isSelected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : isImplemented
                                ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)
                                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                      ),
                      contentPadding: EdgeInsets.zero,
                      enabled: isImplemented,
                      onTap: isImplemented
                          ? () {
                              setState(() {
                                _selectedTheme = theme;
                              });
                            }
                          : null,
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
          onPressed: _isThemeImplemented(_selectedTheme)
              ? () {
                  widget.onThemeSelected(_selectedTheme);
                  Navigator.of(context).pop();
                }
              : null,
          child: const Text('확인'),
        ),
      ],
    );
  }
}

