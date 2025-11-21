import 'package:flutter/material.dart';
import '../../../models/charging_graph_theme.dart';
import '../../../utils/charging_graph_theme_colors.dart';
import '../painters/particle_painter.dart';
import 'blinking_dot.dart';

/// 에너지 나무 그래프 위젯
/// 충전 전류를 에너지 나무 스타일로 표시하는 위젯
class ParticleGraph extends StatelessWidget {
  final List<double> dataPoints;
  final double height;

  const ParticleGraph({
    super.key,
    required this.dataPoints,
    this.height = 180.0,
  });

  @override
  Widget build(BuildContext context) {
    // 에너지 나무 테마 색상 가져오기
    final graphColor = ChargingGraphThemeColors.getGraphColor(ChargingGraphTheme.particle);
    final gradientColors = ChargingGraphThemeColors.getGraphGradientColors(ChargingGraphTheme.particle);
    final gridColor = ChargingGraphThemeColors.getGridColor(ChargingGraphTheme.particle);

    return SizedBox(
      height: height,
      child: Stack(
        children: [
          CustomPaint(
            key: ValueKey('particle_${dataPoints.length}_${dataPoints.isNotEmpty ? dataPoints.last : 0}'),
            size: Size(double.infinity, height),
            painter: ParticlePainter(
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

