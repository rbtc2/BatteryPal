import 'package:flutter/material.dart';
import '../../../models/charging_graph_theme.dart';
import '../../../utils/charging_graph_theme_colors.dart';
import '../painters/dna_painter.dart';
import 'blinking_dot.dart';

/// DNA 나선 그래프 위젯
/// 충전 전류를 DNA 나선 구조 스타일로 표시하는 위젯
class DNAGraph extends StatelessWidget {
  final List<double> dataPoints;
  final double height;

  const DNAGraph({
    super.key,
    required this.dataPoints,
    this.height = 180.0,
  });

  @override
  Widget build(BuildContext context) {
    // DNA 나선 테마 색상 가져오기
    final graphColor = ChargingGraphThemeColors.getGraphColor(ChargingGraphTheme.dna);
    final gradientColors = ChargingGraphThemeColors.getGraphGradientColors(ChargingGraphTheme.dna);
    final gridColor = ChargingGraphThemeColors.getGridColor(ChargingGraphTheme.dna);

    return SizedBox(
      height: height,
      child: Stack(
        children: [
          CustomPaint(
            key: ValueKey('dna_${dataPoints.length}_${dataPoints.isNotEmpty ? dataPoints.last : 0}'),
            size: Size(double.infinity, height),
            painter: DNAPainter(
              dataPoints: dataPoints,
              color: graphColor,
              gradientColors: gradientColors,
              gridColor: gridColor,
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

