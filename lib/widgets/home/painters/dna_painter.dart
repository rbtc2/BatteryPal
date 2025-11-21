import 'package:flutter/material.dart';
import 'dart:math' as math;

/// DNA 나선 그래프 페인터
/// 충전 전류를 DNA 나선 구조 스타일로 그리는 커스텀 페인터
/// 두 개의 나선이 서로 감싸며 수직으로 뻗어나가는 형태
class DNAPainter extends CustomPainter {
  final List<double> dataPoints;
  final Color color;
  final List<Color>? gradientColors;
  final Color? gridColor;

  DNAPainter({
    required this.dataPoints,
    required this.color,
    this.gradientColors,
    this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.isEmpty) return;

    // 그리드 배경
    _drawGrid(canvas, size, gridColor ?? color.withValues(alpha: 0.1));

    // 데이터 정규화
    if (dataPoints.length < 2) return;

    final maxValue = dataPoints.reduce((a, b) => a > b ? a : b);
    final minValue = dataPoints.reduce((a, b) => a < b ? a : b);
    final range = maxValue - minValue;

    // 나선 색상 결정
    final helixColor = gradientColors != null && gradientColors!.isNotEmpty
        ? gradientColors!.first
        : color;

    // 나선 중심선 (수직 중앙)
    final centerX = size.width / 2;
    
    // 나선 반경 (데이터에 따라 조절)
    final baseRadius = size.width * 0.15; // 기본 반경
    
    // 나선 주기 (한 바퀴 도는 높이)
    final helixPeriod = size.height / 3; // 화면 높이의 1/3마다 한 바퀴

    // 첫 번째 나선 경로 (왼쪽)
    final helix1Path = Path();
    // 두 번째 나선 경로 (오른쪽)
    final helix2Path = Path();

    // 나선 포인트 저장 (입자 배치용)
    final helix1Points = <Offset>[];
    final helix2Points = <Offset>[];

    // 각 데이터 포인트에 대해 나선 포인트 계산
    for (int i = 0; i < dataPoints.length; i++) {
      final normalizedValue = range > 0
          ? (dataPoints[i] - minValue) / range
          : 0.5;
      
      // 높이 계산 (위에서 아래로)
      final y = (i / (dataPoints.length - 1)) * size.height;
      
      // 나선 각도 계산 (높이에 따라 회전)
      final angle = (y / helixPeriod) * 2 * math.pi;
      
      // 반경 계산 (데이터 값에 따라 조절)
      final radius = baseRadius * (0.7 + normalizedValue * 0.6);
      
      // 첫 번째 나선 (왼쪽)
      final x1 = centerX - radius * math.cos(angle);
      final point1 = Offset(x1, y);
      helix1Points.add(point1);
      
      // 두 번째 나선 (오른쪽, 반대 위상)
      final x2 = centerX + radius * math.cos(angle);
      final point2 = Offset(x2, y);
      helix2Points.add(point2);

      if (i == 0) {
        helix1Path.moveTo(point1.dx, point1.dy);
        helix2Path.moveTo(point2.dx, point2.dy);
      } else {
        helix1Path.lineTo(point1.dx, point1.dy);
        helix2Path.lineTo(point2.dx, point2.dy);
      }
    }

    // 나선 그리기
    _drawHelix(canvas, helix1Path, helix1Points, helixColor, gradientColors, dataPoints, maxValue, minValue, range);
    _drawHelix(canvas, helix2Path, helix2Points, helixColor, gradientColors, dataPoints, maxValue, minValue, range);

    // 나선 사이 연결선 (rung) 그리기
    _drawRungs(canvas, helix1Points, helix2Points, helixColor, gradientColors, dataPoints, maxValue, minValue, range);
  }

