import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/battery_history_models.dart';
import '../../utils/battery_chart_data_converter.dart';

/// 배터리 레벨 차트 컴포넌트
/// 시간별 배터리 레벨 변화를 시각화하는 전문가 수준의 차트
class BatteryLevelChart extends StatefulWidget {
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
  final BatteryChartTheme? theme;
  
  /// 터치 인터랙션 활성화 여부
  final bool enableTouchInteraction;
  
  /// 터치 시 콜백
  final Function(BatteryHistoryDataPoint)? onTouchDataPoint;
  
  /// 애니메이션 활성화 여부
  final bool enableAnimation;
  
  /// 애니메이션 지속 시간
  final Duration animationDuration;
  
  /// 차트 타입
  final BatteryChartType chartType;

  const BatteryLevelChart({
    super.key,
    required this.dataPoints,
    this.height = 200.0,
    this.width,
    this.title,
    this.subtitle,
    this.theme,
    this.enableTouchInteraction = true,
    this.onTouchDataPoint,
    this.enableAnimation = true,
    this.animationDuration = const Duration(milliseconds: 1500),
    this.chartType = BatteryChartType.line,
  });

  @override
  State<BatteryLevelChart> createState() => _BatteryLevelChartState();
}

class _BatteryLevelChartState extends State<BatteryLevelChart>
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
    if (widget.dataPoints.isEmpty) {
      return _buildEmptyChart();
    }

    final theme = widget.theme ?? BatteryChartTheme.defaultTheme(context);
    
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
            child: _buildChart(theme),
          ),
          const SizedBox(height: 8),
          _buildChartLegend(theme),
        ],
      ),
    );
  }

  /// 차트 헤더 구성
  Widget _buildChartHeader(BatteryChartTheme theme) {
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

  /// 실제 차트 구성
  Widget _buildChart(BatteryChartTheme theme) {
    switch (widget.chartType) {
      case BatteryChartType.line:
        return _buildLineChart(theme);
      case BatteryChartType.area:
        return _buildAreaChart(theme);
      case BatteryChartType.bar:
        return _buildBarChart(theme);
    }
  }

  /// 라인 차트 구성
  Widget _buildLineChart(BatteryChartTheme theme) {
    final colorBasedSpots = BatteryChartDataConverter.convertToColorBasedFlSpots(widget.dataPoints);
    
    return LineChart(
      LineChartData(
        lineBarsData: [
          // 충전 중 라인
          if (colorBasedSpots['charging']!.isNotEmpty)
            LineChartBarData(
              spots: colorBasedSpots['charging']!,
              isCurved: true,
              color: theme.chargingColor,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: widget.enableTouchInteraction,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: theme.chargingColor,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: false,
              ),
            ),
          
          // 방전 중 라인
          if (colorBasedSpots['discharging']!.isNotEmpty)
            LineChartBarData(
              spots: colorBasedSpots['discharging']!,
              isCurved: true,
              color: theme.dischargingColor,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: widget.enableTouchInteraction,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: theme.dischargingColor,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: false,
              ),
            ),
          
          // 충전 완료 라인
          if (colorBasedSpots['full']!.isNotEmpty)
            LineChartBarData(
              spots: colorBasedSpots['full']!,
              isCurved: true,
              color: theme.fullColor,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: widget.enableTouchInteraction,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: theme.fullColor,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: false,
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
                      if (index >= 0 && index < widget.dataPoints.length) {
                        final dataPoint = widget.dataPoints[index];
                        return LineTooltipItem(
                          '${dataPoint.level.toStringAsFixed(1)}%\n${_formatTime(dataPoint.timestamp)}',
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
          horizontalInterval: 25,
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
              interval: _calculateXAxisInterval(),
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < widget.dataPoints.length) {
                  return Text(
                    _formatTime(widget.dataPoints[index].timestamp),
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
              reservedSize: 40,
              interval: 25,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}%',
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
        
        // 애니메이션
        showingTooltipIndicators: widget.enableAnimation ? [] : [],
      ),
    );
  }

  /// 영역 차트 구성
  Widget _buildAreaChart(BatteryChartTheme theme) {
    final spots = BatteryChartDataConverter.convertToFlSpots(widget.dataPoints);
    
    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: theme.primaryColor,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: theme.primaryColor.withValues(alpha: 0.3),
            ),
          ),
        ],
        lineTouchData: widget.enableTouchInteraction
            ? LineTouchData(
                enabled: true,
                touchTooltipData: LineTouchTooltipData(
                  tooltipRoundedRadius: 8,
                  tooltipPadding: const EdgeInsets.all(8),
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((touchedSpot) {
                      final index = touchedSpot.x.toInt();
                      if (index >= 0 && index < widget.dataPoints.length) {
                        final dataPoint = widget.dataPoints[index];
                        return LineTooltipItem(
                          '${dataPoint.level.toStringAsFixed(1)}%\n${_formatTime(dataPoint.timestamp)}',
                          theme.tooltipTextStyle,
                        );
                      }
                      return null;
                    }).toList();
                  },
                ),
              )
            : LineTouchData(enabled: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 25,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: theme.gridColor,
              strokeWidth: 1,
              dashArray: [5, 5],
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: _calculateXAxisInterval(),
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < widget.dataPoints.length) {
                  return Text(
                    _formatTime(widget.dataPoints[index].timestamp),
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
              reservedSize: 40,
              interval: 25,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}%',
                  style: theme.axisTextStyle,
                );
              },
            ),
          ),
        ),
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

  /// 바 차트 구성
  Widget _buildBarChart(BatteryChartTheme theme) {
    final spots = BatteryChartDataConverter.convertToFlSpots(widget.dataPoints);
    
    return BarChart(
      BarChartData(
        barGroups: spots.map((spot) {
          return BarChartGroupData(
            x: spot.x.toInt(),
            barRods: [
              BarChartRodData(
                toY: spot.y,
                color: BatteryChartDataConverter.getBatteryLevelColor(spot.y),
                width: 8,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
            ],
          );
        }).toList(),
        barTouchData: widget.enableTouchInteraction
            ? BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  tooltipRoundedRadius: 8,
                  tooltipPadding: const EdgeInsets.all(8),
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final index = group.x;
                    if (index >= 0 && index < widget.dataPoints.length) {
                      final dataPoint = widget.dataPoints[index];
                      return BarTooltipItem(
                        '${dataPoint.level.toStringAsFixed(1)}%\n${_formatTime(dataPoint.timestamp)}',
                        theme.tooltipTextStyle,
                      );
                    }
                    return null;
                  },
                ),
              )
            : BarTouchData(enabled: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 25,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: theme.gridColor,
              strokeWidth: 1,
              dashArray: [5, 5],
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: _calculateXAxisInterval(),
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < widget.dataPoints.length) {
                  return Text(
                    _formatTime(widget.dataPoints[index].timestamp),
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
              reservedSize: 40,
              interval: 25,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}%',
                  style: theme.axisTextStyle,
                );
              },
            ),
          ),
        ),
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

  /// 차트 범례 구성
  Widget _buildChartLegend(BatteryChartTheme theme) {
    final colorBasedSpots = BatteryChartDataConverter.convertToColorBasedFlSpots(widget.dataPoints);
    final hasCharging = colorBasedSpots['charging']!.isNotEmpty;
    final hasDischarging = colorBasedSpots['discharging']!.isNotEmpty;
    final hasFull = colorBasedSpots['full']!.isNotEmpty;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (hasCharging) ...[
          _buildLegendItem('충전', theme.chargingColor),
          const SizedBox(width: 16),
        ],
        if (hasDischarging) ...[
          _buildLegendItem('방전', theme.dischargingColor),
          const SizedBox(width: 16),
        ],
        if (hasFull) ...[
          _buildLegendItem('완료', theme.fullColor),
        ],
      ],
    );
  }

  /// 범례 아이템 구성
  Widget _buildLegendItem(String label, Color color) {
    return Row(
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
              Icons.show_chart,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 8),
            Text(
              '표시할 데이터가 없습니다',
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

  /// X축 간격 계산
  double _calculateXAxisInterval() {
    if (widget.dataPoints.length <= 6) return 1.0;
    return (widget.dataPoints.length / 6).ceil().toDouble();
  }

  /// 시간 포맷팅
  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

/// 배터리 차트 타입 열거형
enum BatteryChartType {
  line,
  area,
  bar,
}

/// 배터리 차트 테마 클래스
class BatteryChartTheme {
  final Color primaryColor;
  final Color chargingColor;
  final Color dischargingColor;
  final Color fullColor;
  final Color gridColor;
  final Color borderColor;
  final Color tooltipBackgroundColor;
  final Color touchIndicatorColor;
  final TextStyle titleStyle;
  final TextStyle subtitleStyle;
  final TextStyle axisTextStyle;
  final TextStyle tooltipTextStyle;

  const BatteryChartTheme({
    required this.primaryColor,
    required this.chargingColor,
    required this.dischargingColor,
    required this.fullColor,
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
  factory BatteryChartTheme.defaultTheme(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return BatteryChartTheme(
      primaryColor: colorScheme.primary,
      chargingColor: Colors.green,
      dischargingColor: Colors.red,
      fullColor: Colors.blue,
      gridColor: colorScheme.outline.withValues(alpha: 0.3),
      borderColor: colorScheme.outline.withValues(alpha: 0.5),
      tooltipBackgroundColor: colorScheme.surfaceContainerHighest,
      touchIndicatorColor: colorScheme.primary,
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
