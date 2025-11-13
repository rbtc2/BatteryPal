import 'package:flutter/material.dart';
import '../painters/battery_gauge_painter.dart';
import 'animated_charging_gauge.dart';
import 'battery_display_content.dart';
import '../models/battery_display_models.dart';

/// 원형 배터리 게이지 위젯
/// 배터리 레벨을 원형 게이지로 표시하고 중앙에 동적 정보를 표시
class CircularBatteryGauge extends StatelessWidget {
  final double level;
  final bool isCharging;
  final DisplayInfo displayInfo;
  final AnimationController cycleController;
  final AnimationController rotationController;
  final AnimationController pulseController;
  final Color backgroundColor;
  final VoidCallback? onTap;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;
  final ValueChanged<double>? onSwipeStart;

  const CircularBatteryGauge({
    super.key,
    required this.level,
    required this.isCharging,
    required this.displayInfo,
    required this.cycleController,
    required this.rotationController,
    required this.pulseController,
    required this.backgroundColor,
    this.onTap,
    this.onSwipeLeft,
    this.onSwipeRight,
    this.onSwipeStart,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // 배경 원 (게이지)
        SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: isCharging
              ? AnimatedChargingGauge(
                  level: level,
                  rotationController: rotationController,
                  pulseController: pulseController,
                  backgroundColor: backgroundColor,
                )
              : CustomPaint(
                  size: const Size(200, 200),
                  painter: BatteryGaugePainter(
                    progress: level / 100,
                    strokeWidth: 12,
                    backgroundColor: backgroundColor,
                  ),
                ),
        ),
        // 중앙 텍스트 (동적 표시) + 제스처 감지
        _BatteryGaugeGestureDetector(
          onTap: onTap,
          onSwipeStart: onSwipeStart,
          onSwipeLeft: onSwipeLeft,
          onSwipeRight: onSwipeRight,
          child: BatteryDisplayContent(
            displayInfo: displayInfo,
            cycleController: cycleController,
          ),
        ),
      ],
    );
  }
}

/// 제스처 감지 위젯 (스와이프 거리 계산 포함)
class _BatteryGaugeGestureDetector extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final ValueChanged<double>? onSwipeStart;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;

  const _BatteryGaugeGestureDetector({
    required this.child,
    this.onTap,
    this.onSwipeStart,
    this.onSwipeLeft,
    this.onSwipeRight,
  });

  @override
  State<_BatteryGaugeGestureDetector> createState() => _BatteryGaugeGestureDetectorState();
}

class _BatteryGaugeGestureDetectorState extends State<_BatteryGaugeGestureDetector> {
  double? _swipeStartX;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onHorizontalDragStart: widget.onSwipeStart != null
          ? (details) {
              _swipeStartX = details.globalPosition.dx;
              widget.onSwipeStart!(details.globalPosition.dx);
            }
          : null,
      onHorizontalDragEnd: (details) {
        if (widget.onSwipeLeft == null && widget.onSwipeRight == null) return;
        if (_swipeStartX == null) return;
        
        final swipeEndX = details.globalPosition.dx;
        final swipeDistance = swipeEndX - _swipeStartX!;
        
        // 최소 스와이프 거리 (50px)
        if (swipeDistance.abs() > 50) {
          if (swipeDistance > 0) {
            // 오른쪽으로 스와이프 -> 이전 정보
            widget.onSwipeRight?.call();
          } else {
            // 왼쪽으로 스와이프 -> 다음 정보
            widget.onSwipeLeft?.call();
          }
        }
        
        _swipeStartX = null;
      },
      behavior: HitTestBehavior.opaque,
      child: widget.child,
    );
  }
}

