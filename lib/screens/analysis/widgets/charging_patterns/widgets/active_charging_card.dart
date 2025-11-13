import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../../services/battery_service.dart';
import '../services/charging_session_service.dart';
import '../config/charging_session_config.dart';

/// 진행 중인 충전 세션을 표시하는 카드
/// 
/// 현재 진행 중인 충전 세션의 정보를 실시간으로 표시합니다.
class ActiveChargingCard extends StatefulWidget {
  final BatteryService batteryService;
  final ChargingSessionService sessionService;

  const ActiveChargingCard({
    super.key,
    required this.batteryService,
    required this.sessionService,
  });

  @override
  State<ActiveChargingCard> createState() => _ActiveChargingCardState();
}

class _ActiveChargingCardState extends State<ActiveChargingCard> {
  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    // 1초마다 UI 업데이트
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {});
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final batteryInfo = widget.batteryService.currentBatteryInfo;
    final sessionStartTime = widget.sessionService.sessionStartTime;
    
    if (batteryInfo == null || sessionStartTime == null) {
      return const SizedBox.shrink();
    }
    
    final elapsed = DateTime.now().difference(sessionStartTime);
    final minutes = elapsed.inMinutes;
    final seconds = elapsed.inSeconds % 60;
    
    // 유의미한 세션이 되기까지 남은 시간 계산 (ChargingSessionConfig에서 가져옴)
    final minSessionDuration = ChargingSessionConfig.minChargingDuration;
    
    final currentLevel = batteryInfo.level;
    final startBatteryInfo = widget.sessionService.startBatteryInfo;
    final startLevel = startBatteryInfo?.level ?? currentLevel;
    final batteryChange = currentLevel - startLevel;
    
    // 조건 만족 여부 확인
    final isDurationMet = elapsed >= minSessionDuration;
    final isCurrentMet = batteryInfo.chargingCurrent >= ChargingSessionConfig.minSignificantCurrentMa;
    final isBatteryChangeMet = batteryChange >= ChargingSessionConfig.minBatteryChangePercent;
    // 30초 대기는 충전 중에는 항상 대기 중
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.withValues(alpha: 0.15),
            Colors.blue.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더: 진행 중 배지
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _PulsingDot(color: Colors.blue),
                    const SizedBox(width: 6),
                    Text(
                      '진행 중',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                batteryInfo.chargingTypeText,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // 정보 그리드
          Row(
            children: [
              Expanded(
                child: _buildActiveInfoItem(
                  context,
                  icon: Icons.access_time,
                  label: '경과 시간',
                  value: '$minutes분 $seconds초',
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.blue.withValues(alpha: 0.2),
              ),
              Expanded(
                child: _buildActiveInfoItem(
                  context,
                  icon: Icons.battery_std,
                  label: '배터리',
                  value: '${currentLevel.toInt()}%',
                ),
              ),
            ],
          ),
          
          // 기록 조건 배지 (컴팩트 스타일)
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _buildConditionBadge(
                context,
                isMet: isDurationMet,
                label: '3분',
                icon: isDurationMet ? Icons.check_circle : Icons.radio_button_unchecked,
              ),
              _buildConditionBadge(
                context,
                isMet: isCurrentMet,
                label: '100mA',
                icon: isCurrentMet ? Icons.check_circle : Icons.radio_button_unchecked,
              ),
              _buildConditionBadge(
                context,
                isMet: isBatteryChangeMet,
                label: '1% ↗',
                icon: isBatteryChangeMet ? Icons.check_circle : Icons.radio_button_unchecked,
              ),
              _buildConditionBadge(
                context,
                isMet: false, // 충전 중에는 항상 대기 중
                label: '30초',
                icon: Icons.access_time,
                isWaiting: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActiveInfoItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
  
  /// 조건 배지 빌더
  Widget _buildConditionBadge(
    BuildContext context, {
    required bool isMet,
    required String label,
    required IconData icon,
    bool isWaiting = false,
  }) {
    final color = isMet 
        ? Colors.green 
        : (isWaiting ? Colors.orange : Colors.grey);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color[700],
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color[700],
            ),
          ),
        ],
      ),
    );
  }
}

/// 펄싱 애니메이션 도트 위젯
class _PulsingDot extends StatefulWidget {
  final Color color;

  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    
    _animation = Tween<double>(begin: 0.5, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: widget.color,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}

