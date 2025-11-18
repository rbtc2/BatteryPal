import 'package:flutter/material.dart';
import '../../../models/models.dart';

/// 충전 모니터 표시 방식 선택 다이얼로그
class ChargingMonitorDisplayDialog extends StatefulWidget {
  final ChargingMonitorDisplayMode initialMode;
  final ValueChanged<ChargingMonitorDisplayMode> onModeSelected;

  const ChargingMonitorDisplayDialog({
    super.key,
    required this.initialMode,
    required this.onModeSelected,
  });

  static void show(
    BuildContext context,
    ChargingMonitorDisplayMode initialMode,
    ValueChanged<ChargingMonitorDisplayMode> onModeSelected,
  ) {
    showDialog(
      context: context,
      builder: (context) => ChargingMonitorDisplayDialog(
        initialMode: initialMode,
        onModeSelected: onModeSelected,
      ),
    );
  }

  @override
  State<ChargingMonitorDisplayDialog> createState() => _ChargingMonitorDisplayDialogState();
}

class _ChargingMonitorDisplayDialogState extends State<ChargingMonitorDisplayDialog> {
  late ChargingMonitorDisplayMode _selectedMode;

  @override
  void initState() {
    super.initState();
    _selectedMode = widget.initialMode;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.monitor_heart),
          SizedBox(width: 8),
          Text('충전 모니터 표시 방식'),
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
                '표시 방식 선택',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              // 충전 속도만 표시
              ListTile(
                title: const Text('충전 속도만 표시'),
                subtitle: const Text('현재 충전 전류만 실시간으로 표시'),
                leading: Icon(
                  _selectedMode == ChargingMonitorDisplayMode.currentOnly
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: _selectedMode == ChargingMonitorDisplayMode.currentOnly
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                contentPadding: EdgeInsets.zero,
                onTap: () {
                  setState(() {
                    _selectedMode = ChargingMonitorDisplayMode.currentOnly;
                  });
                },
              ),
              const SizedBox(height: 8),
              // 충전 속도 + 지속 시간 표시
              ListTile(
                title: const Text('충전 속도 + 지속 시간 표시'),
                subtitle: const Text('충전 속도와 함께 이 세션의 충전 지속 시간을 표시'),
                leading: Icon(
                  _selectedMode == ChargingMonitorDisplayMode.currentWithDuration
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: _selectedMode == ChargingMonitorDisplayMode.currentWithDuration
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                contentPadding: EdgeInsets.zero,
                onTap: () {
                  setState(() {
                    _selectedMode = ChargingMonitorDisplayMode.currentWithDuration;
                  });
                },
              ),
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
            widget.onModeSelected(_selectedMode);
            Navigator.of(context).pop();
          },
          child: const Text('확인'),
        ),
      ],
    );
  }
}

