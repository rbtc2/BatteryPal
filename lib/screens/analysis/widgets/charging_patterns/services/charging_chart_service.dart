import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/charging_data_models.dart';

/// 충전 차트 관련 서비스 클래스
class ChargingChartService {
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
    
    // targetDate가 있으면 해당 날짜의 시작 시간을 기준으로 계산
    DateTime? baseDate;
    if (targetDate != null) {
      baseDate = DateTime(targetDate.year, targetDate.month, targetDate.day);
    } else if (sortedPoints.isNotEmpty) {
      // targetDate가 없으면 첫 번째 데이터 포인트의 날짜를 기준으로 사용
      final firstPoint = sortedPoints.first;
      baseDate = DateTime(firstPoint.timestamp.year, firstPoint.timestamp.month, firstPoint.timestamp.day);
    }
    
    // 먼저 같은 날짜 데이터만 필터링하고, 같은 시간의 포인트는 하나만 남김
    final filteredPoints = <ChargingCurrentPoint>[];
    final seenTimes = <int>{}; // 밀리초 단위로 중복 체크
    
    for (final p in sortedPoints) {
      DateTime pointDate = DateTime(p.timestamp.year, p.timestamp.month, p.timestamp.day);
      
      // baseDate와 같은 날짜인 경우만 처리
      if (baseDate != null && 
          pointDate.year == baseDate.year &&
          pointDate.month == baseDate.month &&
          pointDate.day == baseDate.day) {
        // 같은 시간(초 단위)의 포인트는 가장 최근 것만 사용 (전류 값이 업데이트된 것)
        final timeKey = p.timestamp.millisecondsSinceEpoch ~/ 1000; // 초 단위로 정규화
        
        if (!seenTimes.contains(timeKey)) {
          filteredPoints.add(p);
          seenTimes.add(timeKey);
        } else {
          // 같은 시간의 포인트가 이미 있으면, 더 높은 전류 값을 가진 것으로 교체 (충전 중이므로)
          final existingIndex = filteredPoints.indexWhere(
            (existing) => (existing.timestamp.millisecondsSinceEpoch ~/ 1000) == timeKey
          );
          if (existingIndex >= 0 && p.currentMa > filteredPoints[existingIndex].currentMa) {
            filteredPoints[existingIndex] = p;
          }
        }
      }
    }
    
    // 시간(hour)으로 변환하고, 같은 시간의 포인트는 하나로 통합
    // 시간을 분 단위로 반올림하여 너무 가까운 포인트들을 통합 (최소 1분 간격)
    final timeMap = <double, double>{}; // hour -> currentMa
    
    for (final p in filteredPoints) {
      // 분 단위로 반올림 (예: 13.5시간 = 13시 30분)
      final totalMinutes = p.timestamp.hour * 60 + p.timestamp.minute;
      final roundedHour = totalMinutes / 60.0; // 분 단위로 반올림된 시간
      
      // 같은 시간(분 단위)이면 더 높은 전류 값 사용 (충전 중이므로 증가하는 것이 정상)
      if (!timeMap.containsKey(roundedHour) || p.currentMa > timeMap[roundedHour]!) {
        timeMap[roundedHour] = p.currentMa.toDouble();
      }
    }
    
    // 시간 순서대로 정렬하여 변환
    final chartData = timeMap.entries
        .map((e) => ChargingDataPoint(e.key, e.value))
        .toList()
      ..sort((a, b) => a.hour.compareTo(b.hour));

    // 3. 충전 중이면 현재 시각까지 연장
    if (chartData.isNotEmpty && chartData.last.currentMa > 0 && baseDate != null) {
      final now = targetDate ?? DateTime.now();
      final nowDate = DateTime(now.year, now.month, now.day);
      
      // 같은 날짜이고 현재 시각이 마지막 포인트보다 늦으면 연장
      if (nowDate.year == baseDate.year &&
          nowDate.month == baseDate.month &&
          nowDate.day == baseDate.day) {
        final currentHour = now.hour + now.minute / 60.0 + now.second / 3600.0;
        
        // 마지막 포인트보다 현재 시각이 더 늦으면 연장
        if (chartData.last.hour < currentHour) {
          chartData.add(ChargingDataPoint(currentHour, chartData.last.currentMa));
        }
      }
    }

