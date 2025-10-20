import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/battery_history_models.dart';
import '../../utils/battery_chart_data_converter.dart';

/// 배터리 전압 차트 컴포넌트
/// 시간별 배터리 전압 변화를 시각화하는 전문가 수준의 차트
class BatteryVoltageChart extends StatefulWidget {
  /// 표시할 배터리 히스토리 데이터
  final List<BatteryHistoryDataPoint> dataPoints;
  
  /// 차트 높이
  final double height;
  
  /// 차트 너비
  final double? width;
  
  /// 차트 제목
  final String? title;
  
  /// 차트 부제목
  final String? subtitle;
  
  /// 색상 테마
  final BatteryVoltageChartTheme? theme;
  
  /// 터치 인터랙션 활성화 여부
  final bool enableTouchInteraction;
  
  /// 터치 시 콜백
  final Function(BatteryHistoryDataPoint)? onTouchDataPoint;
  
  /// 애니메이션 활성화 여부
  final bool enableAnimation;
  
  /// 애니메이션 지속 시간
  final Duration animationDuration;

  const BatteryVoltageChart({
    super.key,
    required this.dataPoints,
    this.height = 150.0,
    this.width,
    this.title,
    this.subtitle,
    this.theme,
    this.enableTouchInteraction = true,
    this.onTouchDataPoint,
    this.enableAnimation = true,
    this.animationDuration = const Duration(milliseconds: 1500),
  });

  @override
  State<BatteryVoltageChart> createState() => _BatteryVoltageChartState();
}

