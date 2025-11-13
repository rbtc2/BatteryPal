// 충전 세션 분석 서비스
// 세션 데이터를 분석하고 효율을 계산하는 서비스

import 'dart:math' as math;
import '../../../../../models/models.dart';
import '../models/charging_session_models.dart';
import '../config/charging_session_config.dart';

/// 세션 데이터 포인트 (분석용)
class SessionDataPoint {
  final DateTime timestamp;
  final int currentMa;
  final double batteryLevel;
  final double temperature;
  
  SessionDataPoint({
    required this.timestamp,
    required this.currentMa,
    required this.batteryLevel,
    required this.temperature,
  });
}

/// 세션 분석 결과
class SessionAnalysisResult {
  /// 평균 전류 (mA)
  final double avgCurrent;
  
  /// 평균 온도 (°C)
  final double avgTemperature;
  
  /// 최대 전류 (mA)
  final int maxCurrent;
  
  /// 최소 전류 (mA)
  final int minCurrent;
  
  /// 중앙값 전류 (mA) - 극값의 영향을 줄임
  final int medianCurrent;
  
  /// 전류 표준편차 (mA) - 전류 안정성 지표
  final double currentStdDev;
  
  /// 시작 배터리 레벨 (%)
  final double startBatteryLevel;
  
  /// 종료 배터리 레벨 (%)
  final double endBatteryLevel;
  
  /// 배터리 변화량 (%)
  final double batteryChange;
  
  /// 충전 시간
  final Duration duration;
  
  /// 총 충전 에너지 (mAh) - 실제 충전된 에너지
  final double? totalChargedEnergy;
  
  /// 총 공급 에너지 (mAh) - 충전기에 공급된 에너지
  final double? totalSuppliedEnergy;
  
  /// 충전 효율 (%)
  final double efficiency;
  
  /// 효율 등급
  final String efficiencyGrade;
  
  /// 전류 안정성 점수 (0.0 ~ 1.0, 높을수록 안정적)
  final double currentStabilityScore;

  SessionAnalysisResult({
    required this.avgCurrent,
    required this.avgTemperature,
    required this.maxCurrent,
    required this.minCurrent,
    required this.medianCurrent,
    required this.currentStdDev,
    required this.startBatteryLevel,
    required this.endBatteryLevel,
    required this.batteryChange,
    required this.duration,
    this.totalChargedEnergy,
    this.totalSuppliedEnergy,
    required this.efficiency,
    required this.efficiencyGrade,
    required this.currentStabilityScore,
  });
}

/// 충전 세션 분석 서비스
/// 세션 데이터를 분석하고 효율을 계산하는 정적 유틸리티 클래스
class ChargingSessionAnalyzer {
  ChargingSessionAnalyzer._(); // private constructor (정적 클래스)

  /// 세션 데이터 분석
  /// 
  /// [dataPoints] 수집된 데이터 포인트 목록
  /// [startBatteryInfo] 세션 시작 시 배터리 정보
  /// [endBatteryInfo] 세션 종료 시 배터리 정보
  /// [batteryCapacity] 배터리 용량 (mAh), null이면 기본값 사용
  /// [batteryVoltage] 배터리 전압 (mV), null이면 기본값 사용
  /// 
  /// 반환: 분석 결과
  static SessionAnalysisResult analyzeSession({
    required List<SessionDataPoint> dataPoints,
    required BatteryInfo startBatteryInfo,
    required BatteryInfo endBatteryInfo,
    required Duration duration,
    int? batteryCapacity,
    int? batteryVoltage,
  }) {
    if (dataPoints.isEmpty) {
      throw ArgumentError('데이터 포인트가 비어있습니다');
    }

    // 기본 통계 계산
    final stats = _calculateBasicStatistics(dataPoints);
    
    // 배터리 변화량 계산
    final batteryChange = endBatteryInfo.level - startBatteryInfo.level;
    
    // 효율 계산
    final efficiencyData = _calculateEfficiency(
      batteryChange: batteryChange,
      avgCurrent: stats.avgCurrent,
      duration: duration,
      batteryCapacity: batteryCapacity ?? startBatteryInfo.capacity,
      batteryVoltage: batteryVoltage ?? startBatteryInfo.voltage,
    );
    
    // 전류 안정성 점수 계산
    final stabilityScore = _calculateCurrentStability(
      dataPoints.map((p) => p.currentMa).toList(),
    );

    return SessionAnalysisResult(
      avgCurrent: stats.avgCurrent,
      avgTemperature: stats.avgTemperature,
      maxCurrent: stats.maxCurrent,
      minCurrent: stats.minCurrent,
      medianCurrent: stats.medianCurrent,
      currentStdDev: stats.stdDev,
      startBatteryLevel: startBatteryInfo.level,
      endBatteryLevel: endBatteryInfo.level,
      batteryChange: batteryChange,
      duration: duration,
      totalChargedEnergy: efficiencyData.totalChargedEnergy,
      totalSuppliedEnergy: efficiencyData.totalSuppliedEnergy,
      efficiency: efficiencyData.efficiency,
      efficiencyGrade: efficiencyData.grade,
      currentStabilityScore: stabilityScore,
    );
  }

