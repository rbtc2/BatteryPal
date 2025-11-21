import 'package:flutter/material.dart';
import '../../../models/charging_graph_theme.dart';
import '../../../utils/charging_graph_theme_colors.dart';
import '../painters/aurora_painter.dart';
import 'blinking_dot.dart';

/// 오로라 그래프 위젯
/// 충전 전류를 오로라(북극광) 스타일로 표시하는 위젯
/// 다중 리본 레이어와 애니메이션 효과를 지원
class AuroraGraph extends StatefulWidget {
  final List<double> dataPoints;
  final double height;

  const AuroraGraph({
    super.key,
    required this.dataPoints,
    this.height = 180.0,
  });

  @override
  State<AuroraGraph> createState() => _AuroraGraphState();
}

class _AuroraGraphState extends State<AuroraGraph>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  double _animationValue = 0.0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4), // 부드러운 오로라 흐름
    )..repeat();

    _animationController.addListener(() {
      setState(() {
        _animationValue = _animationController.value;
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 오로라 테마 색상 가져오기
    final gradientColors = ChargingGraphThemeColors.getGraphGradientColors(
      ChargingGraphTheme.aurora,
    ) ?? [Colors.purple];
    final gridColor = ChargingGraphThemeColors.getGridColor(
      ChargingGraphTheme.aurora,
    );

    return SizedBox(
      height: widget.height,
      child: Stack(
        children: [
          CustomPaint(
            key: ValueKey(
              'aurora_${widget.dataPoints.length}_${widget.dataPoints.isNotEmpty ? widget.dataPoints.last : 0}_$_animationValue',
            ),
            size: Size(double.infinity, widget.height),
            painter: AuroraPainter(
              dataPoints: widget.dataPoints,
              gradientColors: gradientColors,
              gridColor: gridColor,
              animationValue: _animationValue,
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

