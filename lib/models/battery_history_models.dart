import 'package:json_annotation/json_annotation.dart';
import 'package:battery_plus/battery_plus.dart';
import 'battery_info.dart';

part 'battery_history_models.g.dart';

/// 배터리 히스토리 데이터 포인트를 나타내는 모델
/// 시간별 배터리 상태 변화를 기록하는 기본 단위
@JsonSerializable()
class BatteryHistoryDataPoint {
  /// 고유 식별자 (자동 증가)
  final int? id;
  
  /// 데이터 수집 시간 (UTC)
  final DateTime timestamp;
  
  /// 배터리 레벨 (0.0 ~ 100.0)
  final double level;
  
  /// 배터리 상태 (충전/방전/완료/알수없음)
  final BatteryState state;
  
  /// 배터리 온도 (섭씨, -1.0이면 측정 불가)
  final double temperature;
  
  /// 배터리 전압 (mV, -1이면 측정 불가)
  final int voltage;
  
  /// 배터리 용량 (mAh, -1이면 측정 불가)
  final int capacity;
  
  /// 배터리 건강도 (1-7, -1이면 측정 불가)
  final int health;
  
  /// 충전 방식 (AC/USB/Wireless/Unknown)
  final String chargingType;
  
  /// 충전 전류 (mA, -1이면 측정 불가)
  final int chargingCurrent;
  
  /// 충전 중 여부
  final bool isCharging;
  
  /// 앱이 포그라운드에 있었는지 여부
  final bool isAppInForeground;
  
  /// 데이터 수집 방법 (manual/automatic/system_event)
  final String collectionMethod;
  
  /// 데이터 품질 점수 (0.0 ~ 1.0)
  final double dataQuality;

  const BatteryHistoryDataPoint({
    this.id,
    required this.timestamp,
    required this.level,
    required this.state,
    required this.temperature,
    required this.voltage,
    required this.capacity,
    required this.health,
    required this.chargingType,
    required this.chargingCurrent,
    required this.isCharging,
    required this.isAppInForeground,
    required this.collectionMethod,
    required this.dataQuality,
  });

  /// BatteryInfo에서 BatteryHistoryDataPoint 생성
  factory BatteryHistoryDataPoint.fromBatteryInfo(
    BatteryInfo batteryInfo, {
    bool isAppInForeground = true,
    String collectionMethod = 'automatic',
  }) {
    return BatteryHistoryDataPoint(
      timestamp: batteryInfo.timestamp,
      level: batteryInfo.level,
      state: batteryInfo.state,
      temperature: batteryInfo.temperature,
      voltage: batteryInfo.voltage,
      capacity: batteryInfo.capacity,
      health: batteryInfo.health,
      chargingType: batteryInfo.chargingType,
      chargingCurrent: batteryInfo.chargingCurrent,
      isCharging: batteryInfo.isCharging,
      isAppInForeground: isAppInForeground,
      collectionMethod: collectionMethod,
      dataQuality: _calculateDataQuality(batteryInfo),
    );
  }

  /// 데이터 품질 점수 계산
  static double _calculateDataQuality(BatteryInfo batteryInfo) {
    double quality = 1.0;
    
    // 온도 측정 가능 여부
    if (batteryInfo.temperature < 0) quality -= 0.1;
    
    // 전압 측정 가능 여부
    if (batteryInfo.voltage < 0) quality -= 0.1;
    
    // 용량 측정 가능 여부
    if (batteryInfo.capacity < 0) quality -= 0.1;
    
    // 건강도 측정 가능 여부
    if (batteryInfo.health < 0) quality -= 0.1;
    
    // 충전 전류 측정 가능 여부
    if (batteryInfo.chargingCurrent < 0) quality -= 0.1;
    
    return quality.clamp(0.0, 1.0);
  }

  /// 배터리 레벨이 유효한 범위 내에 있는지 확인
  bool get isValidLevel => level >= 0.0 && level <= 100.0;
  
  /// 온도가 측정 가능한지 확인
  bool get hasTemperature => temperature >= 0;
  
  /// 전압이 측정 가능한지 확인
  bool get hasVoltage => voltage >= 0;
  
  /// 용량이 측정 가능한지 확인
  bool get hasCapacity => capacity >= 0;
  
  /// 건강도가 측정 가능한지 확인
  bool get hasHealth => health >= 0;
  
  /// 충전 전류가 측정 가능한지 확인
  bool get hasChargingCurrent => chargingCurrent >= 0;
  
  /// 데이터 품질이 양호한지 확인 (0.7 이상)
  bool get hasGoodQuality => dataQuality >= 0.7;
  
  /// 충전 상태를 한국어로 반환
  String get chargingStatusText {
    if (!isCharging) return '방전 중';
    return '$chargingTypeText ($formattedChargingCurrent)';
  }
  
