import 'package:flutter/material.dart';

/// 실시간 막대 그래프 페인터
/// 충전 전류를 막대 그래프 스타일로 그리는 커스텀 페인터
class BarGraphPainter extends CustomPainter {
  final List<double> dataPoints;
  final Color color;

  BarGraphPainter({required this.dataPoints, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.isEmpty) return;

    // 그리드 배경
    _drawGrid(canvas, size);

    // 데이터 정규화
    if (dataPoints.isEmpty) return;

    final maxValue = dataPoints.reduce((a, b) => a > b ? a : b);
    final minValue = dataPoints.reduce((a, b) => a < b ? a : b);
    final range = maxValue - minValue;

    // 막대 너비 계산
    final barCount = dataPoints.length;
    final totalSpacing = size.width * 0.1; // 양쪽 여백 5%씩
    final availableWidth = size.width - totalSpacing;
    final barWidth = availableWidth / barCount * 0.8; // 막대 간격을 위해 80%만 사용
    final barSpacing = availableWidth / barCount * 0.2; // 막대 간격 20%

    // 막대 그리기
    for (int i = 0; i < dataPoints.length; i++) {
      final x = (size.width * 0.05) + (i * (barWidth + barSpacing));
      
      // 데이터 정규화 (0.0 ~ 1.0)
      final normalizedValue = range > 0
          ? (dataPoints[i] - minValue) / range
          : 0.5;
      
      // 막대 높이 계산 (화면 높이의 80% 범위 내)
      final barHeight = normalizedValue * size.height * 0.8;
      
      // 막대 Y 위치 (하단에서 시작)
      final barY = size.height - barHeight;
      
      // 막대 그리기
      final barRect = Rect.fromLTWH(
        x,
        barY,
        barWidth,
        barHeight,
      );
      
      // 색상 그라데이션 (높이에 따라)
      final gradient = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          color,
          color.withValues(alpha: 0.7),
        ],
      );
      
      final paint = Paint()
        ..shader = gradient.createShader(barRect)
        ..style = PaintingStyle.fill;
      
      // 둥근 모서리 막대 그리기
      final roundedRect = RRect.fromRectAndRadius(
        barRect,
        const Radius.circular(2),
      );
      
      canvas.drawRRect(roundedRect, paint);
      
      // 막대 상단에 하이라이트 효과
      final highlightPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.3)
        ..style = PaintingStyle.fill;
      
      final highlightRect = Rect.fromLTWH(
        x,
        barY,
        barWidth,
        barHeight * 0.2, // 상단 20%만 하이라이트
      );
      
      final highlightRoundedRect = RRect.fromRectAndRadius(
        highlightRect,
        const Radius.circular(2),
      );
      
      canvas.drawRRect(highlightRoundedRect, highlightPaint);
    }
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
  bool shouldRepaint(BarGraphPainter oldDelegate) =>
      oldDelegate.dataPoints != dataPoints;
}

