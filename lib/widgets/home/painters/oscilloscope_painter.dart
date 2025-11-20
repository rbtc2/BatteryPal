import 'package:flutter/material.dart';

/// 오실로스코프 그래프 페인터
/// 충전 전류를 오실로스코프 스타일로 그리는 커스텀 페인터
/// 중앙 기준선을 기준으로 위아래로 진동하는 파형을 표시
class OscilloscopePainter extends CustomPainter {
  final List<double> dataPoints;
  final Color color;

  OscilloscopePainter({required this.dataPoints, required this.color});

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

    // 중앙 기준선 그리기 (오실로스코프 특징)
    _drawCenterLine(canvas, size);

    // 데이터 정규화 및 그리기
    if (dataPoints.length < 2) return;

    final maxValue = dataPoints.reduce((a, b) => a > b ? a : b);
    final minValue = dataPoints.reduce((a, b) => a < b ? a : b);
    final range = maxValue - minValue;
    
    // 중앙 기준선 위치 (화면 중앙)
    final centerY = size.height / 2;
    
    // 진폭 계산 (중앙 기준선을 중심으로 위아래로 진동)
    // 범위의 절반을 진폭으로 사용

    final path = Path();
    final spacing = size.width / (dataPoints.length - 1);

    for (int i = 0; i < dataPoints.length; i++) {
      final x = i * spacing;
      
      // 중앙 기준선을 기준으로 정규화 (0.0 ~ 1.0)
      final normalizedValue = range > 0
          ? (dataPoints[i] - minValue) / range
          : 0.5;
      
      // 중앙 기준선 기준으로 위아래 진동 (-1.0 ~ 1.0 범위로 변환)
      final offset = (normalizedValue - 0.5) * 2.0; // -1.0 ~ 1.0
      
      // 진폭을 고려한 Y 좌표 계산
      // 중앙 기준선에서 위아래로 진동
      final y = centerY - (offset * centerY * 0.8); // 화면 높이의 80% 범위 내에서 진동

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

  /// 중앙 기준선 그리기
  void _drawCenterLine(Canvas canvas, Size size) {
    final centerLinePaint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    
    final centerY = size.height / 2;
    canvas.drawLine(
      Offset(0, centerY),
      Offset(size.width, centerY),
      centerLinePaint,
    );
  }

  /// 그리드 배경 그리기
  void _drawGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..strokeWidth = 0.5;

    // 수평선 (중앙 기준선 포함)
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
  bool shouldRepaint(OscilloscopePainter oldDelegate) =>
      oldDelegate.dataPoints != dataPoints;
}

