import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/battery_service.dart';
import '../../services/last_charging_info_service.dart';
import '../../services/settings_service.dart';
import '../../models/models.dart';
import '../../screens/analysis/widgets/charging_patterns/services/charging_session_service.dart';

/// 실시간 충전 모니터 위젯
/// 충전 중일 때 심전도 그래프처럼 충전 속도를 실시간으로 표시
class RealtimeChargingMonitor extends StatefulWidget {
  final BatteryInfo? batteryInfo;

  const RealtimeChargingMonitor({
    super.key,
    this.batteryInfo,
  });

  @override
  State<RealtimeChargingMonitor> createState() => _RealtimeChargingMonitorState();
}

class _RealtimeChargingMonitorState extends State<RealtimeChargingMonitor> {
  final List<double> _dataPoints = [];
  final int _maxDataPoints = 50; // 50개 포인트 유지
  Timer? _updateTimer; // 충전 속도 업데이트 타이머 (200ms)
  Timer? _durationUpdateTimer; // 지속 시간 업데이트 타이머 (1초)
  final BatteryService _batteryService = BatteryService();
  final LastChargingInfoService _lastChargingInfoService = LastChargingInfoService();
  final ChargingSessionService _sessionService = ChargingSessionService();
  final SettingsService _settingsService = SettingsService();
  
  // 마지막 충전 정보
  LastChargingInfo? _lastChargingInfo;
  
  // 현재 충전 세션 시작 시간
  DateTime? _sessionStartTime;

