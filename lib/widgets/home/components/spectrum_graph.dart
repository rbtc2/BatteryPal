import 'package:flutter/material.dart';
import '../painters/spectrum_painter.dart';
import 'blinking_dot.dart';

/// 스펙트럼 분석기 그래프 위젯
/// 충전 전류를 스펙트럼 분석기 스타일로 표시하는 위젯
/// 부드러운 애니메이션을 지원
class SpectrumGraph extends StatefulWidget {
  final List<double> dataPoints;
  final double height;

  const SpectrumGraph({
    super.key,
    required this.dataPoints,
    this.height = 180.0,
  });

  @override
  State<SpectrumGraph> createState() => _SpectrumGraphState();
}

class _SpectrumGraphState extends State<SpectrumGraph>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  List<double> _animatedDataPoints = [];
  List<double> _targetDataPoints = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300), // 부드러운 전환을 위한 애니메이션 시간
    );
    
    _targetDataPoints = List.from(widget.dataPoints);
    _animatedDataPoints = List.from(widget.dataPoints);
    
    _animationController.forward();
  }

  @override
  void didUpdateWidget(SpectrumGraph oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // 데이터가 변경되면 애니메이션 시작
    if (oldWidget.dataPoints != widget.dataPoints) {
      _targetDataPoints = List.from(widget.dataPoints);
      
      // 애니메이션 재시작
      _animationController.reset();
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: Stack(
        children: [
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              // 현재 데이터와 목표 데이터 사이를 보간
              if (_animatedDataPoints.length != _targetDataPoints.length) {
                _animatedDataPoints = List.filled(
                  _targetDataPoints.length,
                  0.0,
                );
              }
              
              for (int i = 0; i < _targetDataPoints.length; i++) {
                final currentValue = i < _animatedDataPoints.length
                    ? _animatedDataPoints[i]
                    : _targetDataPoints[i];
                final targetValue = _targetDataPoints[i];
                
                // 부드러운 보간
                _animatedDataPoints[i] = currentValue +
                    (targetValue - currentValue) * _animationController.value;
              }
              
              return CustomPaint(
                key: ValueKey('spectrum_${_animatedDataPoints.length}_${_animatedDataPoints.isNotEmpty ? _animatedDataPoints.last : 0}'),
                size: Size(double.infinity, widget.height),
                painter: SpectrumPainter(
                  dataPoints: _animatedDataPoints,
                  color: Colors.green,
                ),
              );
            },
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