  /// 충전 방식 텍스트 변환
  String get chargingTypeText {
    switch (chargingType) {
      case 'AC': return 'AC 충전';
      case 'USB': return 'USB 충전';
      case 'Wireless': return '무선 충전';
      default: return '알 수 없음';
    }
  }
  
  /// 충전 전류 포맷팅
  String get formattedChargingCurrent {
    if (chargingCurrent < 0) return '--mA';
    return '${chargingCurrent}mA';
  }
  
  /// 배터리 상태를 한국어로 변환
  String get stateText {
    switch (state) {
      case BatteryState.charging:
        return '충전 중';
      case BatteryState.discharging:
        return '방전 중';
      case BatteryState.full:
        return '충전 완료';
      default:
        return '알 수 없음';
    }
  }
  
  /// 데이터 수집 방법을 한국어로 변환
  String get collectionMethodText {
    switch (collectionMethod) {
      case 'manual': return '수동';
      case 'automatic': return '자동';
      case 'system_event': return '시스템 이벤트';
      default: return '알 수 없음';
    }
  }

  /// JSON 직렬화
  factory BatteryHistoryDataPoint.fromJson(Map<String, dynamic> json) =>
      _$BatteryHistoryDataPointFromJson(json);

  /// JSON 역직렬화
  Map<String, dynamic> toJson() => _$BatteryHistoryDataPointToJson(this);

  /// 데이터 포인트 복사본 생성
  BatteryHistoryDataPoint copyWith({
    int? id,
    DateTime? timestamp,
    double? level,
    BatteryState? state,
    double? temperature,
    int? voltage,
    int? capacity,
    int? health,
    String? chargingType,
    int? chargingCurrent,
    bool? isCharging,
    bool? isAppInForeground,
    String? collectionMethod,
    double? dataQuality,
  }) {
    return BatteryHistoryDataPoint(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      level: level ?? this.level,
      state: state ?? this.state,
      temperature: temperature ?? this.temperature,
      voltage: voltage ?? this.voltage,
      capacity: capacity ?? this.capacity,
      health: health ?? this.health,
      chargingType: chargingType ?? this.chargingType,
      chargingCurrent: chargingCurrent ?? this.chargingCurrent,
      isCharging: isCharging ?? this.isCharging,
      isAppInForeground: isAppInForeground ?? this.isAppInForeground,
      collectionMethod: collectionMethod ?? this.collectionMethod,
      dataQuality: dataQuality ?? this.dataQuality,
    );
  }

  @override
  String toString() {
    return 'BatteryHistoryDataPoint(id: $id, timestamp: $timestamp, level: ${level.toStringAsFixed(1)}%, state: $stateText, temperature: ${temperature.toStringAsFixed(1)}°C, quality: ${(dataQuality * 100).toStringAsFixed(1)}%)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BatteryHistoryDataPoint &&
        other.id == id &&
        other.timestamp == timestamp &&
        other.level == level &&
        other.state == state &&
        other.temperature == temperature &&
        other.voltage == voltage &&
        other.capacity == capacity &&
        other.health == health &&
        other.chargingType == chargingType &&
        other.chargingCurrent == chargingCurrent &&
        other.isCharging == isCharging &&
        other.isAppInForeground == isAppInForeground &&
        other.collectionMethod == collectionMethod &&
        other.dataQuality == dataQuality;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      timestamp,
      level,
      state,
      temperature,
      voltage,
      capacity,
      health,
      chargingType,
      chargingCurrent,
      isCharging,
      isAppInForeground,
      collectionMethod,
      dataQuality,
    );
  }
}

/// 배터리 히스토리 분석 결과를 담는 모델
@JsonSerializable()
class BatteryHistoryAnalysis {
  /// 분석 시작 시간
  final DateTime analysisStartTime;
  
  /// 분석 종료 시간
  final DateTime analysisEndTime;
  
  /// 분석된 데이터 포인트 수
  final int dataPointCount;
  
  /// 분석 기간 (시간)
  final double analysisDurationHours;
  
  /// 평균 배터리 레벨
  final double averageBatteryLevel;
  
  /// 최소 배터리 레벨
  final double minBatteryLevel;
  
  /// 최대 배터리 레벨
  final double maxBatteryLevel;
  
  /// 배터리 변동폭
  final double batteryVariation;
  
  /// 평균 방전 속도 (%/시간)
  final double averageDischargeRate;
  
  /// 평균 충전 속도 (%/시간)
  final double averageChargeRate;
  
  /// 충전 세션 수
  final int chargingSessions;
  
  /// 평균 충전 세션 시간 (분)
  final double averageChargingSessionMinutes;
  
