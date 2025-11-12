import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/battery_service.dart';
import '../../services/last_charging_info_service.dart';
import '../../models/app_models.dart';

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
  Timer? _updateTimer;
  final BatteryService _batteryService = BatteryService();
  final LastChargingInfoService _lastChargingInfoService = LastChargingInfoService();
  
  // 마지막 충전 정보
  LastChargingInfo? _lastChargingInfo;

  @override
  void initState() {
    super.initState();
    // 충전 중일 때만 모니터링 시작
    if (widget.batteryInfo?.isCharging == true) {
      _startRealTimeUpdate();
    }
    // 마지막 충전 정보 로드
    _loadLastChargingInfo();
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
      _startRealTimeUpdate();
    } else if (wasCharging && !isCharging) {
      // 충전 종료
      _stopRealTimeUpdate();
      // 충전 종료 시 마지막 충전 정보 다시 로드
      _loadLastChargingInfo();
    }
  }

  void _startRealTimeUpdate() {
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
  }

  void _stopRealTimeUpdate() {
    _updateTimer?.cancel();
    _updateTimer = null;
    setState(() {
      _dataPoints.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isCharging = widget.batteryInfo?.isCharging ?? false;
    final current = widget.batteryInfo?.chargingCurrent ?? 0;
    final currentAbs = current.abs();

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

          // 현재 수치 (크게)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
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
              Text(
                'mA',
                style: TextStyle(
                  color: Colors.green.withValues(alpha: 0.7),
                  fontSize: 20,
                ),
              ),
            ],
          ),

        ],
      ),
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

