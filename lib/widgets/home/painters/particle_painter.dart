import 'package:flutter/material.dart';
import 'dart:math' as math;

/// 에너지 나무 그래프 페인터
/// 충전 전류를 방사형 입자 흐름 + 나무 가지형 분기 스타일로 그리는 커스텀 페인터
/// 화면 중앙에서 시작하여 나무 가지처럼 분기하며 퍼져나가는 에너지 흐름
class ParticlePainter extends CustomPainter {
  final List<double> dataPoints;
  final Color color;
  final List<Color>? gradientColors;
  final Color? gridColor;

  ParticlePainter({
    required this.dataPoints,
    required this.color,
    this.gradientColors,
    this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.isEmpty) return;

    // 원형 그리드 배경
    _drawCircularGrid(canvas, size, gridColor ?? color.withValues(alpha: 0.1));

    // 데이터 정규화
    if (dataPoints.length < 2) return;

    final maxValue = dataPoints.reduce((a, b) => a > b ? a : b);
    final minValue = dataPoints.reduce((a, b) => a < b ? a : b);
    final range = maxValue - minValue;

    // 화면 중앙 (에너지 나무의 뿌리)
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.min(size.width, size.height) * 0.4; // 최대 반경

    // 입자 색상 결정
    final particleColor = gradientColors != null && gradientColors!.isNotEmpty
        ? gradientColors!.first
        : color;

    // 나무 가지 구조 생성
    final branches = _createBranchStructure(dataPoints, maxValue, minValue, range, maxRadius);

    // 나무 가지 그리기
    for (final branch in branches) {
      _drawBranch(canvas, center, branch, particleColor, gradientColors);
    }

    // 중앙 핵심 에너지원 그리기
    _drawEnergyCore(canvas, center, particleColor);
  }

  /// 나무 가지 구조 생성
  List<Branch> _createBranchStructure(
    List<double> dataPoints,
    double maxValue,
    double minValue,
    double range,
    double maxRadius,
  ) {
    final branches = <Branch>[];
    
    // 데이터 포인트를 각도로 매핑 (0°~360°)
    final angleStep = 2 * math.pi / dataPoints.length;
    
    for (int i = 0; i < dataPoints.length; i++) {
      final normalizedValue = range > 0
          ? (dataPoints[i] - minValue) / range
          : 0.5;
      
      // 각도 계산
      final angle = i * angleStep;
      
      // 반경 계산 (데이터 값에 비례, 최소 10%, 최대 100%)
      final radius = maxRadius * (0.1 + normalizedValue * 0.9);
      
      // 메인 가지 생성
      final mainBranch = Branch(
        angle: angle,
        radius: radius,
        normalizedValue: normalizedValue,
        level: 0,
      );
      branches.add(mainBranch);
      
      // 분기 생성 (데이터 값이 클수록 더 많은 분기)
      if (normalizedValue > 0.3) {
        final branchCount = (normalizedValue * 2).floor() + 1; // 1~3개 분기
        
        for (int j = 0; j < branchCount; j++) {
          // 분기 각도 (메인 가지에서 약간 벗어남)
          final branchAngleOffset = (j - branchCount / 2) * 0.3;
          final branchAngle = angle + branchAngleOffset;
          
          // 분기 길이 (메인 가지보다 짧음)
          final branchRadius = radius * (0.5 + normalizedValue * 0.3);
          
          final subBranch = Branch(
            angle: branchAngle,
            radius: branchRadius,
            normalizedValue: normalizedValue * 0.8,
            level: 1,
            parentAngle: angle,
            parentRadius: radius,
          );
          branches.add(subBranch);
        }
      }
    }
    
    return branches;
  }

  /// 나무 가지 그리기
  void _drawBranch(
    Canvas canvas,
    Offset center,
    Branch branch,
    Color baseColor,
    List<Color>? gradientColors,
  ) {
    // 가지 끝 위치 계산
    final endX = center.dx + math.cos(branch.angle) * branch.radius;
    final endY = center.dy + math.sin(branch.angle) * branch.radius;
    final endPosition = Offset(endX, endY);

    // 부모 가지가 있으면 부모에서 시작, 없으면 중앙에서 시작
    Offset startPosition;
    if (branch.parentAngle != null && branch.parentRadius != null) {
      final parentX = center.dx + math.cos(branch.parentAngle!) * branch.parentRadius!;
      final parentY = center.dy + math.sin(branch.parentAngle!) * branch.parentRadius!;
      startPosition = Offset(parentX, parentY);
    } else {
      startPosition = center;
    }

    // 가지 선 그리기
    final branchPaint = Paint()
      ..color = _getBranchColor(baseColor, branch.normalizedValue, gradientColors)
      ..strokeWidth = 1.5 + (branch.normalizedValue * 1.5)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    canvas.drawLine(startPosition, endPosition, branchPaint);

    // 가지 글로우 효과
    final glowPaint = Paint()
      ..color = _getBranchColor(baseColor, branch.normalizedValue, gradientColors)
        .withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3)
      ..strokeWidth = 2.0 + (branch.normalizedValue * 2.0)
      ..style = PaintingStyle.stroke;
    canvas.drawLine(startPosition, endPosition, glowPaint);