class _BatteryVoltageChartState extends State<BatteryVoltageChart>
    with TickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    
    if (widget.enableAnimation) {
      _animationController = AnimationController(
        duration: widget.animationDuration,
        vsync: this,
      );
      
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    if (widget.enableAnimation) {
      _animationController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 전압 데이터가 있는 데이터 포인트만 필터링
    final voltageDataPoints = widget.dataPoints
        .where((dataPoint) => dataPoint.hasVoltage)
        .toList();

    if (voltageDataPoints.isEmpty) {
      return _buildEmptyChart();
    }

    final theme = widget.theme ?? BatteryVoltageChartTheme.defaultTheme(context);
    
    return Container(
      width: widget.width,
      height: widget.height,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.title != null || widget.subtitle != null) ...[
            _buildChartHeader(theme),
            const SizedBox(height: 16),
          ],
          Expanded(
            child: _buildVoltageChart(voltageDataPoints, theme),
          ),
          const SizedBox(height: 8),
          _buildVoltageLegend(theme),
        ],
      ),
    );
  }

  /// 차트 헤더 구성
  Widget _buildChartHeader(BatteryVoltageChartTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.title != null)
          Text(
            widget.title!,
            style: theme.titleStyle,
          ),
        if (widget.subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            widget.subtitle!,
            style: theme.subtitleStyle,
          ),
        ],
      ],
    );
  }

  /// 전압 차트 구성
  Widget _buildVoltageChart(
    List<BatteryHistoryDataPoint> voltageDataPoints,
    BatteryVoltageChartTheme theme,
  ) {
    final spots = BatteryChartDataConverter.convertToVoltageFlSpots(voltageDataPoints);
    
    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: theme.primaryColor,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: widget.enableTouchInteraction,
              getDotPainter: (spot, percent, barData, index) {
                final voltage = spot.y;
                return FlDotCirclePainter(
                  radius: 4,
                  color: BatteryChartDataConverter.getVoltageColor(voltage),
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: theme.primaryColor.withValues(alpha: 0.1),
            ),
          ),
        ],
        
        // 터치 인터랙션
        lineTouchData: widget.enableTouchInteraction
            ? LineTouchData(
                enabled: true,
                touchTooltipData: LineTouchTooltipData(
                  tooltipRoundedRadius: 8,
                  tooltipPadding: const EdgeInsets.all(8),
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((touchedSpot) {
                      final index = touchedSpot.x.toInt();
                      if (index >= 0 && index < voltageDataPoints.length) {
                        final dataPoint = voltageDataPoints[index];
                        return LineTooltipItem(
                          '${dataPoint.voltage}mV\n${_formatTime(dataPoint.timestamp)}',
                          theme.tooltipTextStyle,
                        );
                      }
                      return null;
                    }).toList();
                  },
                ),
                handleBuiltInTouches: true,
                getTouchedSpotIndicator: (barData, spotIndexes) {
                  return spotIndexes.map((spotIndex) {
                    return TouchedSpotIndicatorData(
                      FlLine(
                        color: theme.touchIndicatorColor,
                        strokeWidth: 2,
                        dashArray: [5, 5],
                      ),
                      FlDotData(
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 6,
                            color: theme.touchIndicatorColor,
                            strokeWidth: 3,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                    );
                  }).toList();
                },
              )
            : LineTouchData(enabled: false),
        
        // 격자 및 축
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: _calculateVoltageInterval(voltageDataPoints),
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: theme.gridColor,
              strokeWidth: 1,
              dashArray: [5, 5],
            );
          },
        ),
        
        // X축
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: _calculateXAxisInterval(voltageDataPoints),
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < voltageDataPoints.length) {
                  return Text(
                    _formatTime(voltageDataPoints[index].timestamp),
                    style: theme.axisTextStyle,
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              interval: _calculateVoltageInterval(voltageDataPoints),
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}mV',
                  style: theme.axisTextStyle,
                );
              },
            ),
          ),
        ),
        
        // 경계
        borderData: FlBorderData(
          show: true,
          border: Border.all(
            color: theme.borderColor,
            width: 1,
          ),
        ),
      ),
    );
  }

  /// 전압 범례 구성
  Widget _buildVoltageLegend(BatteryVoltageChartTheme theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildVoltageLegendItem('낮음', Colors.red, '< 3500mV'),
        const SizedBox(width: 16),
        _buildVoltageLegendItem('보통', Colors.orange, '3500-4000mV'),
        const SizedBox(width: 16),
        _buildVoltageLegendItem('양호', Colors.green, '4000-4500mV'),
        const SizedBox(width: 16),
        _buildVoltageLegendItem('우수', Colors.blue, '> 4500mV'),
      ],
    );
  }

  /// 전압 범례 아이템 구성
  Widget _buildVoltageLegendItem(String label, Color color, String range) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        Text(
          range,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  /// 빈 차트 구성
  Widget _buildEmptyChart() {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.electrical_services,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 8),
            Text(
              '전압 데이터가 없습니다',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 전압 간격 계산
  double _calculateVoltageInterval(List<BatteryHistoryDataPoint> dataPoints) {
    if (dataPoints.isEmpty) return 200.0;
    
    final voltages = dataPoints.where((d) => d.hasVoltage).map((d) => d.voltage.toDouble()).toList();
    final minVoltage = voltages.reduce((a, b) => a < b ? a : b);
    final maxVoltage = voltages.reduce((a, b) => a > b ? a : b);
    final range = maxVoltage - minVoltage;
    
    if (range <= 200) return 50.0;
    if (range <= 500) return 100.0;
    if (range <= 1000) return 200.0;
    return 500.0;
  }

  /// X축 간격 계산
  double _calculateXAxisInterval(List<BatteryHistoryDataPoint> dataPoints) {
    if (dataPoints.length <= 6) return 1.0;
    return (dataPoints.length / 6).ceil().toDouble();
  }

  /// 시간 포맷팅
  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

/// 배터리 전압 차트 테마 클래스
class BatteryVoltageChartTheme {
  final Color primaryColor;
  final Color gridColor;
  final Color borderColor;
  final Color tooltipBackgroundColor;
  final Color touchIndicatorColor;
  final TextStyle titleStyle;
  final TextStyle subtitleStyle;
  final TextStyle axisTextStyle;
  final TextStyle tooltipTextStyle;

  const BatteryVoltageChartTheme({
    required this.primaryColor,
    required this.gridColor,
    required this.borderColor,
    required this.tooltipBackgroundColor,
    required this.touchIndicatorColor,
    required this.titleStyle,
    required this.subtitleStyle,
    required this.axisTextStyle,
    required this.tooltipTextStyle,
  });

  /// 기본 테마 생성
  factory BatteryVoltageChartTheme.defaultTheme(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return BatteryVoltageChartTheme(
      primaryColor: Colors.purple,
      gridColor: colorScheme.outline.withValues(alpha: 0.3),
      borderColor: colorScheme.outline.withValues(alpha: 0.5),
      tooltipBackgroundColor: colorScheme.surfaceContainerHighest,
      touchIndicatorColor: Colors.purple,
      titleStyle: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: colorScheme.onSurface,
      ),
      subtitleStyle: TextStyle(
        fontSize: 12,
        color: colorScheme.onSurface.withValues(alpha: 0.7),
      ),
      axisTextStyle: TextStyle(
        fontSize: 10,
        color: colorScheme.onSurface.withValues(alpha: 0.6),
      ),
      tooltipTextStyle: TextStyle(
        fontSize: 12,
        color: colorScheme.onSurface,
      ),
    );
  }
}