  /// 나선 그리기
  void _drawHelix(
    Canvas canvas,
    Path path,
    List<Offset> points,
    Color baseColor,
    List<Color>? gradientColors,
    List<double> dataPoints,
    double maxValue,
    double minValue,
    double range,
  ) {
    // 나선 글로우 효과
    final glowPaint = Paint()
      ..color = baseColor.withValues(alpha: 0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, glowPaint);

    // 메인 나선 그리기 (그라데이션 또는 단색)
    Paint helixPaint;
    if (gradientColors != null && gradientColors.length >= 2) {
      // 그라데이션 적용 (수직 그라데이션)
      final gradient = LinearGradient(
        colors: gradientColors,
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );
      helixPaint = Paint()
        ..shader = gradient.createShader(Rect.fromLTWH(0, 0, 1, path.getBounds().height))
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
    } else {
      helixPaint = Paint()
        ..color = baseColor
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
    }
    canvas.drawPath(path, helixPaint);

    // 나선 위에 입자 배치
    for (int i = 0; i < points.length; i++) {
      if (i % 3 == 0) { // 일부만 입자 표시 (성능 최적화)
        final normalizedValue = range > 0
            ? (dataPoints[i] - minValue) / range
            : 0.5;
        
        final particleSize = 2.0 + (normalizedValue * 3.0);
        final point = points[i];

        // 입자 글로우
        final particleGlowPaint = Paint()
          ..color = _getParticleColor(baseColor, normalizedValue, gradientColors)
            .withValues(alpha: 0.4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(point, particleSize * 1.5, particleGlowPaint);

        // 메인 입자
        final particlePaint = Paint()
          ..color = _getParticleColor(baseColor, normalizedValue, gradientColors)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(point, particleSize, particlePaint);
      }
    }
  }

  /// 나선 사이 연결선 (rung) 그리기
  void _drawRungs(
    Canvas canvas,
    List<Offset> helix1Points,
    List<Offset> helix2Points,
    Color baseColor,
    List<Color>? gradientColors,
    List<double> dataPoints,
    double maxValue,
    double minValue,
    double range,
  ) {
    // 일부만 연결선 그리기 (성능 최적화)
    final step = math.max(1, (helix1Points.length / 20).floor());
    
    for (int i = 0; i < helix1Points.length; i += step) {
      if (i >= helix2Points.length) break;
      
      final normalizedValue = range > 0
          ? (dataPoints[i] - minValue) / range
          : 0.5;
      
      final point1 = helix1Points[i];
      final point2 = helix2Points[i];

      // 연결선 색상 결정
      final rungColor = _getRungColor(baseColor, normalizedValue, gradientColors);
      
      // 연결선 그리기
      final rungPaint = Paint()
        ..color = rungColor
        ..strokeWidth = 1.0 + (normalizedValue * 1.5)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      
      canvas.drawLine(point1, point2, rungPaint);

      // 연결선 글로우
      final rungGlowPaint = Paint()
        ..color = rungColor.withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2)
        ..strokeWidth = 2.0 + (normalizedValue * 2.0)
        ..style = PaintingStyle.stroke;
      canvas.drawLine(point1, point2, rungGlowPaint);
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
        final lerpedColor = Color.lerp(
          gradientColors[segmentIndex],
          gradientColors[segmentIndex + 1],
          segmentT,
        );
        return lerpedColor ?? gradientColors[segmentIndex];
      }
    } else {
      final brightness = 0.8 + (normalizedValue * 0.2);
      return baseColor.withValues(alpha: brightness);
    }
  }

  /// 연결선 색상 결정
  Color _getRungColor(Color baseColor, double normalizedValue, List<Color>? gradientColors) {
    if (gradientColors != null && gradientColors.length >= 2) {
      final t = normalizedValue.clamp(0.0, 1.0);
      if (gradientColors.length == 2) {
        return Color.lerp(gradientColors[0], gradientColors[1], t) ?? gradientColors[0];
      } else {
        final segmentSize = 1.0 / (gradientColors.length - 1);
        final segmentIndex = (t / segmentSize).floor().clamp(0, gradientColors.length - 2);
        final segmentT = (t - segmentIndex * segmentSize) / segmentSize;
        final lerpedColor = Color.lerp(
          gradientColors[segmentIndex],
          gradientColors[segmentIndex + 1],
          segmentT,
        );
        return lerpedColor ?? gradientColors[segmentIndex];
      }
    } else {
      final brightness = 0.6 + (normalizedValue * 0.4);
      return baseColor.withValues(alpha: brightness);
    }
  }

  /// 그리드 배경 그리기
  void _drawGrid(Canvas canvas, Size size, Color gridColor) {
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
  bool shouldRepaint(DNAPainter oldDelegate) =>
      oldDelegate.dataPoints != dataPoints ||
      oldDelegate.color != color ||
      oldDelegate.gradientColors != gradientColors ||
      oldDelegate.gridColor != gridColor;
}

