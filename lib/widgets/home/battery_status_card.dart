import 'package:flutter/material.dart';
import '../../models/app_models.dart';
import '../common/common_widgets.dart';
import '../../utils/app_utils.dart';

/// 배터리 상태 카드 위젯
/// 홈 탭에서 배터리 정보를 표시하는 카드
class BatteryStatusCard extends StatelessWidget {
  final BatteryInfo? batteryInfo;
  final VoidCallback? onTap;

  const BatteryStatusCard({
    super.key,
    this.batteryInfo,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    debugPrint('BatteryStatusCard: 빌드 - batteryInfo: ${batteryInfo?.toString()}');
    
    return CustomCard(
      elevation: 4,
      padding: const EdgeInsets.all(20),
      onTap: onTap,
      child: Column(
        children: [
          // 배터리 레벨 표시
          _buildBatteryLevelSection(context),
          const SizedBox(height: 16),
          
          // 배터리 정보 (3개 항목)
          _buildBatteryInfoSection(context),
          
          // 충전 정보 섹션
          if (batteryInfo != null && batteryInfo!.isCharging) ...[
            const SizedBox(height: 16),
            _buildChargingInfoSection(context),
          ],
          
          // 마지막 업데이트 시간
          if (batteryInfo != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: _buildLastUpdateSection(context),
            ),
        ],
      ),
    );
  }

  /// 배터리 레벨 섹션 빌드
  Widget _buildBatteryLevelSection(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '현재 배터리',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            Text(
              batteryInfo?.formattedLevel ?? '--.-%',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: batteryInfo?.levelColor ?? Colors.grey,
              ),
            ),
          ],
        ),
        // 배터리 아이콘
        Icon(
          batteryInfo?.levelIcon ?? Icons.battery_unknown,
          size: 48,
          color: batteryInfo?.levelColor ?? Colors.grey,
        ),
      ],
    );
  }

  /// 배터리 정보 섹션 빌드 (온도, 전압, 건강도)
  Widget _buildBatteryInfoSection(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        InfoItem(
          label: '온도',
          value: batteryInfo?.formattedTemperature ?? '--.-°C',
          valueColor: batteryInfo?.temperatureColor,
        ),
        InfoItem(
          label: '전압',
          value: batteryInfo?.formattedVoltage ?? '--mV',
          valueColor: batteryInfo?.voltageColor,
        ),
        InfoItem(
          label: '건강도',
          value: batteryInfo?.healthText ?? '알 수 없음',
          valueColor: batteryInfo?.healthColor,
        ),
      ],
    );
  }

  /// 충전 정보 섹션 빌드
  Widget _buildChargingInfoSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.bolt,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              batteryInfo!.chargingStatusText,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 마지막 업데이트 시간 섹션 빌드
  Widget _buildLastUpdateSection(BuildContext context) {
    return Text(
      '마지막 업데이트: ${TimeUtils.formatRelativeTime(batteryInfo!.timestamp)}',
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
        fontSize: 12,
      ),
    );
  }
}