  /// 데이터 품질 점수 (0.0 ~ 1.0)
  final double overallDataQuality;
  
  /// 분석 인사이트
  final List<String> insights;
  
  /// 최적화 제안
  final List<String> recommendations;
  
  /// 패턴 분석 결과
  final Map<String, dynamic> patternAnalysis;
  
  /// 충전 이벤트 목록
  final List<String> chargingEvents;
  
  /// 방전 이벤트 목록
  final List<String> dischargingEvents;
  
  /// 패턴 요약
  final String patternSummary;

  const BatteryHistoryAnalysis({
    required this.analysisStartTime,
    required this.analysisEndTime,
    required this.dataPointCount,
    required this.analysisDurationHours,
    required this.averageBatteryLevel,
    required this.minBatteryLevel,
    required this.maxBatteryLevel,
    required this.batteryVariation,
    required this.averageDischargeRate,
    required this.averageChargeRate,
    required this.chargingSessions,
    required this.averageChargingSessionMinutes,
    required this.overallDataQuality,
    required this.insights,
    required this.recommendations,
    required this.patternAnalysis,
    required this.chargingEvents,
    required this.dischargingEvents,
    required this.patternSummary,
  });

  /// 분석 소요 시간
  Duration get analysisDuration => analysisEndTime.difference(analysisStartTime);
  
  /// 분석 소요 시간을 포맷팅된 문자열로 반환
  String get formattedAnalysisDuration {
    final duration = analysisDuration;
    if (duration.inSeconds < 60) {
      return '${duration.inSeconds}초';
    } else if (duration.inMinutes < 60) {
      return '${duration.inMinutes}분 ${duration.inSeconds % 60}초';
    } else {
      return '${duration.inHours}시간 ${duration.inMinutes % 60}분';
    }
  }
  
  /// 배터리 효율성 점수 (0.0 ~ 100.0)
  double get batteryEfficiencyScore {
    double score = 100.0;
    
    // 평균 레벨이 너무 낮으면 감점
    if (averageBatteryLevel < 30) {
      score -= 20;
    } else if (averageBatteryLevel < 50) {
      score -= 10;
    }
    
    // 변동폭이 크면 감점
    if (batteryVariation > 80) {
      score -= 15;
    } else if (batteryVariation > 60) {
      score -= 10;
    }
    
    // 방전 속도가 빠르면 감점
    if (averageDischargeRate > 5) {
      score -= 15;
    } else if (averageDischargeRate > 3) {
      score -= 10;
    }
    
    // 데이터 품질이 낮으면 감점
    if (overallDataQuality < 0.7) {
      score -= 10;
    }
    
    return score.clamp(0.0, 100.0);
  }
  
  /// 효율성 등급 반환
  String get batteryEfficiencyGrade {
    final score = batteryEfficiencyScore;
    if (score >= 90) return 'A+';
    if (score >= 80) return 'A';
    if (score >= 70) return 'B';
    if (score >= 60) return 'C';
    if (score >= 50) return 'D';
    return 'F';
  }

  /// JSON 직렬화
  factory BatteryHistoryAnalysis.fromJson(Map<String, dynamic> json) =>
      _$BatteryHistoryAnalysisFromJson(json);

  /// JSON 역직렬화
  Map<String, dynamic> toJson() => _$BatteryHistoryAnalysisToJson(this);

  @override
  String toString() {
    return 'BatteryHistoryAnalysis(duration: $formattedAnalysisDuration, dataPoints: $dataPointCount, avgLevel: ${averageBatteryLevel.toStringAsFixed(1)}%, efficiency: $batteryEfficiencyGrade)';
  }
}

/// 배터리 히스토리 데이터베이스 설정
class BatteryHistoryDatabaseConfig {
  /// 데이터베이스 이름
  static const String databaseName = 'battery_history.db';
  
  /// 데이터베이스 버전
  /// 버전 2: charging_sessions 테이블 추가
  static const int databaseVersion = 2;
  
  /// 테이블 이름
  static const String tableName = 'battery_history';
  
  /// 데이터 보관 기간 (일)
  static const int dataRetentionDays = 30;
  
  /// 충전 전류 데이터 보관 기간 (일) - 그래프용 데이터는 7일만 보관
  static const int chargingCurrentRetentionDays = 7;
  
  /// 자동 정리 주기 (일)
  static const int autoCleanupIntervalDays = 7;
  
  /// 일별 자동 정리 실행 시간 (시간) - 매일 자정에 실행
  static const int dailyCleanupHour = 0;
  
  /// 최대 데이터 포인트 수
  static const int maxDataPoints = 10000;
  
  /// 데이터 압축 임계값
  static const int compressionThreshold = 1000;
}
