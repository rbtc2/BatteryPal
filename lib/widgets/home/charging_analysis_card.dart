import 'package:flutter/material.dart';
import '../../models/app_models.dart';

/// 충전 분석 카드 위젯
/// 충전 중일 때 충전 속도 정보를 표시하는 카드
class ChargingAnalysisCard extends StatelessWidget {
  final BatteryInfo? batteryInfo;

  const ChargingAnalysisCard({
    super.key,
    this.batteryInfo,
  });

  @override
  Widget build(BuildContext context) {
    if (batteryInfo == null || !batteryInfo!.isCharging) {
      return const SizedBox.shrink();
    }
    
    final chargingCurrent = batteryInfo!.chargingCurrent.abs();
    final speedType = _getChargingSpeedType(chargingCurrent);
    
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text('🔌', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Text(
                  '충전 정보',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          
          // 충전 속도 정보
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    speedType.color.withValues(alpha: 0.2),
                    speedType.color.withValues(alpha: 0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: speedType.color.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(speedType.icon, color: speedType.color, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        speedType.label,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: speedType.color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${chargingCurrent}mA',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: speedType.color,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }
  
  _ChargingSpeedType _getChargingSpeedType(int current) {
    if (current >= 2000) {
      return _ChargingSpeedType(
        label: '고속 충전',
        icon: Icons.flash_on,
        color: Colors.red[400]!,
      );
    } else if (current >= 1000) {
      return _ChargingSpeedType(
        label: '일반 충전',
        icon: Icons.battery_charging_full,
        color: Colors.blue[400]!,
      );
    } else {
      return _ChargingSpeedType(
        label: '저속 충전',
        icon: Icons.battery_6_bar,
        color: Colors.green[400]!,
      );
    }
  }
}

class _ChargingSpeedType {
  final String label;
  final IconData icon;
  final Color color;
  
  _ChargingSpeedType({
    required this.label,
    required this.icon,
    required this.color,
  });
}
