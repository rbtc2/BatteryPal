import 'package:flutter/material.dart';
import 'dart:math' as math;

/// 배터리 게이지 페인터 (Pro 업그레이드 그라데이션 적용)
class BatteryGaugePainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color backgroundColor;

  BatteryGaugePainter({
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

    // 진행률에 따른 호 그리기 (Pro 업그레이드 그라데이션 적용)
    final sweepAngle = 2 * math.pi * progress;
    final startAngle = -math.pi / 2; // 12시 방향부터 시작
    
    // 각도에 따라 색상을 계산하여 선형 그라데이션 효과 구현
    // 부드러운 그라데이션을 위해 충분한 세그먼트 수 사용
    final segments = (sweepAngle * 60 / (2 * math.pi)).ceil().clamp(1, 120);
    final segmentAngle = sweepAngle / segments;
    
    for (int i = 0; i < segments; i++) {
      final currentAngle = startAngle + (segmentAngle * i);
      final t = i / segments; // 0.0 ~ 1.0
      
      // Pro 업그레이드 그라데이션 색상 (초록 → 청록)
      final color = Color.lerp(
        Colors.green[400]!,
        Colors.teal[400]!,
        t,
      )!;
      
      final segmentPaint = Paint()
        ..color = color
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        currentAngle,
        segmentAngle,
        false,
        segmentPaint,
      );
    }
  }

  @override
  bool shouldRepaint(BatteryGaugePainter oldDelegate) {
    return oldDelegate.progress != progress ||
           oldDelegate.strokeWidth != strokeWidth ||
           oldDelegate.backgroundColor != backgroundColor;
  }
}

