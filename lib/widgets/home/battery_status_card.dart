import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../models/app_models.dart';

/// 배터리 상태 카드 위젯
/// 홈 탭에서 배터리 정보를 표시하는 카드 (원형 게이지 디자인)
class BatteryStatusCard extends StatefulWidget {
  final BatteryInfo? batteryInfo;

  const BatteryStatusCard({
    super.key,
    this.batteryInfo,
  });

  @override
  State<BatteryStatusCard> createState() => _BatteryStatusCardState();
}

class _BatteryStatusCardState extends State<BatteryStatusCard>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  
  @override
  void initState() {
    super.initState();
    
    // 회전 애니메이션 컨트롤러 (3초 주기)
    _rotationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    
    // 펄스 애니메이션 컨트롤러 (1.5초 주기)
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    // 충전 중일 때만 애니메이션 시작
    if (widget.batteryInfo?.isCharging == true) {
      _rotationController.repeat();
      _pulseController.repeat(reverse: true);
    }
  }
  
  @override
  void didUpdateWidget(BatteryStatusCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // 충전 상태가 변경될 때 애니메이션 제어
    if (widget.batteryInfo?.isCharging != oldWidget.batteryInfo?.isCharging) {
      if (widget.batteryInfo?.isCharging == true) {
        _rotationController.repeat();
        _pulseController.repeat(reverse: true);
      } else {
        _rotationController.stop();
        _pulseController.stop();
      }
    }
  }
  
  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final level = widget.batteryInfo?.level ?? 0;
    final isCharging = widget.batteryInfo?.isCharging ?? false;
    
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
                    value: widget.batteryInfo?.formattedTemperature ?? '--°C',
                    color: _getTemperatureColor(widget.batteryInfo?.temperature ?? 0),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    context,
                    icon: '⚡',
                    label: '전압',
                    value: widget.batteryInfo?.formattedVoltage ?? '--mV',
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    context,
                    icon: '✅',
                    label: '건강도',
                    value: widget.batteryInfo?.healthText ?? '알 수 없음',
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
    final isCharging = widget.batteryInfo?.isCharging ?? false;
    
    return Stack(
      alignment: Alignment.center,
      children: [
        // 배경 원
        SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: isCharging 
              ? _buildAnimatedChargingGauge(context, level)
              : CircularProgressIndicator(
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
  
  /// 충전 중일 때 애니메이션이 적용된 게이지
  Widget _buildAnimatedChargingGauge(BuildContext context, double level) {
    return AnimatedBuilder(
      animation: Listenable.merge([_rotationController, _pulseController]),
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (_pulseController.value * 0.05), // 5% 크기 변화
          child: Transform.rotate(
            angle: _rotationController.value * 2 * math.pi,
            child: CustomPaint(
              size: const Size(200, 200),
              painter: ChargingGaugePainter(
                progress: level / 100,
                strokeWidth: 12,
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
            ),
          ),
        );
      },
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

/// 충전 중일 때 그라데이션 효과가 적용된 게이지 페인터
class ChargingGaugePainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color backgroundColor;

  ChargingGaugePainter({
    required this.progress,
    required this.strokeWidth,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // 배경 원 그리기
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // 그라데이션 원 그리기
    final gradientPaint = Paint()
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // 그라데이션 색상 정의 (초록 → 파랑 → 보라)
    final colors = [
      Colors.green,
      Colors.blue,
      Colors.purple,
      Colors.green,
    ];

    // 그라데이션 생성
    final gradient = SweepGradient(
      colors: colors,
      stops: const [0.0, 0.33, 0.66, 1.0],
    );

    final rect = Rect.fromCircle(center: center, radius: radius);
    gradientPaint.shader = gradient.createShader(rect);

    // 진행률에 따른 호 그리기
    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      rect,
      -math.pi / 2, // 12시 방향부터 시작
      sweepAngle,
      false,
      gradientPaint,
    );
  }

  @override
  bool shouldRepaint(ChargingGaugePainter oldDelegate) {
    return oldDelegate.progress != progress ||
           oldDelegate.strokeWidth != strokeWidth ||
           oldDelegate.backgroundColor != backgroundColor;
  }
}
