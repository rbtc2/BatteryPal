import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

/// 시간대별 소모 그래프 - 시간대별 배터리 소모 패턴을 표시하는 위젯
/// 
/// fl_chart의 BarChart를 사용하여 시간대별 소모 패턴을 시각화합니다.
class DrainHourlyChart extends StatefulWidget {
  final bool isProUser;
  final VoidCallback? onProUpgrade;

  const DrainHourlyChart({
    super.key,
    required this.isProUser,
    this.onProUpgrade,
  });

  @override
  State<DrainHourlyChart> createState() => _DrainHourlyChartState();
}

class _DrainHourlyChartState extends State<DrainHourlyChart> {
  /// 더미 데이터: 시간대별 소모량 (%)
  /// 0, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22 시간대 (12개)
  final List<double> _dummyData = [1.2, 0.8, 0.5, 0.3, 0.4, 1.5, 2.3, 3.1, 2.8, 2.2, 1.8, 1.0];

  /// Pull-to-Refresh를 위한 public 메서드
  Future<void> refresh() async {
    // 더미 데이터이므로 실제 새로고침 로직은 없음
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '시간대별 소모 패턴',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          
          // 차트 영역
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              height: 200,
              child: _buildChart(context, primaryColor),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 피크 정보
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '피크: -- (--% 소모, --%/h)',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// 차트 빌드
  Widget _buildChart(BuildContext context, Color barColor) {
    final theme = Theme.of(context);
    
    return BarChart(
      BarChartData(
        barGroups: List.generate(12, (index) {
          final hour = index * 2; // 0, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22
          final value = _dummyData[index];
          
          return BarChartGroupData(
            x: hour,
            barRods: [
              BarChartRodData(
                toY: value,
                color: barColor,
                width: 12,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
              ),
            ],
          );
        }),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipRoundedRadius: 8,
            tooltipPadding: const EdgeInsets.all(8),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final hour = group.x.toInt();
              final value = rod.toY;
              return BarTooltipItem(
                '$hour시\n${value.toStringAsFixed(1)}%',
                TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 2,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
              strokeWidth: 1,
              dashArray: [5, 5],
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 2,
              getTitlesWidget: (value, meta) {
                final hour = value.toInt();
                if (hour >= 0 && hour <= 22 && hour % 2 == 0) {
                  return Text(
                    '$hour',
                    style: TextStyle(
                      fontSize: 10,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
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
              interval: 2,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}',
                  style: TextStyle(
                    fontSize: 10,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
    );
  }
}

