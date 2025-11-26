import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../../services/battery_service.dart';
import '../../../../../models/models.dart';
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
  StreamSubscription<BatteryInfo>? _batteryInfoSubscription;
  bool _previousIsCharging = false;

  @override
  void initState() {
    super.initState();
    
    // BatteryService 스트림 구독하여 충전 상태 변화 즉시 감지
    _batteryInfoSubscription = widget.batteryService.batteryInfoStream.listen(
      (batteryInfo) {
        if (!mounted) return;
        
        final isCharging = batteryInfo.isCharging;
        
        // 충전 상태가 변경되면 즉시 UI 업데이트 (카드 표시/숨김)
        if (_previousIsCharging != isCharging) {
          _previousIsCharging = isCharging;
          setState(() {});
        }
      },
      onError: (error) {
        debugPrint('ActiveChargingCard: 배터리 정보 스트림 오류 - $error');
      },
    );
    
    // 초기 충전 상태 저장
    final currentInfo = widget.batteryService.currentBatteryInfo;
    if (currentInfo != null) {
      _previousIsCharging = currentInfo.isCharging;
    }
    
    // 1초마다 UI 업데이트 (경과 시간 등 실시간 정보 업데이트용)
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
    _batteryInfoSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final batteryInfo = widget.batteryService.currentBatteryInfo;
    final sessionStartTime = widget.sessionService.sessionStartTime;
    final isSessionActive = widget.sessionService.isSessionActive;
    
    // 카드 표시 조건:
    // 1. 배터리 정보가 있어야 함
    // 2. 세션 시작 시간이 있어야 함
    // 3. 세션이 활성화되어 있어야 함 (isSessionActive == true)
    // 4. 실제로 충전 중이어야 함 (batteryInfo.isCharging == true)
    // 
    // 충전기가 제거되면 즉시 카드가 사라지도록 실제 충전 상태도 확인
    if (batteryInfo == null || 
        sessionStartTime == null || 
        !isSessionActive || 
        !batteryInfo.isCharging) {
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
    // 종료 대기 시간(ChargingSessionConfig.sessionEndWaitSeconds)은 충전 중에는 항상 대기 중
    
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
          Row(
            children: [
              Expanded(
                child: Wrap(
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
                  ],
                ),
              ),
              // 정보 아이콘
              GestureDetector(
                onTap: () => _showRecordingConditionsDialog(context),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Colors.blue[700],
                  ),
                ),
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
  }) {
    final color = isMet ? Colors.green : Colors.grey;
    
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
  
  /// 기록 조건 안내 다이얼로그 표시
  void _showRecordingConditionsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.info_outline,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              '기록 조건 안내',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '충전 세션이 기록되려면 다음 조건을 모두 만족해야 합니다:',
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 16),
            _buildConditionItem(
              context,
              icon: Icons.access_time,
              label: '3분 이상 충전',
              color: Colors.blue,
            ),
            const SizedBox(height: 12),
            _buildConditionItem(
              context,
              icon: Icons.speed,
              label: '평균 전류 100mA 이상',
              color: Colors.blue,
            ),
            const SizedBox(height: 12),
            _buildConditionItem(
              context,
              icon: Icons.trending_up,
              label: '배터리 레벨 1% 이상 상승',
              color: Colors.blue,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.orange.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: Colors.orange[700],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '위 조건을 모두 충족한 후, 충전기가 떨어진 상태로 ${ChargingSessionConfig.sessionEndWaitSeconds}초가 지나면 세션이 기록됩니다.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: Colors.orange[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              '확인',
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// 조건 항목 빌더
  Widget _buildConditionItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: color,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
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

