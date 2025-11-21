import 'package:flutter/material.dart';
import 'dart:math' as math;

/// 파도/웨이브 그래프 페인터
/// 충전 전류를 파도 애니메이션 스타일로 그리는 커스텀 페인터
/// 사인파와 코사인파를 조합하여 부드러운 파도 효과 생성
class WavePainter extends CustomPainter {
  final List<double> dataPoints;
  final Color color;

  WavePainter({required this.dataPoints, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // 그리드 배경
    _drawGrid(canvas, size);

    // 데이터 정규화
    if (dataPoints.length < 2) return;

    final maxValue = dataPoints.reduce((a, b) => a > b ? a : b);
    final minValue = dataPoints.reduce((a, b) => a < b ? a : b);
    final range = maxValue - minValue;

    // 중앙 Y 위치 (파도가 중앙 기준으로 위아래로 흐름)
    final centerY = size.height / 2;
    
    // 파도 주파수 (데이터에 따라 조절)
    final waveFrequency = 2.0; // 파도 주파수
    final waveAmplitude = size.height * 0.35; // 파도 진폭 (화면 높이의 35%)

    final path = Path();
    final spacing = size.width / (dataPoints.length - 1);

    for (int i = 0; i < dataPoints.length; i++) {
      final x = i * spacing;
      
      // 데이터 정규화 (0.0 ~ 1.0)
      final normalizedValue = range > 0
          ? (dataPoints[i] - minValue) / range
          : 0.5;
      
      // 사인파 기반 파도 생성
      // 데이터 값에 따라 파도 진폭 조절
      final dataAmplitude = (normalizedValue - 0.5) * 2.0; // -1.0 ~ 1.0
      
      // 여러 파도 주파수를 조합하여 더 자연스러운 파도 생성
      final wave1 = math.sin((x / size.width) * math.pi * waveFrequency * 2) * waveAmplitude;
      final wave2 = math.cos((x / size.width) * math.pi * waveFrequency * 1.5) * waveAmplitude * 0.5;
      
      // 데이터 값에 따라 파도 높이 조절
      final y = centerY + (wave1 + wave2) * (0.5 + dataAmplitude * 0.5);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        // 부드러운 곡선을 위해 quadraticBezierTo 사용
        final prevX = (i - 1) * spacing;
        final controlX = (prevX + x) / 2;
        path.quadraticBezierTo(controlX, y, x, y);
      }
    }

    canvas.drawPath(path, paint);

    // 그림자 효과 (글로우)
    final shadowPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, shadowPaint);
    
    // 추가 파도 레이어 (더 부드러운 효과)
    final secondaryPath = Path();
    for (int i = 0; i < dataPoints.length; i++) {
      final x = i * spacing;
      final normalizedValue = range > 0
          ? (dataPoints[i] - minValue) / range
          : 0.5;
      final dataAmplitude = (normalizedValue - 0.5) * 2.0;
      
      // 약간 다른 주파수로 두 번째 파도 생성
      final wave1 = math.sin((x / size.width) * math.pi * waveFrequency * 2.3) * waveAmplitude * 0.6;
      final wave2 = math.cos((x / size.width) * math.pi * waveFrequency * 1.8) * waveAmplitude * 0.3;
      
      final y = centerY + (wave1 + wave2) * (0.5 + dataAmplitude * 0.5);

      if (i == 0) {
        secondaryPath.moveTo(x, y);
      } else {
        final prevX = (i - 1) * spacing;
        final controlX = (prevX + x) / 2;
        secondaryPath.quadraticBezierTo(controlX, y, x, y);
      }
    }
    
    final secondaryPaint = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(secondaryPath, secondaryPaint);
  }

  /// 그리드 배경 그리기
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
  bool shouldRepaint(WavePainter oldDelegate) =>
      oldDelegate.dataPoints != dataPoints;
}

