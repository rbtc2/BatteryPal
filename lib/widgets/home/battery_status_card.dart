import 'package:flutter/material.dart';
import '../../models/app_models.dart';

/// 배터리 상태 카드 위젯
/// 홈 탭에서 배터리 정보를 표시하는 카드 (원형 게이지 디자인)
class BatteryStatusCard extends StatelessWidget {
  final BatteryInfo? batteryInfo;

  const BatteryStatusCard({
    super.key,
    this.batteryInfo,
  });

  @override
  Widget build(BuildContext context) {
    final level = batteryInfo?.level ?? 0;
    final isCharging = batteryInfo?.isCharging ?? false;
    
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
                const Text('🔋', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Text(
                  '배터리 상태',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          
          // 메인 영역: 게이지 + 상태
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // 원형 게이지
                Expanded(
                  flex: 2,
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: _buildCircularGauge(context, level),
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // 상태 정보
                Expanded(
                  flex: 1,
                  child: _buildStatusInfo(context, isCharging),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 3개 메트릭 (온도/전압/건강도)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    context,
                    icon: '🌡️',
                    label: '온도',
                    value: batteryInfo?.formattedTemperature ?? '--°C',
                    color: _getTemperatureColor(batteryInfo?.temperature ?? 0),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    context,
                    icon: '⚡',
                    label: '전압',
                    value: batteryInfo?.formattedVoltage ?? '--mV',
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    context,
                    icon: '✅',
                    label: '건강도',
                    value: batteryInfo?.healthText ?? '알 수 없음',
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }
  
  Widget _buildCircularGauge(BuildContext context, double level) {
    final color = _getLevelColor(level);
    
    return Stack(
      alignment: Alignment.center,
      children: [
        // 배경 원
        SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: CircularProgressIndicator(
            value: level / 100,
            strokeWidth: 12,
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        // 중앙 텍스트
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${level.toInt()}%',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              '배터리',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildStatusInfo(BuildContext context, bool isCharging) {
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
          if (isCharging) ...[
            const SizedBox(height: 8),
            Text(
              '예상: 1시간 25분',
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildMetricCard(
    BuildContext context, {
    required String icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            maxLines: 1,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Color _getLevelColor(double level) {
    if (level > 50) return Colors.green;
    if (level > 20) return Colors.orange;
    return Colors.red;
  }
  
  Color _getTemperatureColor(double temp) {
    if (temp < 30) return Colors.blue;
    if (temp < 40) return Colors.green;
    if (temp < 45) return Colors.orange;
    return Colors.red;
  }
}
