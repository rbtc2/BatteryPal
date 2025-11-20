import 'package:flutter/material.dart';
import '../painters/oscilloscope_painter.dart';
import 'blinking_dot.dart';

/// 오실로스코프 그래프 위젯
/// 충전 전류를 오실로스코프 스타일로 표시하는 위젯
class OscilloscopeGraph extends StatelessWidget {
  final List<double> dataPoints;
  final double height;

  const OscilloscopeGraph({
    super.key,
    required this.dataPoints,
    this.height = 180.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Stack(
        children: [
          CustomPaint(
            size: Size(double.infinity, height),
            painter: OscilloscopePainter(
              dataPoints: dataPoints,
              color: Colors.green,
            ),
          ),
          // 깜빡이는 점 (오른쪽 상단)
          const Positioned(
            top: 0,
            right: 0,
            child: BlinkingDot(),
          ),
        ],
      ),
    );
  }
}

