import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:battery_plus/battery_plus.dart';
import '../models/battery_history_models.dart';

/// 배터리 차트 데이터 변환 유틸리티
/// 히스토리 데이터를 차트에 표시할 수 있는 형태로 변환
class BatteryChartDataConverter {
  /// 배터리 히스토리 데이터를 FlSpot 리스트로 변환
  static List<FlSpot> convertToFlSpots(List<BatteryHistoryDataPoint> dataPoints) {
    return dataPoints.asMap().entries.map((entry) {
      final index = entry.key;
      final dataPoint = entry.value;
      
      return FlSpot(
        index.toDouble(),
        dataPoint.level,
      );
    }).toList();
  }

  /// 배터리 히스토리 데이터를 시간 기반 FlSpot 리스트로 변환
  static List<FlSpot> convertToTimeBasedFlSpots(
    List<BatteryHistoryDataPoint> dataPoints, {
    DateTime? startTime,
    DateTime? endTime,
  }) {
    if (dataPoints.isEmpty) return [];
    
    final actualStartTime = startTime ?? dataPoints.first.timestamp;
    final actualEndTime = endTime ?? dataPoints.last.timestamp;
    final totalDuration = actualEndTime.difference(actualStartTime).inMilliseconds;
    
    return dataPoints.map((dataPoint) {
      final timeOffset = dataPoint.timestamp.difference(actualStartTime).inMilliseconds;
      final x = totalDuration > 0 ? (timeOffset / totalDuration) * 100 : 0.0;
      
      return FlSpot(x, dataPoint.level);
    }).toList();
  }

  /// 배터리 히스토리 데이터를 색상별 FlSpot 리스트로 변환 (충전/방전 구분)
  static Map<String, List<FlSpot>> convertToColorBasedFlSpots(
    List<BatteryHistoryDataPoint> dataPoints,
  ) {
    final chargingSpots = <FlSpot>[];
    final dischargingSpots = <FlSpot>[];
    final fullSpots = <FlSpot>[];
    
    dataPoints.asMap().entries.forEach((entry) {
      final index = entry.key;
      final dataPoint = entry.value;
      final spot = FlSpot(index.toDouble(), dataPoint.level);
      
      switch (dataPoint.state) {
        case BatteryState.charging:
          chargingSpots.add(spot);
          break;
        case BatteryState.discharging:
          dischargingSpots.add(spot);
          break;
        case BatteryState.full:
          fullSpots.add(spot);
          break;
        default:
          dischargingSpots.add(spot);
      }
    });
    
    return {
      'charging': chargingSpots,
      'discharging': dischargingSpots,
      'full': fullSpots,
    };
  }

  /// 배터리 히스토리 데이터를 온도 기반 FlSpot 리스트로 변환
  static List<FlSpot> convertToTemperatureFlSpots(
    List<BatteryHistoryDataPoint> dataPoints,
  ) {
    return dataPoints.asMap().entries
        .where((entry) => entry.value.hasTemperature)
        .map((entry) {
      final index = entry.key;
      final dataPoint = entry.value;
      
      return FlSpot(
        index.toDouble(),
        dataPoint.temperature,
      );
    }).toList();
  }

  /// 배터리 히스토리 데이터를 전압 기반 FlSpot 리스트로 변환
  static List<FlSpot> convertToVoltageFlSpots(
    List<BatteryHistoryDataPoint> dataPoints,
  ) {
    return dataPoints.asMap().entries
        .where((entry) => entry.value.hasVoltage)
        .map((entry) {
      final index = entry.key;
      final dataPoint = entry.value;
      
      return FlSpot(
        index.toDouble(),
        dataPoint.voltage.toDouble(),
      );
    }).toList();
  }

  /// 차트에 표시할 X축 레이블 생성
  static List<String> generateXAxisLabels(
    List<BatteryHistoryDataPoint> dataPoints, {
    int maxLabels = 6,
    bool showTime = true,
  }) {
    if (dataPoints.isEmpty) return [];
    
    final labels = <String>[];
    final step = (dataPoints.length / (maxLabels - 1)).ceil();
    
    for (int i = 0; i < dataPoints.length; i += step) {
      final dataPoint = dataPoints[i];
      if (showTime) {
        labels.add(_formatTime(dataPoint.timestamp));
      } else {
        labels.add('${i + 1}');
      }
    }
    
    // 마지막 데이터 포인트가 포함되지 않았다면 추가
    if (labels.length < maxLabels && dataPoints.isNotEmpty) {
      final lastDataPoint = dataPoints.last;
      if (showTime) {
        labels.add(_formatTime(lastDataPoint.timestamp));
      } else {
        labels.add('${dataPoints.length}');
      }
    }
    
    return labels;
  }

  /// 차트에 표시할 Y축 레이블 생성 (배터리 레벨)
  static List<String> generateBatteryLevelYAxisLabels() {
    return ['0%', '25%', '50%', '75%', '100%'];
  }

