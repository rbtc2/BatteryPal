import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/charging_data_models.dart';

/// 충전 차트 관련 서비스 클래스
class ChargingChartService {
  /// 더미 데이터 생성 함수
  static List<ChargingDataPoint> generateDummyData() {
    return [
      ChargingDataPoint(0, 0),
      ChargingDataPoint(2, 0),
      ChargingDataPoint(2.25, 500),  // 02:15 충전 시작
      ChargingDataPoint(4.5, 500),
      ChargingDataPoint(4.5, 2100),  // 04:30 급속 전환
      ChargingDataPoint(6, 2100),
      ChargingDataPoint(6, 500),     // 06:00 저속 전환
      ChargingDataPoint(7, 500),
      ChargingDataPoint(7, 0),       // 07:00 충전 종료
      ChargingDataPoint(9, 0),
      ChargingDataPoint(9, 2100),    // 09:00 급속 충전
      ChargingDataPoint(10.25, 2100),
      ChargingDataPoint(10.25, 0),   // 10:15 종료
      ChargingDataPoint(18.5, 0),
      ChargingDataPoint(18.5, 1000), // 18:30 일반 충전
      ChargingDataPoint(19, 1000),
      ChargingDataPoint(19, 0),      // 19:00 종료
      ChargingDataPoint(24, 0),
    ];
  }
  
  /// 차트 바 데이터 생성
  static List<LineChartBarData> buildLineChartBars(List<ChargingDataPoint> data) {
    List<LineChartBarData> bars = [];
    
    // 저속 세그먼트 (파란색)
    bars.add(_createSegment(data, 0, 500, Colors.blue[400]!));
    
    // 일반 세그먼트 (주황색)
    bars.add(_createSegment(data, 500, 1500, Colors.orange[400]!));
    
    // 급속 세그먼트 (빨간색)
    bars.add(_createSegment(data, 1500, 2500, Colors.red[400]!));
    
    return bars;
  }
  
  /// 세그먼트별 차트 바 생성
  static LineChartBarData _createSegment(
    List<ChargingDataPoint> data,
    double minCurrent,
    double maxCurrent,
    Color color,
  ) {
    final spots = <FlSpot>[];
    
    for (var point in data) {
      if (point.currentMa >= minCurrent && point.currentMa < maxCurrent) {
        spots.add(FlSpot(point.hour, point.currentMa));
      }
    }
    
    return LineChartBarData(
      spots: spots.isEmpty ? [FlSpot(0, 0)] : spots,
      isCurved: true,
      color: color,
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: FlDotData(show: false),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.3),
            color.withValues(alpha: 0.0),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }

  /// 차트 설정 데이터 생성
  static LineChartData createChartData(List<ChargingDataPoint> data) {
    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        horizontalInterval: 500,
        verticalInterval: 4,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: Colors.grey.withValues(alpha: 0.2),
            strokeWidth: 1,
          );
        },
        getDrawingVerticalLine: (value) {
          return FlLine(
            color: Colors.grey.withValues(alpha: 0.2),
            strokeWidth: 1,
          );
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        bottomTitles: AxisTitles(
          axisNameWidget: Text(
            '시간 (Hour)',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 4,
            getTitlesWidget: (value, meta) {
              return Text(
                value.toInt().toString(),
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                ),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          axisNameWidget: Text(
            'mA',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 45,
            interval: 500,
            getTitlesWidget: (value, meta) {
              return Text(
                value.toInt().toString(),
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                ),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.3),
        ),
      ),
      minX: 0,
      maxX: 24,
      minY: 0,
      maxY: 2500,
      lineBarsData: buildLineChartBars(data),
    );
  }
}
