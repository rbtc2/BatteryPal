import 'package:flutter/material.dart';
import 'dart:math' as math;

/// 스펙트럼 분석기 페인터
/// 충전 전류를 스펙트럼 분석기 스타일로 그리는 커스텀 페인터
/// 여러 주파수 대역의 막대 그래프를 표시
class SpectrumPainter extends CustomPainter {
  final List<double> dataPoints;
  final Color color;

  SpectrumPainter({required this.dataPoints, required this.color});

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

    // 스펙트럼 막대 개수 (주파수 대역 수)
    // 데이터 포인트를 여러 대역으로 나누거나, 고정된 대역 수 사용
    final bandCount = math.min(dataPoints.length, 32); // 최대 32개 대역
    
    // 막대 너비 계산
    final totalSpacing = size.width * 0.1; // 양쪽 여백 5%씩
    final availableWidth = size.width - totalSpacing;
    final barWidth = availableWidth / bandCount * 0.8; // 막대 간격을 위해 80%만 사용
    final barSpacing = availableWidth / bandCount * 0.2; // 막대 간격 20%

    // 각 주파수 대역의 데이터 계산
    final bandsPerDataPoint = dataPoints.length / bandCount;
    
    for (int i = 0; i < bandCount; i++) {
      final x = (size.width * 0.05) + (i * (barWidth + barSpacing));
      
      // 해당 대역의 데이터 포인트들 평균 계산
      final startIdx = (i * bandsPerDataPoint).floor();
      final endIdx = ((i + 1) * bandsPerDataPoint).floor();
      final bandDataPoints = dataPoints.sublist(
        math.min(startIdx, dataPoints.length - 1),
        math.min(endIdx, dataPoints.length),
      );
      
      final bandAverage = bandDataPoints.isEmpty
          ? 0.0
          : bandDataPoints.reduce((a, b) => a + b) / bandDataPoints.length;
      
      // 데이터 정규화 (0.0 ~ 1.0)
      final normalizedValue = range > 0
          ? (bandAverage - minValue) / range
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
      
      // 주파수 대역별 색상 그라데이션
      // 낮은 주파수(왼쪽) = 파랑, 중간 = 초록, 높은 주파수(오른쪽) = 빨강
      final frequencyRatio = i / bandCount; // 0.0 ~ 1.0
      final bandColor = _getFrequencyColor(frequencyRatio);
      
      final gradient = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          bandColor,
          bandColor.withValues(alpha: 0.7),
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

  /// 주파수 비율에 따른 색상 계산
  /// 0.0 (낮은 주파수) = 파랑, 0.5 (중간) = 초록, 1.0 (높은 주파수) = 빨강
  Color _getFrequencyColor(double frequencyRatio) {
    if (frequencyRatio < 0.5) {
      // 파랑 -> 초록 (0.0 ~ 0.5)
      final ratio = frequencyRatio * 2.0; // 0.0 ~ 1.0
      return Color.lerp(
        Colors.blue,
        Colors.green,
        ratio,
      )!;
    } else {
      // 초록 -> 빨강 (0.5 ~ 1.0)
      final ratio = (frequencyRatio - 0.5) * 2.0; // 0.0 ~ 1.0
      return Color.lerp(
        Colors.green,
        Colors.red,
        ratio,
      )!;
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
  bool shouldRepaint(SpectrumPainter oldDelegate) =>
      oldDelegate.dataPoints != dataPoints;
}