  /// 차트에 표시할 Y축 레이블 생성 (온도)
  static List<String> generateTemperatureYAxisLabels(
    List<BatteryHistoryDataPoint> dataPoints,
  ) {
    if (dataPoints.isEmpty) return ['0°C', '25°C', '50°C'];
    
    final temperatures = dataPoints
        .where((d) => d.hasTemperature)
        .map((d) => d.temperature)
        .toList();
    
    if (temperatures.isEmpty) return ['0°C', '25°C', '50°C'];
    
    final minTemp = temperatures.reduce((a, b) => a < b ? a : b);
    final maxTemp = temperatures.reduce((a, b) => a > b ? a : b);
    final range = maxTemp - minTemp;
    
    if (range < 10) {
      // 온도 범위가 작은 경우
      final center = (minTemp + maxTemp) / 2;
      return [
        '${(center - 5).toStringAsFixed(0)}°C',
        '${center.toStringAsFixed(0)}°C',
        '${(center + 5).toStringAsFixed(0)}°C',
      ];
    } else {
      // 온도 범위가 큰 경우
      return [
        '${minTemp.toStringAsFixed(0)}°C',
        '${((minTemp + maxTemp) / 2).toStringAsFixed(0)}°C',
        '${maxTemp.toStringAsFixed(0)}°C',
      ];
    }
  }

  /// 차트에 표시할 Y축 레이블 생성 (전압)
  static List<String> generateVoltageYAxisLabels(
    List<BatteryHistoryDataPoint> dataPoints,
  ) {
    if (dataPoints.isEmpty) return ['3000mV', '4000mV', '5000mV'];
    
    final voltages = dataPoints
        .where((d) => d.hasVoltage)
        .map((d) => d.voltage.toDouble())
        .toList();
    
    if (voltages.isEmpty) return ['3000mV', '4000mV', '5000mV'];
    
    final minVoltage = voltages.reduce((a, b) => a < b ? a : b);
    final maxVoltage = voltages.reduce((a, b) => a > b ? a : b);
    
    return [
      '${minVoltage.toStringAsFixed(0)}mV',
      '${((minVoltage + maxVoltage) / 2).toStringAsFixed(0)}mV',
      '${maxVoltage.toStringAsFixed(0)}mV',
    ];
  }

  /// 시간 포맷팅 (HH:mm 형태)
  static String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// 배터리 레벨에 따른 색상 반환
  static Color getBatteryLevelColor(double level) {
    if (level >= 80) return Colors.green;
    if (level >= 50) return Colors.orange;
    if (level >= 20) return Colors.red;
    return Colors.red.shade800;
  }

  /// 배터리 상태에 따른 색상 반환
  static Color getBatteryStateColor(BatteryState state) {
    switch (state) {
      case BatteryState.charging:
        return Colors.green;
      case BatteryState.discharging:
        return Colors.red;
      case BatteryState.full:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  /// 온도에 따른 색상 반환
  static Color getTemperatureColor(double temperature) {
    if (temperature < 20) return Colors.blue;
    if (temperature < 30) return Colors.green;
    if (temperature < 40) return Colors.orange;
    return Colors.red;
  }

  /// 전압에 따른 색상 반환
  static Color getVoltageColor(double voltage) {
    if (voltage < 3500) return Colors.red;
    if (voltage < 4000) return Colors.orange;
    if (voltage < 4500) return Colors.green;
    return Colors.blue;
  }

  /// 차트 터치 이벤트에서 데이터 포인트 정보 추출
  static BatteryHistoryDataPoint? getDataPointFromTouch(
    FlTouchEvent event,
    List<BatteryHistoryDataPoint> dataPoints,
  ) {
    if (event is FlTapUpEvent || event is FlPanDownEvent) {
      final spot = event.localPosition;
      if (spot != null) {
        final chartWidth = 300.0; // 차트 너비 (실제로는 동적으로 계산해야 함)
        final index = (spot.dx / chartWidth * dataPoints.length).round();
        
        if (index >= 0 && index < dataPoints.length) {
          return dataPoints[index];
        }
      }
    }
    return null;
  }

  /// 차트 데이터 통계 계산
  static Map<String, dynamic> calculateChartStatistics(
    List<BatteryHistoryDataPoint> dataPoints,
  ) {
    if (dataPoints.isEmpty) {
      return {
        'count': 0,
        'avgLevel': 0.0,
        'minLevel': 0.0,
        'maxLevel': 0.0,
        'levelRange': 0.0,
        'avgTemperature': 0.0,
        'avgVoltage': 0.0,
        'chargingCount': 0,
        'dischargingCount': 0,
        'fullCount': 0,
      };
    }

    final levels = dataPoints.map((d) => d.level).toList();
    final avgLevel = levels.reduce((a, b) => a + b) / levels.length;
    final minLevel = levels.reduce((a, b) => a < b ? a : b);
    final maxLevel = levels.reduce((a, b) => a > b ? a : b);

    final temperatures = dataPoints.where((d) => d.hasTemperature).map((d) => d.temperature).toList();
    final avgTemperature = temperatures.isNotEmpty
        ? temperatures.reduce((a, b) => a + b) / temperatures.length
        : 0.0;

    final voltages = dataPoints.where((d) => d.hasVoltage).map((d) => d.voltage.toDouble()).toList();
    final avgVoltage = voltages.isNotEmpty
        ? voltages.reduce((a, b) => a + b) / voltages.length
        : 0.0;

    final chargingCount = dataPoints.where((d) => d.state == BatteryState.charging).length;
    final dischargingCount = dataPoints.where((d) => d.state == BatteryState.discharging).length;
    final fullCount = dataPoints.where((d) => d.state == BatteryState.full).length;

    return {
      'count': dataPoints.length,
      'avgLevel': avgLevel,
      'minLevel': minLevel,
      'maxLevel': maxLevel,
      'levelRange': maxLevel - minLevel,
      'avgTemperature': avgTemperature,
      'avgVoltage': avgVoltage,
      'chargingCount': chargingCount,
      'dischargingCount': dischargingCount,
      'fullCount': fullCount,
    };
  }
}
