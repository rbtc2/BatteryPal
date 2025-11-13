import 'package:flutter/material.dart';

/// 배터리 상태 정보 위젯
/// 충전/방전 상태를 표시하는 작은 카드
class BatteryStatusInfo extends StatelessWidget {
  final bool isCharging;

  const BatteryStatusInfo({
    super.key,
    required this.isCharging,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCharging 
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCharging 
              ? Colors.green.withValues(alpha: 0.3)
              : Colors.grey.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '상태',
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                isCharging ? Icons.bolt : Icons.battery_std,
                size: 20,
                color: isCharging ? Colors.green : Colors.grey,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  isCharging ? '충전 중' : '방전 중',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isCharging ? Colors.green : Colors.grey,
                  ),
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