    debugPrint('convertToChartData: ${points.length} → ${chartData.length} (baseDate: $baseDate)');
    return chartData;
  }

  /// 충전 데이터를 세션별로 분리
  /// 0mA 포인트가 나오면 이전 세션 종료, 0mA가 아닌 포인트가 나오면 새 세션 시작
  /// 각 세션은 시작 시간부터 종료 시간까지의 연속된 충전 구간
  static List<List<ChargingDataPoint>> _splitIntoSessions(List<ChargingDataPoint> data) {
    if (data.isEmpty) {
      debugPrint('_splitIntoSessions: 빈 데이터');
      return [];
    }

    final sessions = <List<ChargingDataPoint>>[];
    var currentSession = <ChargingDataPoint>[];
    bool isCharging = false;

    for (final point in data) {
      if (point.currentMa > 0) {
        // 충전 시작 감지
        if (!isCharging && currentSession.isEmpty) {
          // 이전 세션이 끝나고 새로운 세션 시작
          currentSession = [point];
          isCharging = true;
        } else if (isCharging) {
          // 충전 중이면 현재 세션에 추가
          currentSession.add(point);
        }
      } else {
        // 0mA 감지 - 충전 종료
        if (isCharging && currentSession.isNotEmpty) {
          // 세션 종료 포인트 추가 (선택적)
          // 마지막 충전 포인트 직전까지가 세션
          sessions.add(List.from(currentSession));
          currentSession.clear();
          isCharging = false;
        }
      }
    }

    // 마지막 세션이 아직 종료되지 않은 경우 (충전 중)
    if (currentSession.isNotEmpty) {
      sessions.add(currentSession);
    }

    debugPrint('_splitIntoSessions: ${sessions.length} sessions');
    return sessions;
  }

  /// 세션 내 연속성 보장
  /// 각 충전 세션에서 안정적인 전류 값을 찾아 가로 선으로 표시
  /// 순간적인 급격한 변화는 필터링하고, 보편적인 충전 속도를 표시
  /// 전류가 실제로 변하는 구간(일정 시간 이상 지속)은 별도 구간으로 처리
  static List<ChargingDataPoint> _ensureContinuity(List<ChargingDataPoint> session) {
    if (session.isEmpty) return session;
    if (session.length == 1) {
      // 1개 포인트만 있으면 시작점과 끝점이 같으므로 2개로 만들어야 함
      return [session.first, session.first];
    }

    // 세션 내에서 전류 값이 크게 변하는 구간을 찾기
    // 각 구간에서 안정적인 전류 값을 계산
    final simplified = <ChargingDataPoint>[];
    int segmentStartIndex = 0;
    double segmentCurrent = session[0].currentMa;
    
    // 최소 구간 지속 시간 (3분 = 0.05시간) - 이보다 짧은 변화는 무시
    const minSegmentDuration = 3.0 / 60.0; // 3분
    // 전류 변화 임계값 (100mA 이상 차이날 때만 구간 분리)
    const currentChangeThreshold = 100.0;
    
    for (int i = 1; i < session.length; i++) {
      final point = session[i];
      final timeDiff = point.hour - session[segmentStartIndex].hour;
      final currentDiff = (point.currentMa - segmentCurrent).abs();
      
      // 전류 값이 크게 변했고, 일정 시간 이상 지속된 경우만 구간 분리
      if (currentDiff > currentChangeThreshold && timeDiff >= minSegmentDuration) {
        // 이전 구간 처리
        final segmentPoints = session.sublist(segmentStartIndex, i);
        final stableCurrent = _calculateStableCurrent(segmentPoints);
        
        simplified.add(ChargingDataPoint(session[segmentStartIndex].hour, stableCurrent));
        simplified.add(ChargingDataPoint(session[i - 1].hour, stableCurrent));
        
        // 새 구간 시작
        segmentStartIndex = i;
        segmentCurrent = point.currentMa;
      }
    }
    
    // 마지막 구간 처리
    final lastSegmentPoints = session.sublist(segmentStartIndex);
    final lastStableCurrent = _calculateStableCurrent(lastSegmentPoints);
    
    simplified.add(ChargingDataPoint(session[segmentStartIndex].hour, lastStableCurrent));
    simplified.add(ChargingDataPoint(session.last.hour, lastStableCurrent));

    debugPrint('_ensureContinuity: ${session.length} → ${simplified.length}');
    return simplified;
  }
  
  /// 세션 내에서 안정적인 전류 값을 계산
  /// 순간적인 급격한 변화를 필터링하고 보편적인 충전 속도를 찾음
  static double _calculateStableCurrent(List<ChargingDataPoint> points) {
    if (points.isEmpty) return 0.0;
    if (points.length == 1) return points.first.currentMa;
    
    // 1. 중앙값 계산 (극값의 영향을 줄임)
    final sortedValues = points.map((p) => p.currentMa).toList()..sort();
    final medianIndex = sortedValues.length ~/ 2;
    final median = sortedValues.length % 2 == 1
        ? sortedValues[medianIndex]
        : (sortedValues[medianIndex - 1] + sortedValues[medianIndex]) / 2.0;
    
    // 2. 중앙값 기준으로 ±20% 범위 내의 값들만 사용 (이상치 제거)
    final filteredValues = sortedValues.where((v) => 
      (v - median).abs() <= median * 0.2
    ).toList();
    
    if (filteredValues.isEmpty) {
      // 필터링된 값이 없으면 중앙값 사용
      return median;
    }
    
    // 3. 필터링된 값들의 평균 계산 (안정적인 충전 속도)
    final average = filteredValues.reduce((a, b) => a + b) / filteredValues.length;
    
    return average;
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
        isCurved: false, // 직선형으로 표시 (충전 속도는 일정하므로)
        color: color,
        barWidth: 3,
        isStrokeCapRound: false,
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