    // 가지 끝에 입자 그리기
    final particleSize = 3.0 + (branch.normalizedValue * 4.0);
    
    // 입자 글로우
    final particleGlowPaint = Paint()
      ..color = _getParticleColor(baseColor, branch.normalizedValue, gradientColors)
        .withValues(alpha: 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(endPosition, particleSize * 1.8, particleGlowPaint);

    // 메인 입자
    final particlePaint = Paint()
      ..color = _getParticleColor(baseColor, branch.normalizedValue, gradientColors)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(endPosition, particleSize, particlePaint);

    // 입자 외곽선
    final outlinePaint = Paint()
      ..color = baseColor.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    canvas.drawCircle(endPosition, particleSize, outlinePaint);
  }

  /// 중앙 핵심 에너지원 그리기
  void _drawEnergyCore(Canvas canvas, Offset center, Color baseColor) {
    // 외곽 글로우
    final outerGlowPaint = Paint()
      ..color = baseColor.withValues(alpha: 0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 12, outerGlowPaint);

    // 중간 글로우
    final middleGlowPaint = Paint()
      ..color = baseColor.withValues(alpha: 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 8, middleGlowPaint);

    // 핵심
    final corePaint = Paint()
      ..color = baseColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 5, corePaint);

    // 핵심 외곽선
    final coreOutlinePaint = Paint()
      ..color = baseColor.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, 5, coreOutlinePaint);
  }

  /// 가지 색상 결정
  Color _getBranchColor(Color baseColor, double normalizedValue, List<Color>? gradientColors) {
    if (gradientColors != null && gradientColors.length >= 2) {
      final t = normalizedValue.clamp(0.0, 1.0);
      if (gradientColors.length == 2) {
        return Color.lerp(gradientColors[0], gradientColors[1], t) ?? gradientColors[0];
      } else {
        final segmentSize = 1.0 / (gradientColors.length - 1);
        final segmentIndex = (t / segmentSize).floor().clamp(0, gradientColors.length - 2);
        final segmentT = (t - segmentIndex * segmentSize) / segmentSize;
        return Color.lerp(
          gradientColors[segmentIndex],
          gradientColors[segmentIndex + 1],
          segmentT,
        ) ?? gradientColors[segmentIndex];
      }
    } else {
      final brightness = 0.6 + (normalizedValue * 0.4);
      return baseColor.withValues(alpha: brightness);
    }
  }

  /// 입자 색상 결정
  Color _getParticleColor(Color baseColor, double normalizedValue, List<Color>? gradientColors) {
    if (gradientColors != null && gradientColors.length >= 2) {
      final t = normalizedValue.clamp(0.0, 1.0);
      if (gradientColors.length == 2) {
        return Color.lerp(gradientColors[0], gradientColors[1], t) ?? gradientColors[0];
      } else {
        final segmentSize = 1.0 / (gradientColors.length - 1);
        final segmentIndex = (t / segmentSize).floor().clamp(0, gradientColors.length - 2);
        final segmentT = (t - segmentIndex * segmentSize) / segmentSize;
        return Color.lerp(
          gradientColors[segmentIndex],
          gradientColors[segmentIndex + 1],
          segmentT,
        ) ?? gradientColors[segmentIndex];
      }
    } else {
      final brightness = 0.8 + (normalizedValue * 0.2);
      return baseColor.withValues(alpha: brightness);
    }
  }

  /// 원형 그리드 배경 그리기
  void _drawCircularGrid(Canvas canvas, Size size, Color gridColor) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.min(size.width, size.height) * 0.45;
    
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5;

    // 동심원 그리기
    for (int i = 1; i <= 4; i++) {
      final radius = maxRadius * (i / 4);
      canvas.drawCircle(center, radius, gridPaint);
    }

    // 방사형 선 그리기 (12시 방향부터 시작)
    for (int i = 0; i < 12; i++) {
      final angle = (i * 2 * math.pi / 12) - (math.pi / 2); // 12시 방향부터
      final endX = center.dx + math.cos(angle) * maxRadius;
      final endY = center.dy + math.sin(angle) * maxRadius;
      canvas.drawLine(center, Offset(endX, endY), gridPaint);
    }
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) =>
      oldDelegate.dataPoints != dataPoints ||
      oldDelegate.color != color ||
      oldDelegate.gradientColors != gradientColors ||
      oldDelegate.gridColor != gridColor;
}

/// 나무 가지 구조
class Branch {
  final double angle; // 각도 (라디안)
  final double radius; // 반경
  final double normalizedValue; // 정규화된 데이터 값 (0.0 ~ 1.0)
  final int level; // 가지 레벨 (0: 메인, 1: 서브)
  final double? parentAngle; // 부모 가지 각도
  final double? parentRadius; // 부모 가지 반경

  Branch({
    required this.angle,
    required this.radius,
    required this.normalizedValue,
    required this.level,
    this.parentAngle,
    this.parentRadius,
  });
}
