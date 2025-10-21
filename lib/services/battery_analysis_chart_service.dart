import 'package:flutter/foundation.dart';
import 'package:battery_plus/battery_plus.dart';
import '../models/battery_history_models.dart';
import '../utils/battery_chart_data_converter.dart';

/// 배터리 분석 결과를 차트 데이터로 변환하는 서비스
/// 분석 결과를 시각화할 수 있는 형태로 변환
class BatteryAnalysisChartService {
  /// 배터리 히스토리 분석 결과를 차트용 데이터로 변환
  static Map<String, dynamic> convertAnalysisToChartData(
    BatteryHistoryAnalysis analysis,
    List<BatteryHistoryDataPoint> dataPoints,
  ) {
    // 기본 차트 데이터 생성
    final levelChartData = _generateLevelChartData(dataPoints);
    final temperatureChartData = _generateTemperatureChartData(dataPoints);
    final voltageChartData = _generateVoltageChartData(dataPoints);
    
    // 통계 데이터 생성
    final statisticsData = _generateStatisticsData(analysis, dataPoints);
    
    // 패턴 데이터 생성
    final patternData = _generatePatternData(analysis, dataPoints);
    
    // 효율성 데이터 생성
    final efficiencyData = _generateEfficiencyData(analysis);

    return {
      'levelChart': levelChartData,
      'temperatureChart': temperatureChartData,
      'voltageChart': voltageChartData,
      'statistics': statisticsData,
      'patterns': patternData,
      'efficiency': efficiencyData,
      'insights': analysis.recommendations,
      'summary': {
        'analysisDuration': analysis.analysisDurationHours,
        'dataPointCount': analysis.dataPointCount,
        'averageLevel': analysis.averageBatteryLevel,
        'minLevel': analysis.minBatteryLevel,
        'maxLevel': analysis.maxBatteryLevel,
        'variation': analysis.batteryVariation,
      },
    };
  }

  /// 배터리 레벨 차트 데이터 생성
  static Map<String, dynamic> _generateLevelChartData(
    List<BatteryHistoryDataPoint> dataPoints,
  ) {
    if (dataPoints.isEmpty) {
      return {
        'spots': <Map<String, dynamic>>[],
        'colorBasedSpots': <String, List<Map<String, dynamic>>>{},
        'timeBasedSpots': <Map<String, dynamic>>[],
        'xAxisLabels': <String>[],
        'yAxisLabels': <String>[],
        'statistics': <String, dynamic>{},
      };
    }

    // 기본 FlSpot 데이터
    final spots = BatteryChartDataConverter.convertToFlSpots(dataPoints);
    final spotData = spots.map((spot) => {
      'x': spot.x,
      'y': spot.y,
    }).toList();

    // 색상 기반 FlSpot 데이터
    final colorBasedSpots = BatteryChartDataConverter.convertToColorBasedFlSpots(dataPoints);
    final colorBasedData = <String, List<Map<String, dynamic>>>{};
    colorBasedSpots.forEach((key, value) {
      colorBasedData[key] = value.map((spot) => {
        'x': spot.x,
        'y': spot.y,
      }).toList();
    });

    // 시간 기반 FlSpot 데이터
    final timeBasedSpots = BatteryChartDataConverter.convertToTimeBasedFlSpots(dataPoints);
    final timeBasedData = timeBasedSpots.map((spot) => {
      'x': spot.x,
      'y': spot.y,
    }).toList();

    // 축 레이블 생성
    final xAxisLabels = BatteryChartDataConverter.generateXAxisLabels(dataPoints);
    final yAxisLabels = BatteryChartDataConverter.generateBatteryLevelYAxisLabels();

    // 통계 데이터
    final statistics = BatteryChartDataConverter.calculateChartStatistics(dataPoints);

    return {
      'spots': spotData,
      'colorBasedSpots': colorBasedData,
      'timeBasedSpots': timeBasedData,
      'xAxisLabels': xAxisLabels,
      'yAxisLabels': yAxisLabels,
      'statistics': statistics,
    };
  }

