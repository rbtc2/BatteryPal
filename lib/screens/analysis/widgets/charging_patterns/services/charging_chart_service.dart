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

  /// ChargingCurrentPoint 리스트를 ChargingDataPoint 리스트로 변환
  /// 타임스탬프를 hour (0.0~24.0) 형식으로 변환하고,
  /// 충전 중이면 현재 시각까지 마지막 전류값을 연장
  static List<ChargingDataPoint> convertToChartData(
    List<ChargingCurrentPoint> points, {
    DateTime? targetDate,
  }) {
    // 1. 빈 데이터 처리
    if (points.isEmpty) {
      debugPrint('convertToChartData: 빈 데이터');
      return [];
    }

    // 2. 정렬 및 변환
    final sortedPoints = List<ChargingCurrentPoint>.from(points)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    
    final chartData = sortedPoints.map((p) {
      final hour = p.timestamp.hour + 
                   p.timestamp.minute / 60.0 + 
                   p.timestamp.second / 3600.0;
      return ChargingDataPoint(hour, p.currentMa.toDouble());
    }).toList();

    // 3. 충전 중이면 현재 시각까지 연장
    if (chartData.isNotEmpty && chartData.last.currentMa > 0) {
      final now = targetDate ?? DateTime.now();
      final currentHour = now.hour + now.minute / 60.0 + now.second / 3600.0;
      
      // 마지막 포인트보다 현재 시각이 더 늦으면 연장
      if (chartData.last.hour < currentHour) {
        chartData.add(ChargingDataPoint(currentHour, chartData.last.currentMa));
      }
    }

    debugPrint('convertToChartData: ${points.length} → ${chartData.length}');
    return chartData;
  }

  /// 충전 데이터를 세션별로 분리
  /// 0mA 포인트가 나오면 이전 세션 종료, 0mA가 아닌 포인트가 나오면 새 세션 시작
  static List<List<ChargingDataPoint>> _splitIntoSessions(List<ChargingDataPoint> data) {
    if (data.isEmpty) {
      debugPrint('_splitIntoSessions: 빈 데이터');
      return [];
    }

    final sessions = <List<ChargingDataPoint>>[];
    var currentSession = <ChargingDataPoint>[];

    for (final point in data) {
      if (point.currentMa > 0) {
        // 충전 중이면 현재 세션에 추가
        currentSession.add(point);
      } else if (currentSession.isNotEmpty) {
        // 0mA가 나오고 현재 세션이 있으면 세션 종료
        currentSession.add(point);  // 종료 포인트 포함
        sessions.add(List.from(currentSession));
        currentSession.clear();
      }
      // currentSession이 비어있고 0mA 포인트는 무시 (충전 전 상태)
    }

    // 마지막 세션이 아직 종료되지 않은 경우 (충전 중)
    if (currentSession.isNotEmpty) {
      sessions.add(currentSession);
    }

    debugPrint('_splitIntoSessions: ${sessions.length} sessions');
    return sessions;
  }

  /// 세션 내 연속성 보장
  /// 10초 간격 포인트들을 가로선으로 연결하기 위해 중간 포인트 추가
  /// 모든 연속된 포인트 사이에 "직전 포인트" 추가하여 계단식 연결 방지
  static List<ChargingDataPoint> _ensureContinuity(List<ChargingDataPoint> session) {
    if (session.length < 2) {
      return session;
    }

    final enhanced = <ChargingDataPoint>[];

    for (int i = 0; i < session.length - 1; i++) {
      // 현재 포인트 추가
      enhanced.add(session[i]);
      
      // 다음 포인트 직전에 이전 값을 유지하는 포인트 추가
      // 매우 작은 간격(0.000001 시간 = 약 0.0036초)을 두어 연속성 보장
      enhanced.add(ChargingDataPoint(
        session[i + 1].hour - 0.000001,
        session[i].currentMa,
      ));
    }

    // 마지막 포인트 추가
    enhanced.add(session.last);

    debugPrint('_ensureContinuity: ${session.length} → ${enhanced.length}');
    return enhanced;
  }
  
  /// 차트 바 데이터 생성
  /// 세션별로 LineChartBarData를 생성하고, 평균 전류에 따라 색상을 결정
  static List<LineChartBarData> buildLineChartBars(List<ChargingDataPoint> data) {
    final bars = <LineChartBarData>[];
    final sessions = _splitIntoSessions(data);

    for (final session in sessions) {
      if (session.isEmpty) continue;

      // 세션 내 연속성 보장
      final enhanced = _ensureContinuity(session);
      final spots = enhanced.map((p) => FlSpot(p.hour, p.currentMa)).toList();

      // 평균 전류로 색상 결정
      final avgCurrent = enhanced
          .map((p) => p.currentMa)
          .reduce((a, b) => a + b) / enhanced.length;
      
      final color = avgCurrent < 500
          ? Colors.blue[400]!
          : avgCurrent < 1500
              ? Colors.orange[400]!
              : Colors.red[400]!;

      bars.add(LineChartBarData(
        spots: spots,
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
      ));
    }

    debugPrint('buildLineChartBars: ${bars.length} bars created');
    return bars;
  }

  /// Y축 최대값 계산
  /// 데이터의 최대 전류값의 1.2배를 500 단위로 올림하여 반환
  /// 최소 500, 최대 10000으로 제한
  static double _calculateMaxY(List<ChargingDataPoint> data) {
    if (data.isEmpty) return 2500;

    final maxCurrent = data
        .map((p) => p.currentMa)
        .reduce((a, b) => a > b ? a : b);
    
    final maxY = ((maxCurrent * 1.2) / 500).ceil() * 500.0;
    return maxY.clamp(500, 10000);
  }

  /// 차트 설정 데이터 생성
  static LineChartData createChartData(List<ChargingDataPoint> data) {
    final maxY = _calculateMaxY(data);
    
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
      maxY: maxY,
      lineBarsData: buildLineChartBars(data),
    );
  }
}
