import 'package:flutter/material.dart';
import '../../../../../services/battery_service.dart';
import '../services/charging_session_service.dart';
import '../config/charging_session_config.dart';

/// 진행 중인 충전 세션을 표시하는 카드
/// 
/// 현재 진행 중인 충전 세션의 정보를 실시간으로 표시합니다.
class ActiveChargingCard extends StatelessWidget {
  final BatteryService batteryService;
  final ChargingSessionService sessionService;

  const ActiveChargingCard({
    super.key,
    required this.batteryService,
    required this.sessionService,
  });

  @override
  Widget build(BuildContext context) {
    final batteryInfo = batteryService.currentBatteryInfo;
    final sessionStartTime = sessionService.sessionStartTime;
    
    if (batteryInfo == null || sessionStartTime == null) {
      return const SizedBox.shrink();
    }
    
    final elapsed = DateTime.now().difference(sessionStartTime);
    final minutes = elapsed.inMinutes;
    final seconds = elapsed.inSeconds % 60;
    
    // 유의미한 세션이 되기까지 남은 시간 계산 (ChargingSessionConfig에서 가져옴)
    final minSessionDuration = ChargingSessionConfig.minChargingDuration;
    final remainingTime = minSessionDuration - elapsed;
    final remainingMinutes = remainingTime.inMinutes.clamp(0, 999);
    final remainingSeconds = remainingTime.inSeconds.clamp(0, 59) % 60;
    
    final currentLevel = batteryInfo.level;
    
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
          
          // 유의미한 세션이 되기까지 남은 시간
          if (remainingTime.inSeconds > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Colors.blue[700],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      remainingMinutes > 0
                          ? '$remainingMinutes분 $remainingSeconds초 후 기록됩니다'
                          : '$remainingSeconds초 후 기록됩니다',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 16,
                    color: Colors.green[700],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '충전 세션이 기록되었습니다',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
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