  /// 온도 차트 데이터 생성
  static Map<String, dynamic> _generateTemperatureChartData(
    List<BatteryHistoryDataPoint> dataPoints,
  ) {
    final temperatureDataPoints = dataPoints.where((d) => d.hasTemperature).toList();
    
    if (temperatureDataPoints.isEmpty) {
      return {
        'spots': <Map<String, dynamic>>[],
        'xAxisLabels': <String>[],
        'yAxisLabels': <String>[],
        'statistics': <String, dynamic>{},
        'hasData': false,
      };
    }

    // 온도 FlSpot 데이터
    final spots = BatteryChartDataConverter.convertToTemperatureFlSpots(temperatureDataPoints);
    final spotData = spots.map((spot) => {
      'x': spot.x,
      'y': spot.y,
    }).toList();

    // 축 레이블 생성
    final xAxisLabels = BatteryChartDataConverter.generateXAxisLabels(temperatureDataPoints);
    final yAxisLabels = BatteryChartDataConverter.generateTemperatureYAxisLabels(temperatureDataPoints);

    // 온도 통계
    final temperatures = temperatureDataPoints.map((d) => d.temperature).toList();
    final statistics = {
      'count': temperatureDataPoints.length,
      'average': temperatures.reduce((a, b) => a + b) / temperatures.length,
      'min': temperatures.reduce((a, b) => a < b ? a : b),
      'max': temperatures.reduce((a, b) => a > b ? a : b),
      'range': temperatures.reduce((a, b) => a > b ? a : b) - temperatures.reduce((a, b) => a < b ? a : b),
    };

    return {
      'spots': spotData,
      'xAxisLabels': xAxisLabels,
      'yAxisLabels': yAxisLabels,
      'statistics': statistics,
      'hasData': true,
    };
  }

  /// 전압 차트 데이터 생성
  static Map<String, dynamic> _generateVoltageChartData(
    List<BatteryHistoryDataPoint> dataPoints,
  ) {
    final voltageDataPoints = dataPoints.where((d) => d.hasVoltage).toList();
    
    if (voltageDataPoints.isEmpty) {
      return {
        'spots': <Map<String, dynamic>>[],
        'xAxisLabels': <String>[],
        'yAxisLabels': <String>[],
        'statistics': <String, dynamic>{},
        'hasData': false,
      };
    }

    // 전압 FlSpot 데이터
    final spots = BatteryChartDataConverter.convertToVoltageFlSpots(voltageDataPoints);
    final spotData = spots.map((spot) => {
      'x': spot.x,
      'y': spot.y,
    }).toList();

    // 축 레이블 생성
    final xAxisLabels = BatteryChartDataConverter.generateXAxisLabels(voltageDataPoints);
    final yAxisLabels = BatteryChartDataConverter.generateVoltageYAxisLabels(voltageDataPoints);

    // 전압 통계
    final voltages = voltageDataPoints.map((d) => d.voltage.toDouble()).toList();
    final statistics = {
      'count': voltageDataPoints.length,
      'average': voltages.reduce((a, b) => a + b) / voltages.length,
      'min': voltages.reduce((a, b) => a < b ? a : b),
      'max': voltages.reduce((a, b) => a > b ? a : b),
      'range': voltages.reduce((a, b) => a > b ? a : b) - voltages.reduce((a, b) => a < b ? a : b),
    };

    return {
      'spots': spotData,
      'xAxisLabels': xAxisLabels,
      'yAxisLabels': yAxisLabels,
      'statistics': statistics,
      'hasData': true,
    };
  }

