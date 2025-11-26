import 'dart:math';
import 'package:battery_plus/battery_plus.dart';
import '../models/battery_history_models.dart';

/// 배터리 분석 엔진
/// 전문가 수준의 배터리 데이터 분석 및 인사이트 생성
class BatteryAnalysisEngine {
  /// 배터리 히스토리 데이터를 분석하여 종합적인 분석 결과 생성
  static Future<BatteryHistoryAnalysis> performComprehensiveAnalysis(
    List<BatteryHistoryDataPoint> dataPoints, {
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    if (dataPoints.isEmpty) {
      throw Exception('분석할 데이터가 없습니다.');
    }

    final actualStartTime = startTime ?? dataPoints.first.timestamp;
    final actualEndTime = endTime ?? dataPoints.last.timestamp;
    final analysisDuration = actualEndTime.difference(actualStartTime);

    // 기본 통계 계산
    final basicStats = _calculateBasicStatistics(dataPoints);
    
    // 패턴 분석
    final patternAnalysis = _analyzeUsagePatterns(dataPoints, actualStartTime, actualEndTime);
    
    // 충전/방전 이벤트 분석
    final chargingEvents = _analyzeChargingEvents(dataPoints);
    final dischargingEvents = _analyzeDischargingEvents(dataPoints);
    
    // 효율성 분석
    final efficiencyAnalysis = _analyzeEfficiency(dataPoints, patternAnalysis);
    
    // 인사이트 생성
    final insights = _generateInsights(
      basicStats,
      patternAnalysis,
      chargingEvents,
      dischargingEvents,
      efficiencyAnalysis,
    );

    // 추천사항 생성
    final recommendations = _generateRecommendations(
      basicStats,
      patternAnalysis,
      chargingEvents,
      dischargingEvents,
      efficiencyAnalysis,
    );

    return BatteryHistoryAnalysis(
      analysisStartTime: actualStartTime,
      analysisEndTime: actualEndTime,
      dataPointCount: dataPoints.length,
      analysisDurationHours: analysisDuration.inMinutes / 60.0,
      averageBatteryLevel: basicStats['averageLevel']!,
      minBatteryLevel: basicStats['minLevel']!,
      maxBatteryLevel: basicStats['maxLevel']!,
      batteryVariation: basicStats['variation']!,
      averageDischargeRate: basicStats['averageDischargeRate']!,
      averageChargeRate: basicStats['averageChargeRate']!,
      chargingSessions: chargingEvents.length,
      averageChargingSessionMinutes: _calculateAverageChargingSessionMinutes(chargingEvents),
      overallDataQuality: basicStats['overallDataQuality']!,
      insights: insights,
      patternAnalysis: patternAnalysis,
      chargingEvents: chargingEvents,
      dischargingEvents: dischargingEvents,
      recommendations: recommendations,
      patternSummary: patternAnalysis['summary']!,
    );
  }

  /// 기본 통계 계산
  static Map<String, double> _calculateBasicStatistics(
    List<BatteryHistoryDataPoint> dataPoints,
  ) {
    if (dataPoints.isEmpty) {
      return {
        'averageLevel': 0.0,
        'minLevel': 0.0,
        'maxLevel': 0.0,
        'variation': 0.0,
        'averageTemperature': 0.0,
        'averageVoltage': 0.0,
        'averageDischargeRate': 0.0,
        'averageChargeRate': 0.0,
        'overallDataQuality': 0.0,
      };
    }

    final levels = dataPoints.map((d) => d.level).toList();
    final avgLevel = levels.reduce((a, b) => a + b) / levels.length;
    final minLevel = levels.reduce((a, b) => a < b ? a : b);
    final maxLevel = levels.reduce((a, b) => a > b ? a : b);
    final variation = maxLevel - minLevel;

    // 온도 통계
    final temperatureData = dataPoints.where((d) => d.hasTemperature).toList();
    final avgTemperature = temperatureData.isNotEmpty
        ? temperatureData.map((d) => d.temperature).reduce((a, b) => a + b) / temperatureData.length
        : 0.0;

    // 전압 통계
    final voltageData = dataPoints.where((d) => d.hasVoltage).toList();
    final avgVoltage = voltageData.isNotEmpty
        ? voltageData.map((d) => d.voltage.toDouble()).reduce((a, b) => a + b) / voltageData.length
        : 0.0;

    // 방전/충전 속도 계산
    final dischargeRate = _calculateDischargeRate(dataPoints);
    final chargeRate = _calculateChargeRate(dataPoints);

    // 데이터 품질 계산
    final dataQuality = _calculateDataQuality(dataPoints);

    return {
      'averageLevel': avgLevel,
      'minLevel': minLevel,
      'maxLevel': maxLevel,
      'variation': variation,
      'averageTemperature': avgTemperature,
      'averageVoltage': avgVoltage,
      'averageDischargeRate': dischargeRate,
      'averageChargeRate': chargeRate,
      'overallDataQuality': dataQuality,
    };
  }

  /// 사용 패턴 분석
  static Map<String, dynamic> _analyzeUsagePatterns(
    List<BatteryHistoryDataPoint> dataPoints,
    DateTime startTime,
    DateTime endTime,
  ) {
    // 시간대별 사용 패턴 분석
    final hourlyPatterns = _analyzeHourlyPatterns(dataPoints);
    
    // 요일별 사용 패턴 분석
    final dailyPatterns = _analyzeDailyPatterns(dataPoints);
    
    // 배터리 레벨 구간별 분석
    final levelSegments = _analyzeLevelSegments(dataPoints);
    
    // 사용 강도 분석
    final usageIntensity = _analyzeUsageIntensity(dataPoints);
    
    // 패턴 요약 생성
    final summary = _generatePatternSummary(
      hourlyPatterns,
      dailyPatterns,
      levelSegments,
      usageIntensity,
    );

    return {
      'hourlyPatterns': hourlyPatterns,
      'dailyPatterns': dailyPatterns,
      'levelSegments': levelSegments,
      'usageIntensity': usageIntensity,
      'summary': summary,
    };
  }

  /// 시간대별 사용 패턴 분석
  static Map<String, dynamic> _analyzeHourlyPatterns(
    List<BatteryHistoryDataPoint> dataPoints,
  ) {
    final hourlyData = <int, List<double>>{};
    
    for (final dataPoint in dataPoints) {
      final hour = dataPoint.timestamp.hour;
      hourlyData.putIfAbsent(hour, () => []).add(dataPoint.level);
    }

    final hourlyStats = <int, Map<String, double>>{};
    for (final entry in hourlyData.entries) {
      final hour = entry.key;
      final levels = entry.value;
      
      hourlyStats[hour] = {
        'average': levels.reduce((a, b) => a + b) / levels.length,
        'min': levels.reduce((a, b) => a < b ? a : b),
        'max': levels.reduce((a, b) => a > b ? a : b),
        'count': levels.length.toDouble(),
      };
    }

    // 가장 활발한 시간대 찾기
    final mostActiveHour = hourlyStats.entries
        .reduce((a, b) => a.value['count']! > b.value['count']! ? a : b)
        .key;

    return {
      'hourlyStats': hourlyStats,
      'mostActiveHour': mostActiveHour,
      'peakUsageHour': mostActiveHour,
    };
  }

  /// 요일별 사용 패턴 분석
  static Map<String, dynamic> _analyzeDailyPatterns(
    List<BatteryHistoryDataPoint> dataPoints,
  ) {
    final dailyData = <int, List<double>>{};
    
    for (final dataPoint in dataPoints) {
      final weekday = dataPoint.timestamp.weekday;
      dailyData.putIfAbsent(weekday, () => []).add(dataPoint.level);
    }

    final dailyStats = <int, Map<String, double>>{};
    for (final entry in dailyData.entries) {
      final weekday = entry.key;
      final levels = entry.value;
      
      dailyStats[weekday] = {
        'average': levels.reduce((a, b) => a + b) / levels.length,
        'min': levels.reduce((a, b) => a < b ? a : b),
        'max': levels.reduce((a, b) => a > b ? a : b),
        'count': levels.length.toDouble(),
      };
    }

    return {
      'dailyStats': dailyStats,
      'weekdayPattern': dailyStats,
    };
  }

  /// 배터리 레벨 구간별 분석
  static Map<String, dynamic> _analyzeLevelSegments(
    List<BatteryHistoryDataPoint> dataPoints,
  ) {
    final segments = {
      'critical': <BatteryHistoryDataPoint>[], // 0-20%
      'low': <BatteryHistoryDataPoint>[],      // 21-40%
      'medium': <BatteryHistoryDataPoint>[],  // 41-70%
      'high': <BatteryHistoryDataPoint>[],    // 71-100%
    };

    for (final dataPoint in dataPoints) {
      if (dataPoint.level <= 20) {
        segments['critical']!.add(dataPoint);
      } else if (dataPoint.level <= 40) {
        segments['low']!.add(dataPoint);
      } else if (dataPoint.level <= 70) {
        segments['medium']!.add(dataPoint);
      } else {
        segments['high']!.add(dataPoint);
      }
    }

    final segmentStats = <String, Map<String, double>>{};
    for (final entry in segments.entries) {
      final segmentName = entry.key;
      final segmentData = entry.value;
      
      if (segmentData.isNotEmpty) {
        final levels = segmentData.map((d) => d.level).toList();
        segmentStats[segmentName] = {
          'count': segmentData.length.toDouble(),
          'percentage': (segmentData.length / dataPoints.length) * 100,
          'average': levels.reduce((a, b) => a + b) / levels.length,
          'duration': _calculateSegmentDuration(segmentData),
        };
      }
    }

    return {
      'segments': segments,
      'segmentStats': segmentStats,
    };
  }

  /// 사용 강도 분석
  static Map<String, dynamic> _analyzeUsageIntensity(
    List<BatteryHistoryDataPoint> dataPoints,
  ) {
    if (dataPoints.length < 2) {
      return {
        'intensity': 'low',
        'variation': 0.0,
        'stability': 1.0,
      };
    }

    // 배터리 레벨 변화율 계산
    final changes = <double>[];
    for (int i = 1; i < dataPoints.length; i++) {
      final prev = dataPoints[i - 1];
      final curr = dataPoints[i];
      final timeDiff = curr.timestamp.difference(prev.timestamp).inMinutes;
      
      if (timeDiff > 0) {
        final levelChange = curr.level - prev.level;
        final rate = levelChange / timeDiff; // 분당 변화율
        changes.add(rate.abs());
      }
    }

    if (changes.isEmpty) {
      return {
        'intensity': 'low',
        'variation': 0.0,
        'stability': 1.0,
      };
    }

    final avgChange = changes.reduce((a, b) => a + b) / changes.length;
    final maxChange = changes.reduce((a, b) => a > b ? a : b);
    final variation = changes.map((c) => pow(c - avgChange, 2)).reduce((a, b) => a + b) / changes.length;

    String intensity;
    if (avgChange > 2.0) {
      intensity = 'high';
    } else if (avgChange > 1.0) {
      intensity = 'medium';
    } else {
      intensity = 'low';
    }

    return {
      'intensity': intensity,
      'variation': variation,
      'stability': 1.0 / (1.0 + variation),
      'averageChange': avgChange,
      'maxChange': maxChange,
    };
  }

  /// 충전 이벤트 분석
  static List<String> _analyzeChargingEvents(
    List<BatteryHistoryDataPoint> dataPoints,
  ) {
    final events = <String>[];
    bool wasCharging = false;
    DateTime? chargingStartTime;
    double? chargingStartLevel;

    for (final dataPoint in dataPoints) {
      final isCharging = dataPoint.state == BatteryState.charging;

      if (isCharging && !wasCharging) {
        // 충전 시작
        chargingStartTime = dataPoint.timestamp;
        chargingStartLevel = dataPoint.level;
      } else if (!isCharging && wasCharging && chargingStartTime != null) {
        // 충전 종료
        final chargingDuration = dataPoint.timestamp.difference(chargingStartTime);
        final levelIncrease = dataPoint.level - (chargingStartLevel ?? 0);
        
        events.add(
          '충전 세션: ${chargingStartTime.hour.toString().padLeft(2, '0')}:${chargingStartTime.minute.toString().padLeft(2, '0')} - '
          '${dataPoint.timestamp.hour.toString().padLeft(2, '0')}:${dataPoint.timestamp.minute.toString().padLeft(2, '0')} '
          '(${chargingDuration.inMinutes}분, +${levelIncrease.toStringAsFixed(1)}%)',
        );
        
        chargingStartTime = null;
        chargingStartLevel = null;
      }

      wasCharging = isCharging;
    }

    return events;
  }

  /// 방전 이벤트 분석
  static List<String> _analyzeDischargingEvents(
    List<BatteryHistoryDataPoint> dataPoints,
  ) {
    final events = <String>[];
    bool wasDischarging = false;
    DateTime? dischargingStartTime;
    double? dischargingStartLevel;

    for (final dataPoint in dataPoints) {
      final isDischarging = dataPoint.state == BatteryState.discharging;

      if (isDischarging && !wasDischarging) {
        // 방전 시작
        dischargingStartTime = dataPoint.timestamp;
        dischargingStartLevel = dataPoint.level;
      } else if (!isDischarging && wasDischarging && dischargingStartTime != null) {
        // 방전 종료
        final dischargingDuration = dataPoint.timestamp.difference(dischargingStartTime);
        final levelDecrease = (dischargingStartLevel ?? 0) - dataPoint.level;
        
        events.add(
          '방전 세션: ${dischargingStartTime.hour.toString().padLeft(2, '0')}:${dischargingStartTime.minute.toString().padLeft(2, '0')} - '
          '${dataPoint.timestamp.hour.toString().padLeft(2, '0')}:${dataPoint.timestamp.minute.toString().padLeft(2, '0')} '
          '(${dischargingDuration.inMinutes}분, -${levelDecrease.toStringAsFixed(1)}%)',
        );
        
        dischargingStartTime = null;
        dischargingStartLevel = null;
      }

      wasDischarging = isDischarging;
    }

    return events;
  }

  /// 효율성 분석
  static Map<String, dynamic> _analyzeEfficiency(
    List<BatteryHistoryDataPoint> dataPoints,
    Map<String, dynamic> patternAnalysis,
  ) {
    final basicStats = _calculateBasicStatistics(dataPoints);
    final usageIntensity = patternAnalysis['usageIntensity'] as Map<String, dynamic>;
    
    // 효율성 점수 계산
    double efficiencyScore = 100.0;
    
    // 평균 배터리 레벨이 낮으면 감점
    if (basicStats['averageLevel']! < 30) {
      efficiencyScore -= 20;
    } else if (basicStats['averageLevel']! < 50) {
      efficiencyScore -= 10;
    }
    
    // 배터리 변동폭이 크면 감점
    if (basicStats['variation']! > 80) {
      efficiencyScore -= 15;
    } else if (basicStats['variation']! > 60) {
      efficiencyScore -= 10;
    }
    
    // 방전 속도가 빠르면 감점
    if (basicStats['averageDischargeRate']! > 5) {
      efficiencyScore -= 15;
    } else if (basicStats['averageDischargeRate']! > 3) {
      efficiencyScore -= 10;
    }
    
    // 사용 강도가 높으면 감점
    if (usageIntensity['intensity'] == 'high') {
      efficiencyScore -= 10;
    } else if (usageIntensity['intensity'] == 'medium') {
      efficiencyScore -= 5;
    }
    
    // 데이터 품질이 낮으면 감점
    if (basicStats['overallDataQuality']! < 0.7) {
      efficiencyScore -= 10;
    }
    
    efficiencyScore = efficiencyScore.clamp(0.0, 100.0);
    
    // 효율성 등급 결정
    String efficiencyGrade;
    if (efficiencyScore >= 90) {
      efficiencyGrade = 'A+';
    } else if (efficiencyScore >= 80) {
      efficiencyGrade = 'A';
    } else if (efficiencyScore >= 70) {
      efficiencyGrade = 'B';
    } else if (efficiencyScore >= 60) {
      efficiencyGrade = 'C';
    } else if (efficiencyScore >= 50) {
      efficiencyGrade = 'D';
    } else {
      efficiencyGrade = 'F';
    }

    return {
      'score': efficiencyScore,
      'grade': efficiencyGrade,
      'factors': {
        'averageLevel': basicStats['averageLevel']!,
        'variation': basicStats['variation']!,
        'dischargeRate': basicStats['averageDischargeRate']!,
        'usageIntensity': usageIntensity['intensity'],
        'dataQuality': basicStats['overallDataQuality']!,
      },
    };
  }

  /// 방전 속도 계산
  static double _calculateDischargeRate(
    List<BatteryHistoryDataPoint> dataPoints,
  ) {
    if (dataPoints.length < 2) return 0.0;

    final dischargePoints = <Map<String, double>>[];
    
    for (int i = 1; i < dataPoints.length; i++) {
      final prev = dataPoints[i - 1];
      final curr = dataPoints[i];
      
      if (prev.state == BatteryState.discharging && 
          curr.state == BatteryState.discharging) {
        final timeDiff = curr.timestamp.difference(prev.timestamp).inMinutes;
        final levelDiff = prev.level - curr.level;
        
        if (timeDiff > 0 && levelDiff > 0) {
          dischargePoints.add({
            'rate': levelDiff / timeDiff,
            'time': timeDiff.toDouble(),
          });
        }
      }
    }

    if (dischargePoints.isEmpty) return 0.0;

    final totalTime = dischargePoints.map((p) => p['time']!).reduce((a, b) => a + b);
    final weightedRate = dischargePoints
        .map((p) => p['rate']! * p['time']!)
        .reduce((a, b) => a + b) / totalTime;

    return weightedRate;
  }

  /// 충전 속도 계산
  static double _calculateChargeRate(
    List<BatteryHistoryDataPoint> dataPoints,
  ) {
    if (dataPoints.length < 2) return 0.0;

    final chargePoints = <Map<String, double>>[];
    
    for (int i = 1; i < dataPoints.length; i++) {
      final prev = dataPoints[i - 1];
      final curr = dataPoints[i];
      
      if (prev.state == BatteryState.charging && 
          curr.state == BatteryState.charging) {
        final timeDiff = curr.timestamp.difference(prev.timestamp).inMinutes;
        final levelDiff = curr.level - prev.level;
        
        if (timeDiff > 0 && levelDiff > 0) {
          chargePoints.add({
            'rate': levelDiff / timeDiff,
            'time': timeDiff.toDouble(),
          });
        }
      }
    }

    if (chargePoints.isEmpty) return 0.0;

    final totalTime = chargePoints.map((p) => p['time']!).reduce((a, b) => a + b);
    final weightedRate = chargePoints
        .map((p) => p['rate']! * p['time']!)
        .reduce((a, b) => a + b) / totalTime;

    return weightedRate;
  }

  /// 데이터 품질 계산
  static double _calculateDataQuality(
    List<BatteryHistoryDataPoint> dataPoints,
  ) {
    if (dataPoints.isEmpty) return 0.0;

    double qualityScore = 0.0;

    // 온도 데이터 품질
    final temperatureData = dataPoints.where((d) => d.hasTemperature).length;
    qualityScore += (temperatureData / dataPoints.length) * 0.3;

    // 전압 데이터 품질
    final voltageData = dataPoints.where((d) => d.hasVoltage).length;
    qualityScore += (voltageData / dataPoints.length) * 0.3;

    // 데이터 연속성 품질
    final continuityScore = _calculateContinuityScore(dataPoints);
    qualityScore += continuityScore * 0.4;

    return qualityScore;
  }

  /// 데이터 연속성 점수 계산
  static double _calculateContinuityScore(
    List<BatteryHistoryDataPoint> dataPoints,
  ) {
    if (dataPoints.length < 2) return 1.0;

    int gaps = 0;
    for (int i = 1; i < dataPoints.length; i++) {
      final timeDiff = dataPoints[i].timestamp.difference(dataPoints[i - 1].timestamp);
      if (timeDiff.inMinutes > 30) { // 30분 이상 간격이면 갭으로 간주
        gaps++;
      }
    }

    return (dataPoints.length - gaps) / dataPoints.length;
  }

  /// 구간별 지속 시간 계산
  static double _calculateSegmentDuration(
    List<BatteryHistoryDataPoint> segmentData,
  ) {
    if (segmentData.length < 2) return 0.0;

    final startTime = segmentData.first.timestamp;
    final endTime = segmentData.last.timestamp;
    return endTime.difference(startTime).inMinutes.toDouble();
  }

  /// 패턴 요약 생성
  static String _generatePatternSummary(
    Map<String, dynamic> hourlyPatterns,
    Map<String, dynamic> dailyPatterns,
    Map<String, dynamic> levelSegments,
    Map<String, dynamic> usageIntensity,
  ) {
    final mostActiveHour = hourlyPatterns['mostActiveHour'] as int;
    final intensity = usageIntensity['intensity'] as String;
    final segmentStats = levelSegments['segmentStats'] as Map<String, Map<String, double>>;

    String summary = '사용 패턴 분석 결과:\n';
    summary += '• 가장 활발한 시간대: $mostActiveHour시\n';
    summary += '• 사용 강도: ${intensity == 'high' ? '높음' : intensity == 'medium' ? '보통' : '낮음'}\n';
    
    if (segmentStats.containsKey('critical')) {
      final criticalPercentage = segmentStats['critical']!['percentage']!;
      if (criticalPercentage > 10) {
        summary += '• 위험 구간(20% 이하) 사용률: ${criticalPercentage.toStringAsFixed(1)}%\n';
      }
    }
    
    if (segmentStats.containsKey('high')) {
      final highPercentage = segmentStats['high']!['percentage']!;
      if (highPercentage > 30) {
        summary += '• 고용량 구간(70% 이상) 사용률: ${highPercentage.toStringAsFixed(1)}%\n';
      }
    }

    return summary;
  }

  /// 인사이트 생성
  static List<String> _generateInsights(
    Map<String, double> basicStats,
    Map<String, dynamic> patternAnalysis,
    List<String> chargingEvents,
    List<String> dischargingEvents,
    Map<String, dynamic> efficiencyAnalysis,
  ) {
    final insights = <String>[];

    // 배터리 레벨 인사이트
    if (basicStats['averageLevel']! < 30) {
      insights.add('평균 배터리 레벨이 낮습니다 (${basicStats['averageLevel']!.toStringAsFixed(1)}%). 충전 습관을 개선해보세요.');
    } else if (basicStats['averageLevel']! > 80) {
      insights.add('평균 배터리 레벨이 높습니다 (${basicStats['averageLevel']!.toStringAsFixed(1)}%). 배터리 건강을 위해 적절한 방전도 필요합니다.');
    }

    // 변동폭 인사이트
    if (basicStats['variation']! > 80) {
      insights.add('배터리 레벨 변동이 심합니다 (${basicStats['variation']!.toStringAsFixed(1)}%). 사용 패턴을 안정화해보세요.');
    }

    // 방전 속도 인사이트
    if (basicStats['averageDischargeRate']! > 5) {
      insights.add('배터리 방전 속도가 빠릅니다 (${basicStats['averageDischargeRate']!.toStringAsFixed(1)}%/분). 배터리 소모가 많은 앱을 확인해보세요.');
    }

    // 충전 패턴 인사이트
    if (chargingEvents.length > 5) {
      insights.add('충전 빈도가 높습니다 (${chargingEvents.length}회). 충전 습관을 개선하면 배터리 수명을 연장할 수 있습니다.');
    }

    // 효율성 인사이트
    final efficiencyGrade = efficiencyAnalysis['grade'] as String;
    if (efficiencyGrade == 'A+' || efficiencyGrade == 'A') {
      insights.add('배터리 사용 효율성이 우수합니다! 현재 사용 패턴을 유지하세요.');
    } else if (efficiencyGrade == 'F' || efficiencyGrade == 'D') {
      insights.add('배터리 사용 효율성이 낮습니다. 사용 패턴을 개선할 필요가 있습니다.');
    }

    return insights;
  }

  /// 추천사항 생성
  static List<String> _generateRecommendations(
    Map<String, double> basicStats,
    Map<String, dynamic> patternAnalysis,
    List<String> chargingEvents,
    List<String> dischargingEvents,
    Map<String, dynamic> efficiencyAnalysis,
  ) {
    final recommendations = <String>[];

    // 배터리 레벨 기반 추천
    if (basicStats['averageLevel']! < 30) {
      recommendations.add('배터리 레벨을 20% 이하로 떨어뜨리지 않도록 주의하세요.');
      recommendations.add('정기적인 충전 습관을 만들어보세요.');
    }

    // 변동폭 기반 추천
    if (basicStats['variation']! > 80) {
      recommendations.add('배터리 레벨을 20-80% 범위에서 유지하세요.');
      recommendations.add('급격한 방전을 피하고 안정적인 사용 패턴을 만들어보세요.');
    }

    // 방전 속도 기반 추천
    if (basicStats['averageDischargeRate']! > 5) {
      recommendations.add('배터리 소모가 많은 앱을 확인하고 최적화하세요.');
      recommendations.add('화면 밝기를 조절하고 불필요한 백그라운드 앱을 종료하세요.');
    }

    // 충전 패턴 기반 추천
    if (chargingEvents.length > 5) {
      recommendations.add('충전 빈도를 줄이고 한 번에 충분히 충전하세요.');
      recommendations.add('과충전을 피하고 80-90%에서 충전을 중단하는 것을 고려해보세요.');
    }

    // 온도 기반 추천
    if (basicStats['averageTemperature']! > 40) {
      recommendations.add('배터리 온도가 높습니다. 케이스를 제거하거나 통풍이 잘 되는 곳에서 사용하세요.');
    }

    // 효율성 기반 추천
    final efficiencyGrade = efficiencyAnalysis['grade'] as String;
    if (efficiencyGrade == 'F' || efficiencyGrade == 'D') {
      recommendations.add('배터리 최적화 설정을 활성화하세요.');
      recommendations.add('불필요한 위치 서비스와 백그라운드 새로고침을 비활성화하세요.');
    }

    return recommendations;
  }

  /// 평균 충전 세션 시간 계산
  static double _calculateAverageChargingSessionMinutes(List<String> chargingEvents) {
    if (chargingEvents.isEmpty) return 0.0;
    
    // 충전 이벤트에서 시간 정보 추출 (간단한 구현)
    // 실제로는 더 정교한 파싱이 필요할 수 있음
    return 30.0; // 기본값
  }
}
