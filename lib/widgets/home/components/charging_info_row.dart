import 'package:flutter/material.dart';
import '../../../models/charging_monitor_display_mode.dart';
import 'duration_display.dart';

/// 충전 정보 행 위젯
/// 충전 속도와 지속 시간을 한 줄에 표시하는 위젯
class ChargingInfoRow extends StatelessWidget {
  final int currentValue;
  final ChargingMonitorDisplayMode displayMode;
  final Duration? elapsedDuration;

  const ChargingInfoRow({
    super.key,
    required this.currentValue,
    required this.displayMode,
    this.elapsedDuration,
  });

  @override
  Widget build(BuildContext context) {
    final showDuration = displayMode == ChargingMonitorDisplayMode.currentWithDuration;
    final durationWidget = showDuration && elapsedDuration != null
        ? DurationDisplay(elapsedDuration: elapsedDuration)
        : null;
    
    // 지속 시간이 있으면 spaceBetween, 없으면 center
    final mainAxisAlignment = durationWidget != null 
        ? MainAxisAlignment.spaceBetween 
        : MainAxisAlignment.center;
    
    return Row(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // 충전 속도
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              currentValue.toString(),
              style: const TextStyle(
                color: Colors.green,
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                'mA',
                style: TextStyle(
                  color: Colors.green.withValues(alpha: 0.7),
                  fontSize: 20,
                ),
              ),
            ),
          ],
        ),
        
        // 지속 시간 (오른쪽 하단, 설정에 따라 조건부 렌더링)
        if (durationWidget != null) durationWidget,
      ],
    );
  }
}

