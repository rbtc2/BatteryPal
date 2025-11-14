import 'package:flutter/material.dart';
import '../../../services/last_charging_info_service.dart';
import '../utils/charging_format_utils.dart';
import 'charging_info_card.dart';

/// 마지막 충전 정보 뷰
/// 충전이 끝난 후 마지막 충전 정보를 표시하는 위젯
class LastChargingInfoView extends StatelessWidget {
  final LastChargingInfo? lastChargingInfo;
  final LastChargingInfoService lastChargingInfoService;

  const LastChargingInfoView({
    super.key,
    required this.lastChargingInfo,
    required this.lastChargingInfoService,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 제목: 마지막 충전 정보
          Text(
            '마지막 충전 정보',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          
          const SizedBox(height: 12),
          
          // 정보 그리드 (2x2 레이아웃)
          Row(
            children: [
              Expanded(
                child: ChargingInfoCard(
                  icon: '⏱️',
                  text: ChargingFormatUtils.formatChargingTime(lastChargingInfo?.endTime),
                  subtitle: '충전 시간',
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ChargingInfoCard(
                  icon: '⚡',
                  text: lastChargingInfo != null
                      ? lastChargingInfoService.getSpeedText(lastChargingInfo!.speed)
                      : '--',
                  subtitle: lastChargingInfo != null
                      ? '${(lastChargingInfo!.avgCurrent / 1000).toStringAsFixed(1)}A'
                      : '--',
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          Row(
            children: [
              Expanded(
                child: ChargingInfoCard(
                  icon: '🎯',
                  text: lastChargingInfo != null
                      ? '${lastChargingInfo!.batteryLevel.toInt()}%'
                      : '--',
                  subtitle: '충전 레벨',
                  color: Colors.purple,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ChargingInfoCard(
                  icon: '💚',
                  text: '건강한 충전!',
                  subtitle: '상태 양호',
                  color: Colors.green,
                  isHighlight: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