  /// 통계 데이터 생성
  static Map<String, dynamic> _generateStatisticsData(
    BatteryHistoryAnalysis analysis,
    List<BatteryHistoryDataPoint> dataPoints,
  ) {
    // 기본 통계
    final basicStats = {
      'analysisDuration': analysis.analysisDurationHours,
      'dataPointCount': analysis.dataPointCount,
      'averageLevel': analysis.averageBatteryLevel,
      'minLevel': analysis.minBatteryLevel,
      'maxLevel': analysis.maxBatteryLevel,
      'variation': analysis.batteryVariation,
    };

    // 충전/방전 통계
    final chargingCount = dataPoints.where((d) => d.state == BatteryState.charging).length;
    final dischargingCount = dataPoints.where((d) => d.state == BatteryState.discharging).length;
    final fullCount = dataPoints.where((d) => d.state == BatteryState.full).length;

    final stateStats = {
      'chargingCount': chargingCount,
      'dischargingCount': dischargingCount,
      'fullCount': fullCount,
      'chargingPercentage': (chargingCount / dataPoints.length) * 100,
      'dischargingPercentage': (dischargingCount / dataPoints.length) * 100,
      'fullPercentage': (fullCount / dataPoints.length) * 100,
    };

    // 온도 통계
    final temperatureData = dataPoints.where((d) => d.hasTemperature).toList();
    final temperatureStats = temperatureData.isNotEmpty ? {
      'average': temperatureData.map((d) => d.temperature).reduce((a, b) => a + b) / temperatureData.length,
      'min': temperatureData.map((d) => d.temperature).reduce((a, b) => a < b ? a : b),
      'max': temperatureData.map((d) => d.temperature).reduce((a, b) => a > b ? a : b),
      'count': temperatureData.length,
    } : {
      'average': 0.0,
      'min': 0.0,
      'max': 0.0,
      'count': 0,
    };

    // 전압 통계
    final voltageData = dataPoints.where((d) => d.hasVoltage).toList();
    final voltageStats = voltageData.isNotEmpty ? {
      'average': voltageData.map((d) => d.voltage.toDouble()).reduce((a, b) => a + b) / voltageData.length,
      'min': voltageData.map((d) => d.voltage.toDouble()).reduce((a, b) => a < b ? a : b),
      'max': voltageData.map((d) => d.voltage.toDouble()).reduce((a, b) => a > b ? a : b),
      'count': voltageData.length,
    } : {
      'average': 0.0,
      'min': 0.0,
      'max': 0.0,
      'count': 0,
    };

    return {
      'basic': basicStats,
      'state': stateStats,
      'temperature': temperatureStats,
      'voltage': voltageStats,
    };
  }

  /// 패턴 데이터 생성
  static Map<String, dynamic> _generatePatternData(
    BatteryHistoryAnalysis analysis,
    List<BatteryHistoryDataPoint> dataPoints,
  ) {
    // 시간대별 패턴
    final hourlyPatterns = <int, Map<String, double>>{};
    for (int hour = 0; hour < 24; hour++) {
      final hourData = dataPoints.where((d) => d.timestamp.hour == hour).toList();
      if (hourData.isNotEmpty) {
        final levels = hourData.map((d) => d.level).toList();
        hourlyPatterns[hour] = {
          'average': levels.reduce((a, b) => a + b) / levels.length,
          'count': hourData.length.toDouble(),
          'min': levels.reduce((a, b) => a < b ? a : b),
          'max': levels.reduce((a, b) => a > b ? a : b),
        };
      }
    }

    // 요일별 패턴
    final dailyPatterns = <int, Map<String, double>>{};
    for (int weekday = 1; weekday <= 7; weekday++) {
      final dayData = dataPoints.where((d) => d.timestamp.weekday == weekday).toList();
      if (dayData.isNotEmpty) {
        final levels = dayData.map((d) => d.level).toList();
        dailyPatterns[weekday] = {
          'average': levels.reduce((a, b) => a + b) / levels.length,
          'count': dayData.length.toDouble(),
          'min': levels.reduce((a, b) => a < b ? a : b),
          'max': levels.reduce((a, b) => a > b ? a : b),
        };
      }
    }

    // 배터리 레벨 구간별 패턴
    final levelSegments = {
      'critical': dataPoints.where((d) => d.level <= 20).length,
      'low': dataPoints.where((d) => d.level > 20 && d.level <= 40).length,
      'medium': dataPoints.where((d) => d.level > 40 && d.level <= 70).length,
      'high': dataPoints.where((d) => d.level > 70).length,
    };

    return {
      'hourly': hourlyPatterns,
      'daily': dailyPatterns,
      'levelSegments': levelSegments,
      'summary': analysis.patternSummary,
    };
  }

