import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../painters/battery_gauge_painter.dart';

/// 충전 중일 때 애니메이션이 적용된 게이지 위젯
class AnimatedChargingGauge extends StatelessWidget {
  final double level;
  final AnimationController rotationController;
  final AnimationController pulseController;
  final Color backgroundColor;

  const AnimatedChargingGauge({
    super.key,
    required this.level,
    required this.rotationController,
    required this.pulseController,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([rotationController, pulseController]),
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (pulseController.value * 0.05), // 5% 크기 변화
          child: Transform.rotate(
            angle: rotationController.value * 2 * math.pi,
            child: CustomPaint(
              size: const Size(200, 200),
              painter: BatteryGaugePainter(
                progress: level / 100,
                strokeWidth: 12,
                backgroundColor: backgroundColor,
              ),
            ),
          ),
        );
      },
    );
  }
}