  @override
  void initState() {
    super.initState();
    // 충전 중일 때만 모니터링 시작
    if (widget.batteryInfo?.isCharging == true) {
      _updateSessionStartTime();
      _startRealTimeUpdate();
      
      // 앱 재시작 후 충전 중인 경우를 대비해 세션 시작 시간 재확인
      // (세션이 나중에 시작될 수 있으므로)
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && widget.batteryInfo?.isCharging == true) {
          final currentSessionStartTime = _sessionService.sessionStartTime;
          if (currentSessionStartTime != _sessionStartTime) {
            _updateSessionStartTime();
          }
        }
      });
    }
    // 마지막 충전 정보 로드
    _loadLastChargingInfo();
  }
  
  /// 세션 시작 시간 업데이트
  void _updateSessionStartTime() {
    final sessionStartTime = _sessionService.sessionStartTime;
    if (mounted) {
      setState(() {
        _sessionStartTime = sessionStartTime;
      });
      
      // 지속 시간 표시 모드이고 충전 중이면 타이머 재시작
      final displayMode = _settingsService.appSettings.chargingMonitorDisplayMode;
      final isCharging = widget.batteryInfo?.isCharging ?? false;
      if (displayMode == ChargingMonitorDisplayMode.currentWithDuration && 
          isCharging && 
          sessionStartTime != null) {
        _startDurationUpdateTimer();
      }
    }
  }
  
  /// 지속 시간 업데이트 타이머 시작
  void _startDurationUpdateTimer() {
    // 기존 타이머가 있으면 취소
    _durationUpdateTimer?.cancel();
    
    // 설정 모드 확인
    final displayMode = _settingsService.appSettings.chargingMonitorDisplayMode;
    if (displayMode != ChargingMonitorDisplayMode.currentWithDuration) {
      // 지속 시간 표시 모드가 아니면 타이머 시작하지 않음
      return;
    }
    
    // 세션 시작 시간이 없으면 타이머 시작하지 않음
    if (_sessionStartTime == null) {
      return;
    }
    
    _durationUpdateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        _durationUpdateTimer = null;
        return;
      }

      // 충전 중이고 세션 시작 시간이 있으면 UI 업데이트
      final batteryInfo = _batteryService.currentBatteryInfo;
      final currentDisplayMode = _settingsService.appSettings.chargingMonitorDisplayMode;
      
      // 세션 시작 시간이 변경되었을 수 있으므로 재확인
      final currentSessionStartTime = _sessionService.sessionStartTime;
      if (currentSessionStartTime != _sessionStartTime) {
        setState(() {
          _sessionStartTime = currentSessionStartTime;
        });
      }
      
      if (batteryInfo != null && 
          batteryInfo.isCharging && 
          _sessionStartTime != null &&
          currentDisplayMode == ChargingMonitorDisplayMode.currentWithDuration) {
        setState(() {
          // 지속 시간 업데이트를 위해 setState 호출
        });
      } else {
        // 충전 중이 아니거나 설정이 변경되었으면 타이머 중지
        timer.cancel();
        _durationUpdateTimer = null;
      }
    });
  }
  
  /// 지속 시간 업데이트 타이머 중지
  void _stopDurationUpdateTimer() {
    _durationUpdateTimer?.cancel();
    _durationUpdateTimer = null;
  }

  /// 경과 시간 계산
  /// 세션 시작 시간으로부터 현재까지의 경과 시간을 반환
  Duration? _calculateElapsedDuration() {
    if (_sessionStartTime == null) {
      return null;
    }
    
    final duration = DateTime.now().difference(_sessionStartTime!);
    
    // 음수 duration 방지 (시스템 시간 변경 등 엣지 케이스)
    if (duration.isNegative) {
      return null;
    }
    
    return duration;
  }

  /// 지속 시간 포맷팅
  /// Duration을 "X시간 Y분" 또는 "Y분" 형식으로 변환
  String _formatDuration(Duration duration) {
    // 음수 duration 방지
    if (duration.isNegative) {
      return '0분';
    }
    
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    
    // 0분일 때 처리
    if (hours == 0 && minutes == 0) {
      return '0분';
    }
    
    if (hours > 0) {
      return '$hours시간 $minutes분';
    } else {
      return '$minutes분';
    }
  }

  /// 마지막 충전 정보 로드
  Future<void> _loadLastChargingInfo() async {
    final info = await _lastChargingInfoService.getLastChargingInfo();
    if (mounted) {
      setState(() {
        _lastChargingInfo = info;
      });
    }
  }

  /// 충전 시간 포맷팅
  String _formatChargingTime(DateTime? endTime) {
    if (endTime == null) {
      return '--';
    }
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final endDate = DateTime(endTime.year, endTime.month, endTime.day);
    
    String timeStr;
    if (endDate == today) {
      // 오늘
      final hour = endTime.hour;
      final minute = endTime.minute.toString().padLeft(2, '0');
      
      if (hour < 12) {
        timeStr = '오늘 오전 $hour:$minute';
      } else if (hour == 12) {
        timeStr = '오늘 오후 12:$minute';
      } else {
        timeStr = '오늘 오후 ${hour - 12}:$minute';
      }
    } else if (endDate == yesterday) {
      // 어제
      final hour = endTime.hour;
      final minute = endTime.minute.toString().padLeft(2, '0');
      
      if (hour < 12) {
        timeStr = '어제 오전 $hour:$minute';
      } else if (hour == 12) {
        timeStr = '어제 오후 12:$minute';
      } else {
        timeStr = '어제 오후 ${hour - 12}:$minute';
      }
    } else {
      // 그 이전
      final month = endTime.month;
      final day = endTime.day;
      final hour = endTime.hour;
      final minute = endTime.minute.toString().padLeft(2, '0');
      
      String period;
      if (hour < 12) {
        period = '오전 $hour:$minute';
      } else if (hour == 12) {
        period = '오후 12:$minute';
      } else {
        period = '오후 ${hour - 12}:$minute';
      }
      
      timeStr = '$month월 $day일 $period';
    }
    
    return timeStr;
  }

  @override
  void didUpdateWidget(RealtimeChargingMonitor oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 충전 상태 변화 감지
    final wasCharging = oldWidget.batteryInfo?.isCharging ?? false;
    final isCharging = widget.batteryInfo?.isCharging ?? false;

    if (!wasCharging && isCharging) {
      // 충전 시작
      _updateSessionStartTime();
      _startRealTimeUpdate();
    } else if (wasCharging && !isCharging) {
      // 충전 종료
      _stopRealTimeUpdate();
      // 세션 시작 시간 초기화
      setState(() {
        _sessionStartTime = null;
      });
      // 충전 종료 시 마지막 충전 정보 다시 로드
      _loadLastChargingInfo();
    } else if (isCharging) {
      // 충전 중일 때 세션 시작 시간이 변경될 수 있으므로 주기적으로 확인
      // (세션이 나중에 시작될 수 있음)
      final currentSessionStartTime = _sessionService.sessionStartTime;
      if (currentSessionStartTime != _sessionStartTime) {
        _updateSessionStartTime();
      }
      
      // 설정 모드가 변경되었을 수 있으므로 타이머 재시작 확인
      final displayMode = _settingsService.appSettings.chargingMonitorDisplayMode;
      if (displayMode == ChargingMonitorDisplayMode.currentWithDuration && 
          _sessionStartTime != null) {
        // 지속 시간 표시 모드이고 세션이 있으면 타이머 시작
        if (_durationUpdateTimer == null) {
          _startDurationUpdateTimer();
        }
      } else {
        // 지속 시간 표시 모드가 아니면 타이머 중지
        _stopDurationUpdateTimer();
      }
    }
  }

  void _startRealTimeUpdate() {
    // 충전 속도 업데이트 타이머 (200ms)
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      // BatteryService에서 현재 충전 전류 가져오기
      final batteryInfo = _batteryService.currentBatteryInfo;
      if (batteryInfo != null && batteryInfo.isCharging) {
        final current = batteryInfo.chargingCurrent.abs().toDouble();
        
        setState(() {
          _dataPoints.add(current);
          if (_dataPoints.length > _maxDataPoints) {
            _dataPoints.removeAt(0); // 오래된 데이터 제거
          }
        });
      } else {
        // 충전 중이 아니면 타이머 중지
        timer.cancel();
        _updateTimer = null;
      }
    });

    // 지속 시간 업데이트 타이머 시작 (설정 모드에 따라 조건부)
    _startDurationUpdateTimer();
  }

  void _stopRealTimeUpdate() {
    _updateTimer?.cancel();
    _updateTimer = null;
    _stopDurationUpdateTimer();
    setState(() {
      _dataPoints.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    // 설정 변경 감지
    return ListenableBuilder(
      listenable: _settingsService,
      builder: (context, child) {
        // 설정 변경 시 지속 시간 타이머 재시작 확인
        final displayMode = _settingsService.appSettings.chargingMonitorDisplayMode;
        final isCharging = widget.batteryInfo?.isCharging ?? false;
        
        if (isCharging && _sessionStartTime != null) {
          if (displayMode == ChargingMonitorDisplayMode.currentWithDuration) {
            // 지속 시간 표시 모드이고 세션이 있으면 타이머 시작
            if (_durationUpdateTimer == null) {
              _startDurationUpdateTimer();
            }
          } else {
            // 지속 시간 표시 모드가 아니면 타이머 중지
            _stopDurationUpdateTimer();
          }
        }
        
        return _buildChargingMonitor(context);
      },
    );
  }

  /// 충전 모니터 UI 빌드
  Widget _buildChargingMonitor(BuildContext context) {
    final isCharging = widget.batteryInfo?.isCharging ?? false;
    final current = widget.batteryInfo?.chargingCurrent ?? 0;
    final currentAbs = current.abs();
    
    // 현재 표시 모드 가져오기
    final displayMode = _settingsService.appSettings.chargingMonitorDisplayMode;

    // 충전 중이 아닐 때 표시할 UI
    if (!isCharging) {
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
                  child: _buildInfoCard(
                    context,
                    icon: '⏱️',
                    text: _formatChargingTime(_lastChargingInfo?.endTime),
                    subtitle: '충전 시간',
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildInfoCard(
                    context,
                    icon: '⚡',
                    text: _lastChargingInfo != null
                        ? _lastChargingInfoService.getSpeedText(_lastChargingInfo!.speed)
                        : '--',
                    subtitle: _lastChargingInfo != null
                        ? '${(_lastChargingInfo!.avgCurrent / 1000).toStringAsFixed(1)}A'
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
                  child: _buildInfoCard(
                    context,
                    icon: '🎯',
                    text: _lastChargingInfo != null
                        ? '${_lastChargingInfo!.batteryLevel.toInt()}%'
                        : '--',
                    subtitle: '충전 레벨',
                    color: Colors.purple,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildInfoCard(
                    context,
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

    // 충전 중일 때 실시간 모니터 표시
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.green.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Column(
        children: [
          // 심전도 스타일 그래프
          SizedBox(
            height: 180,
            child: Stack(
              children: [
                CustomPaint(
                  size: const Size(double.infinity, 180),
                  painter: ECGPainter(
                    dataPoints: _dataPoints,
                    color: Colors.green,
                  ),
                ),
                // 깜빡이는 점 (오른쪽 상단)
                const Positioned(
                  top: 0,
                  right: 0,
                  child: BlinkingDot(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 충전 속도와 지속 시간 (한 줄에 배치)
          SizedBox(
            height: 60, // 고정 높이로 스크롤 방지
            child: _buildChargingInfoRow(context, displayMode, currentAbs),
          ),

        ],
      ),
    );
  }

  /// 충전 정보 행 (충전 속도 + 지속 시간)
  Widget _buildChargingInfoRow(BuildContext context, ChargingMonitorDisplayMode displayMode, int currentAbs) {
    final showDuration = displayMode == ChargingMonitorDisplayMode.currentWithDuration;
    final durationWidget = showDuration ? _buildDurationDisplay(context) : null;
    
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
              '${_dataPoints.isNotEmpty ? _dataPoints.last.toInt() : currentAbs}',
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

  /// 지속 시간 표시 위젯 (오른쪽 하단)
  Widget _buildDurationDisplay(BuildContext context) {
    final elapsedDuration = _calculateElapsedDuration();
    
    if (elapsedDuration == null) {
      // 세션 시작 시간이 없으면 표시하지 않음
      return const SizedBox.shrink();
    }

    final durationText = _formatDuration(elapsedDuration);

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Icon(
          Icons.access_time,
          color: Colors.green.withValues(alpha: 0.7),
          size: 16,
        ),
        const SizedBox(width: 4),
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            durationText,
            style: TextStyle(
              color: Colors.green.withValues(alpha: 0.8),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  /// 정보 카드 위젯
  Widget _buildInfoCard(
    BuildContext context, {
    required String icon,
    required String text,
    required String subtitle,
    required Color color,
    bool isHighlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isHighlight
            ? color.withValues(alpha: 0.15)
            : color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isHighlight
              ? color.withValues(alpha: 0.4)
              : color.withValues(alpha: 0.2),
          width: isHighlight ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                icon,
                style: const TextStyle(fontSize: 18),
              ),
              const Spacer(),
              if (isHighlight)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '✓',
                    style: TextStyle(
                      color: color,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isHighlight
                  ? color
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _durationUpdateTimer?.cancel();
    super.dispose();
  }
}

/// 심전도 그래프 페인터
class ECGPainter extends CustomPainter {
  final List<double> dataPoints;
  final Color color;

  ECGPainter({required this.dataPoints, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // 그리드 배경
    _drawGrid(canvas, size);

    // 데이터 정규화
    if (dataPoints.length < 2) return;

    final maxValue = dataPoints.reduce((a, b) => a > b ? a : b);
    final minValue = dataPoints.reduce((a, b) => a < b ? a : b);
    final range = maxValue - minValue;

    final path = Path();
    final spacing = size.width / (dataPoints.length - 1);

    for (int i = 0; i < dataPoints.length; i++) {
      final x = i * spacing;
      final normalizedValue = range > 0
          ? (dataPoints[i] - minValue) / range
          : 0.5;
      final y = size.height - (normalizedValue * size.height * 0.8) - (size.height * 0.1);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);

    // 그림자 효과
    final shadowPaint = Paint()
      ..color = color.withValues(alpha: 0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawPath(path, shadowPaint);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..strokeWidth = 0.5;

    // 수평선
    for (int i = 0; i <= 4; i++) {
      final y = (size.height / 4) * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // 수직선
    for (int i = 0; i <= 10; i++) {
      final x = (size.width / 10) * i;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
  }

  @override
  bool shouldRepaint(ECGPainter oldDelegate) =>
      oldDelegate.dataPoints != dataPoints;
}

/// 깜빡이는 점 (녹화 중 표시)
class BlinkingDot extends StatefulWidget {
  const BlinkingDot({super.key});

  @override
  State<BlinkingDot> createState() => _BlinkingDotState();
}

class _BlinkingDotState extends State<BlinkingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