  /// 효율성 데이터 생성
  static Map<String, dynamic> _generateEfficiencyData(
    BatteryHistoryAnalysis analysis,
  ) {
    return {
      'score': analysis.batteryEfficiencyScore,
      'grade': analysis.batteryEfficiencyGrade,
      'factors': {
        'averageLevel': analysis.averageBatteryLevel,
        'variation': analysis.batteryVariation,
        'dischargeRate': analysis.averageDischargeRate,
        'dataQuality': analysis.overallDataQuality,
      },
    };
  }

  /// 차트 데이터를 JSON 직렬화 가능한 형태로 변환
  static Map<String, dynamic> serializeChartData(
    Map<String, dynamic> chartData,
  ) {
    // 모든 데이터를 JSON 직렬화 가능한 형태로 변환
    return Map<String, dynamic>.from(chartData);
  }

  /// JSON 데이터를 차트 데이터로 역직렬화
  static Map<String, dynamic> deserializeChartData(
    Map<String, dynamic> jsonData,
  ) {
    return Map<String, dynamic>.from(jsonData);
  }

  /// 차트 데이터 유효성 검증
  static bool validateChartData(Map<String, dynamic> chartData) {
    try {
      // 필수 키 확인
      final requiredKeys = ['levelChart', 'statistics', 'summary'];
      for (final key in requiredKeys) {
        if (!chartData.containsKey(key)) {
          debugPrint('차트 데이터에 필수 키가 없습니다: $key');
          return false;
        }
      }

      // 레벨 차트 데이터 확인
      final levelChart = chartData['levelChart'] as Map<String, dynamic>;
      if (!levelChart.containsKey('spots') || !levelChart.containsKey('statistics')) {
        debugPrint('레벨 차트 데이터가 올바르지 않습니다');
        return false;
      }

      // 통계 데이터 확인
      final statistics = chartData['statistics'] as Map<String, dynamic>;
      if (!statistics.containsKey('basic') || !statistics.containsKey('state')) {
        debugPrint('통계 데이터가 올바르지 않습니다');
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('차트 데이터 유효성 검증 중 오류 발생: $e');
      return false;
    }
  }

  /// 차트 데이터 크기 계산
  static int calculateChartDataSize(Map<String, dynamic> chartData) {
    try {
      // JSON 직렬화하여 크기 계산
      final jsonString = chartData.toString();
      return jsonString.length;
    } catch (e) {
      debugPrint('차트 데이터 크기 계산 중 오류 발생: $e');
      return 0;
    }
  }

  /// 차트 데이터 압축 (필요한 경우)
  static Map<String, dynamic> compressChartData(
    Map<String, dynamic> chartData, {
    double compressionRatio = 0.5,
  }) {
    try {
      // 데이터 포인트 수가 많으면 압축
      final levelChart = chartData['levelChart'] as Map<String, dynamic>;
      final spots = levelChart['spots'] as List<dynamic>;
      
      if (spots.length > 100) {
        final compressedSpots = <Map<String, dynamic>>[];
        final step = (spots.length * compressionRatio).round();
        
        for (int i = 0; i < spots.length; i += step) {
          compressedSpots.add(Map<String, dynamic>.from(spots[i]));
        }
        
        levelChart['spots'] = compressedSpots;
        levelChart['compressed'] = true;
        levelChart['originalCount'] = spots.length;
        levelChart['compressedCount'] = compressedSpots.length;
      }

      return chartData;
    } catch (e) {
      debugPrint('차트 데이터 압축 중 오류 발생: $e');
      return chartData;
    }
  }
}