  /// 기본 통계 계산
  static _BasicStatistics _calculateBasicStatistics(
    List<SessionDataPoint> dataPoints,
  ) {
    if (dataPoints.isEmpty) {
      return _BasicStatistics(
        avgCurrent: 0.0,
        avgTemperature: 0.0,
        maxCurrent: 0,
        minCurrent: 0,
        medianCurrent: 0,
        stdDev: 0.0,
      );
    }

    // 전류값 리스트
    final currents = dataPoints.map((p) => p.currentMa).toList();
    
    // 평균 전류 계산
    final avgCurrent = currents.reduce((a, b) => a + b) / currents.length;
    
    // 최대/최소 전류
    final maxCurrent = currents.reduce((a, b) => a > b ? a : b);
    final minCurrent = currents.reduce((a, b) => a < b ? a : b);
    
    // 중앙값 전류 계산
    final sortedCurrents = List<int>.from(currents)..sort();
    final medianCurrent = _calculateMedian(sortedCurrents);
    
    // 표준편차 계산
    final stdDev = _calculateStandardDeviation(currents, avgCurrent);
    
    // 평균 온도 계산 (유효한 온도만)
    double totalTemperature = 0.0;
    int validTemperatureCount = 0;
    for (final point in dataPoints) {
      if (point.temperature > 0) {
        totalTemperature += point.temperature;
        validTemperatureCount++;
      }
    }
    final avgTemperature = validTemperatureCount > 0
        ? totalTemperature / validTemperatureCount
        : 0.0;

    return _BasicStatistics(
      avgCurrent: avgCurrent,
      avgTemperature: avgTemperature,
      maxCurrent: maxCurrent,
      minCurrent: minCurrent,
      medianCurrent: medianCurrent,
      stdDev: stdDev,
    );
  }

  /// 중앙값 계산
  static int _calculateMedian(List<int> sortedList) {
    if (sortedList.isEmpty) return 0;
    
    final middle = sortedList.length ~/ 2;
    if (sortedList.length % 2 == 1) {
      return sortedList[middle];
    } else {
      return ((sortedList[middle - 1] + sortedList[middle]) / 2).round();
    }
  }

  /// 표준편차 계산
  static double _calculateStandardDeviation(List<int> values, double mean) {
    if (values.isEmpty) return 0.0;
    
    final variance = values
        .map((v) => (v - mean) * (v - mean))
        .reduce((a, b) => a + b) / values.length;
    
    return variance > 0 ? math.sqrt(variance) : 0.0;
  }

  /// 효율 계산
  static _EfficiencyData _calculateEfficiency({
    required double batteryChange,
    required double avgCurrent,
    required Duration duration,
    required int batteryCapacity,
    required int batteryVoltage,
  }) {
    // 용량 정보가 없으면 기본값 사용
    final capacity = batteryCapacity > 0 
        ? batteryCapacity 
        : 3000; // 기본 용량 3000mAh
    // 전압은 현재 효율 계산에 직접 사용하지 않지만, 향후 확장을 위해 파라미터로 유지
    
    // 시간을 시간 단위로 변환
    final hours = duration.inSeconds / 3600.0;
    
    // 실제 충전 에너지 계산 (mAh)
    // 배터리 변화량(%) × 배터리 용량(mAh) = 실제 충전된 에너지(mAh)
    final totalChargedEnergy = (batteryChange / 100.0) * capacity;
    
    // 공급 에너지 계산 (mAh)
    // 평균 전류(mA) × 시간(시간) = 공급된 에너지(mAh)
    final totalSuppliedEnergy = (avgCurrent / 1000.0) * hours * 1000.0; // mA를 mAh로 변환
    
    // 효율 계산
    double efficiency = 85.0; // 기본 효율
    if (totalSuppliedEnergy > 0) {
      efficiency = (totalChargedEnergy / totalSuppliedEnergy) * 100.0;
      // 효율은 0~100% 범위로 제한
      efficiency = efficiency.clamp(0.0, 100.0);
    }
    
    // 효율 등급 결정
    final grade = ChargingSessionConfig.getEfficiencyGrade(efficiency);
    
    return _EfficiencyData(
      totalChargedEnergy: totalChargedEnergy,
      totalSuppliedEnergy: totalSuppliedEnergy,
      efficiency: efficiency,
      grade: grade,
    );
  }

