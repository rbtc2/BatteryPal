import 'package:flutter/material.dart';
import 'dart:math' as math;

/// 오로라 그래프 페인터
/// 충전 전류를 오로라(북극광) 스타일로 그리는 커스텀 페인터
/// 다중 리본 레이어, 수직 그라데이션, 파티클 효과를 사용
class AuroraPainter extends CustomPainter {
  final List<double> dataPoints;
  final List<Color> gradientColors;
  final Color gridColor;
  final double animationValue; // 애니메이션 값 (0.0 ~ 1.0)

  AuroraPainter({
    required this.dataPoints,
    required this.gradientColors,
    required this.gridColor,
    this.animationValue = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.isEmpty) return;

    // 그리드 배경
    _drawGrid(canvas, size);

    // 별 파티클 배경
    _drawParticles(canvas, size);

    // 데이터 정규화
    if (dataPoints.length < 2) return;

    final maxValue = dataPoints.reduce((a, b) => a > b ? a : b);
    final minValue = dataPoints.reduce((a, b) => a < b ? a : b);
    final range = maxValue - minValue;

    // 오로라 리본 레이어 수 (3-5개)
    final layerCount = 4;
    final spacing = size.width / (dataPoints.length - 1);

    // 각 레이어를 뒤에서 앞으로 그리기 (깊이감)
    for (int layer = layerCount - 1; layer >= 0; layer--) {
      final layerOpacity = 0.3 + (layer / layerCount) * 0.5; // 뒤 레이어일수록 투명
      final layerOffset = (layer - layerCount / 2) * 3.0; // 레이어 간 오프셋
      
      // 각 레이어의 색상 (그라데이션 색상에서 선택)
      final colorIndex = (layer * gradientColors.length / layerCount).floor();
      final layerColor = gradientColors[math.min(colorIndex, gradientColors.length - 1)];

      // 리본 경로 생성
      final path = Path();
      final fillPath = Path(); // 채우기용 경로

      for (int i = 0; i < dataPoints.length; i++) {
        final x = i * spacing;
        
        // 데이터 정규화 (0.0 ~ 1.0)
        final normalizedValue = range > 0
            ? (dataPoints[i] - minValue) / range
            : 0.5;
        
        // 오로라 파도 효과 (사인파 기반)
        final wavePhase = (x / size.width) * math.pi * 4 + animationValue * math.pi * 2;
        final waveOffset = math.sin(wavePhase) * 8.0 * (1.0 - layer / layerCount);
        
        // 리본 높이 (데이터 값에 따라)
        final ribbonHeight = size.height * 0.15 * (0.5 + normalizedValue * 0.5);
        final centerY = size.height * 0.5 + (normalizedValue - 0.5) * size.height * 0.3;
        
        // 레이어별 Y 위치 (오프셋 적용)
        final y = centerY + layerOffset + waveOffset;
        final topY = y - ribbonHeight / 2;

        if (i == 0) {
          path.moveTo(x, topY);
          fillPath.moveTo(x, topY);
        } else {
          // 부드러운 곡선
          final prevX = (i - 1) * spacing;
          final controlX = (prevX + x) / 2;
          path.quadraticBezierTo(controlX, topY, x, topY);
          fillPath.quadraticBezierTo(controlX, topY, x, topY);
        }
      }

      // 하단 경로 (역순)
      for (int i = dataPoints.length - 1; i >= 0; i--) {
        final x = i * spacing;
        final normalizedValue = range > 0
            ? (dataPoints[i] - minValue) / range
            : 0.5;
        
        final wavePhase = (x / size.width) * math.pi * 4 + animationValue * math.pi * 2;
        final waveOffset = math.sin(wavePhase) * 8.0 * (1.0 - layer / layerCount);
        
        final ribbonHeight = size.height * 0.15 * (0.5 + normalizedValue * 0.5);
        final centerY = size.height * 0.5 + (normalizedValue - 0.5) * size.height * 0.3;
        final y = centerY + layerOffset + waveOffset;
        final bottomY = y + ribbonHeight / 2;

        if (i == dataPoints.length - 1) {
          fillPath.lineTo(x, bottomY);
        } else {
          final nextX = (i + 1) * spacing;
          final controlX = (x + nextX) / 2;
          fillPath.quadraticBezierTo(controlX, bottomY, x, bottomY);
        }
      }

      fillPath.close();

      // 수직 그라데이션 생성 (위에서 아래로)
      final gradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          layerColor.withValues(alpha: layerOpacity),
          layerColor.withValues(alpha: layerOpacity * 0.6),
          layerColor.withValues(alpha: layerOpacity * 0.3),
        ],
        stops: const [0.0, 0.5, 1.0],
      );

      // 리본 채우기
      final fillPaint = Paint()
        ..shader = gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height))
        ..style = PaintingStyle.fill;
      
      canvas.drawPath(fillPath, fillPaint);

      // 리본 테두리 (글로우 효과)
      final strokePaint = Paint()
        ..color = layerColor.withValues(alpha: layerOpacity * 0.8)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      
      canvas.drawPath(path, strokePaint);

      // 글로우 효과 (블러)
      final glowPaint = Paint()
        ..color = layerColor.withValues(alpha: layerOpacity * 0.4)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8.0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;
      
      canvas.drawPath(path, glowPaint);
    }
  }

  /// 별 파티클 배경 그리기
  void _drawParticles(Canvas canvas, Size size) {
    final random = math.Random(42); // 고정 시드로 일관된 별 위치
    final particleCount = 30;

    for (int i = 0; i < particleCount; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final brightness = random.nextDouble() * 0.5 + 0.3; // 0.3 ~ 0.8
      
      // 데이터에 따라 별 밝기 조절 (애니메이션 값 사용)
      final pulse = (math.sin(animationValue * math.pi * 2 + i) + 1) / 2;
      final alpha = brightness * (0.5 + pulse * 0.5);

      final paint = Paint()
        ..color = Colors.white.withValues(alpha: alpha)
        ..style = PaintingStyle.fill;

      // 작은 별 그리기
      canvas.drawCircle(
        Offset(x, y),
        1.0 + random.nextDouble() * 1.0,
        paint,
      );
    }
  }

  /// 그리드 배경 그리기
  void _drawGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = gridColor
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
  bool shouldRepaint(AuroraPainter oldDelegate) =>
      oldDelegate.dataPoints != dataPoints ||
      oldDelegate.gradientColors != gradientColors ||
      oldDelegate.gridColor != gridColor ||
      (oldDelegate.animationValue - animationValue).abs() > 0.01;
}

