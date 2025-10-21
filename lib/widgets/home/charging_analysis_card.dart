import 'package:flutter/material.dart';
import '../../models/app_models.dart';
import '../../services/charging_analysis_service.dart';
import '../common/common_widgets.dart';

/// 충전 분석 카드 위젯
/// 충전 중일 때 충전 속도와 최적화 팁을 표시하는 카드
class ChargingAnalysisCard extends StatelessWidget {
  final BatteryInfo? batteryInfo;

  const ChargingAnalysisCard({
    super.key,
    this.batteryInfo,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      elevation: 4,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더: 충전 속도 분석
          _buildChargingHeader(context),
          const SizedBox(height: 12),
          
          // 충전 속도 인디케이터 (큰 시각적 요소)
          _buildChargingSpeedIndicator(context),
          const SizedBox(height: 12),
          
          // 충전 최적화 팁 (접을 수 있는 형태)
          _buildChargingOptimizationTips(context),
        ],
      ),
    );
  }

  /// 충전 분석 헤더 빌드
  Widget _buildChargingHeader(BuildContext context) {
    return Row(
      children: [
        // 미니멀 아이콘 컨테이너
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            Icons.flash_on_outlined,
            color: Theme.of(context).colorScheme.primary,
            size: 16,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '충전 분석',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
        const Spacer(),
        // 개선된 실시간 표시 (충전 전류 변화 감지)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 실시간 애니메이션 도트
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 1000),
                tween: Tween(begin: 0.0, end: 1.0),
                builder: (context, value, child) {
                  return Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: value),
                      shape: BoxShape.circle,
                    ),
                  );
                },
                onEnd: () {
                  // 애니메이션 반복
                },
              ),
              const SizedBox(width: 4),
              Text(
                '실시간 모니터링',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 충전 속도 인디케이터 빌드
  Widget _buildChargingSpeedIndicator(BuildContext context) {
    final chargingSpeed = _getRealChargingSpeed();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: chargingSpeed.color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // 미니멀 아이콘
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: chargingSpeed.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              chargingSpeed.icon,
              color: chargingSpeed.color,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          
          // 텍스트 정보 (개선된 타이포그래피)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  chargingSpeed.label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: chargingSpeed.color,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  chargingSpeed.description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 8),
                // 개선된 충전 진행률 바
                _buildChargingProgressBar(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 충전 진행률 바 빌드
  Widget _buildChargingProgressBar(BuildContext context) {
    final currentLevel = batteryInfo?.level ?? 0.0;
    final progress = currentLevel / 100.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '진행률',
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${currentLevel.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          height: 3,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 충전 최적화 팁 빌드
  Widget _buildChargingOptimizationTips(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        childrenPadding: const EdgeInsets.only(bottom: 8),
        title: Row(
          children: [
            Icon(
              Icons.lightbulb_outline,
              color: Theme.of(context).colorScheme.secondary,
              size: 16,
            ),
            const SizedBox(width: 6),
            const Text(
              '최적화 팁',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
        children: [
          ..._getRealChargingSpeed().tips.map((tip) => _buildTipItem(context, tip)),
        ],
      ),
    );
  }

  /// 팁 아이템 위젯 빌드
  Widget _buildTipItem(BuildContext context, String tip) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 3,
            height: 3,
            margin: const EdgeInsets.only(top: 6, right: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              tip,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                height: 1.3,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 실제 충전 전류값을 사용한 충전 속도 정보
  ChargingSpeedInfo _getRealChargingSpeed() {
    return ChargingAnalysisService.getChargingSpeedInfo(batteryInfo);
  }
}