  /// 전류 안정성 점수 계산
  /// 
  /// 전류의 변동성이 적을수록 높은 점수 (0.0 ~ 1.0)
  /// 표준편차가 작을수록, 평균 대비 변동이 적을수록 높은 점수
  static double _calculateCurrentStability(List<int> currents) {
    if (currents.isEmpty) return 0.0;
    if (currents.length == 1) return 1.0;
    
    // 평균 계산
    final avg = currents.reduce((a, b) => a + b) / currents.length;
    if (avg <= 0) return 0.0;
    
    // 변동 계수 (Coefficient of Variation) 계산
    // CV = 표준편차 / 평균
    final stdDev = _calculateStandardDeviation(currents, avg);
    final cv = stdDev / avg;
    
    // 변동 계수가 작을수록 안정적
    // CV = 0 → 완벽히 안정적 (점수 1.0)
    // CV = 0.5 → 중간 (점수 0.5)
    // CV >= 1.0 → 불안정 (점수 0.0)
    final stabilityScore = (1.0 - (cv * 2.0)).clamp(0.0, 1.0);
    
    return stabilityScore;
  }

  /// 전류 변화 이력 분석
  /// 
  /// [dataPoints] 수집된 데이터 포인트 목록
  /// 
  /// 반환: 전류 변화 이벤트 목록
  static List<CurrentChangeEvent> analyzeCurrentChanges(
    List<SessionDataPoint> dataPoints,
  ) {
    if (dataPoints.length < 2) {
      return [];
    }

    final changeEvents = <CurrentChangeEvent>[];
    int? previousCurrent;
    DateTime? previousTime;

    for (final point in dataPoints) {
      final current = point.currentMa;
      final time = point.timestamp;

      if (previousCurrent == null) {
        // 첫 전류값
        previousCurrent = current;
        previousTime = time;
        continue;
      }

      // 전류 변화가 유의미한지 확인
      if (ChargingSessionConfig.isSignificantCurrentChange(
        previousCurrent,
        current,
      )) {
        // 전류 변화 이벤트 생성
        final changeEvent = _createCurrentChangeEvent(
          previousCurrent,
          current,
          previousTime!,
        );

        if (changeEvent != null) {
          changeEvents.add(changeEvent);
        }

        previousCurrent = current;
        previousTime = time;
      }
    }

    return changeEvents;
  }

  /// 전류 변화 이벤트 생성
  static CurrentChangeEvent? _createCurrentChangeEvent(
    int previousCurrent,
    int newCurrent,
    DateTime timestamp,
  ) {
    if (previousCurrent == 0 && newCurrent > 0) {
      // 충전 시작
      final speedType = ChargingSessionConfig.getChargingSpeedType(newCurrent);
      return CurrentChangeEvent(
        timestamp: timestamp,
        previousCurrent: previousCurrent,
        newCurrent: newCurrent,
        changeType: speedType,
        description: '$speedType 시작',
      );
    } else if (previousCurrent > 0 && newCurrent == 0) {
      // 충전 종료
      return CurrentChangeEvent(
        timestamp: timestamp,
        previousCurrent: previousCurrent,
        newCurrent: newCurrent,
        changeType: '종료',
        description: '충전 종료',
      );
    } else if (previousCurrent > 0 && newCurrent > 0) {
      // 충전 속도 변화 - 충전 단위 간 전환만 기록
      final prevSpeedType = ChargingSessionConfig.getChargingSpeedType(previousCurrent);
      final newSpeedType = ChargingSessionConfig.getChargingSpeedType(newCurrent);
      
      // 충전 단위(저속/일반/급속/초고속) 간 전환만 기록
      if (prevSpeedType != newSpeedType) {
        return CurrentChangeEvent(
          timestamp: timestamp,
          previousCurrent: previousCurrent,
          newCurrent: newCurrent,
          changeType: newSpeedType,
          description: '$prevSpeedType → $newSpeedType 전환 ⚡',
        );
      }
      // 같은 충전 단위 내에서의 변화는 기록하지 않음
    }
    
    return null;
  }

  /// 전류 변화 이력 포맷팅
  /// 
  /// [changeEvents] 전류 변화 이벤트 목록
  /// 
  /// 반환: 포맷팅된 문자열 목록 (UI 표시용)
  static List<String> formatSpeedChanges(
    List<CurrentChangeEvent> changeEvents,
  ) {
    return changeEvents.map((event) {
      final timeStr = '${event.timestamp.hour.toString().padLeft(2, '0')}:'
          '${event.timestamp.minute.toString().padLeft(2, '0')}';
      return '$timeStr ${event.description}';
    }).toList();
  }
}

// ==================== 내부 데이터 클래스 ====================

/// 기본 통계 데이터
class _BasicStatistics {
  final double avgCurrent;
  final double avgTemperature;
  final int maxCurrent;
  final int minCurrent;
  final int medianCurrent;
  final double stdDev;

  _BasicStatistics({
    required this.avgCurrent,
    required this.avgTemperature,
    required this.maxCurrent,
    required this.minCurrent,
    required this.medianCurrent,
    required this.stdDev,
  });
}

/// 효율 계산 데이터
class _EfficiencyData {
  final double? totalChargedEnergy;
  final double? totalSuppliedEnergy;
  final double efficiency;
  final String grade;

  _EfficiencyData({
    required this.totalChargedEnergy,
    required this.totalSuppliedEnergy,
    required this.efficiency,
    required this.grade,
  });
}

