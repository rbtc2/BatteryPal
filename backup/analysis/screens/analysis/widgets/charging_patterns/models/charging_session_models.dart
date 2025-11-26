// 충전 세션 기록을 위한 데이터 모델들

import 'package:flutter/material.dart';
import '../config/charging_session_config.dart';

/// 시간대 분류 enum
/// 충전 세션을 시간대별로 분류하기 위한 enum
enum TimeSlot {
  /// 새벽 충전: 00:00 ~ 06:00
  dawn,
  
  /// 아침 충전: 06:00 ~ 12:00
  morning,
  
  /// 점심 충전: 12:00 ~ 15:00
  afternoon,
  
  /// 늦은 오후 충전: 15:00 ~ 18:00
  lateAfternoon,
  
  /// 저녁 충전: 18:00 ~ 22:00
  evening,
  
  /// 밤 충전: 22:00 ~ 24:00
  night,
}

/// 전류 변화 이벤트
/// 충전 중 전류가 크게 변한 시점을 기록
class CurrentChangeEvent {
  /// 변화 시점
  final DateTime timestamp;
  
  /// 변화 전 전류 (mA)
  final int previousCurrent;
  
  /// 변화 후 전류 (mA)
  final int newCurrent;
  
  /// 변화 유형 (저속/일반/급속)
  final String changeType;
  
  /// 설명 (예: "저속 시작", "급속 전환 ⚡")
  final String description;

  CurrentChangeEvent({
    required this.timestamp,
    required this.previousCurrent,
    required this.newCurrent,
    required this.changeType,
    required this.description,
  });

  /// JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'previousCurrent': previousCurrent,
      'newCurrent': newCurrent,
      'changeType': changeType,
      'description': description,
    };
  }

  /// JSON에서 생성
  factory CurrentChangeEvent.fromJson(Map<String, dynamic> json) {
    return CurrentChangeEvent(
      timestamp: DateTime.parse(json['timestamp'] as String),
      previousCurrent: json['previousCurrent'] as int,
      newCurrent: json['newCurrent'] as int,
      changeType: json['changeType'] as String,
      description: json['description'] as String,
    );
  }

  @override
  String toString() {
    return 'CurrentChangeEvent($description: ${previousCurrent}mA → ${newCurrent}mA)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CurrentChangeEvent &&
        other.timestamp == timestamp &&
        other.previousCurrent == previousCurrent &&
        other.newCurrent == newCurrent;
  }

  @override
  int get hashCode {
    return Object.hash(timestamp, previousCurrent, newCurrent);
  }
}

/// 충전 세션 기록 모델
/// 3분 이상 유의미한 충전 세션에 대한 완전한 기록
class ChargingSessionRecord {
  /// 고유 ID (UUID 또는 타임스탬프 기반)
  final String id;
  
  /// 세션 시작 시간
  final DateTime startTime;
  
  /// 세션 종료 시간
  final DateTime endTime;
  
  /// 시작 배터리 레벨 (%)
  final double startBatteryLevel;
  
  /// 종료 배터리 레벨 (%)
  final double endBatteryLevel;
  
  /// 배터리 변화량 (%)
  final double batteryChange;
  
  /// 충전 시간
  final Duration duration;
  
  /// 평균 전류 (mA)
  final double avgCurrent;
  
  /// 평균 온도 (°C)
  final double avgTemperature;
  
  /// 최대 전류 (mA)
  final int maxCurrent;
  
  /// 최소 전류 (mA)
  final int minCurrent;
  
  /// 충전 효율 (%)
  final double efficiency;
  
  /// 시간대 분류
  final TimeSlot timeSlot;
  
  /// 세션 제목 (예: "아침 충전", "아침 충전 2")
  final String sessionTitle;
  
  /// 전류 변화 이력
  final List<CurrentChangeEvent> speedChanges;
  
  /// 아이콘 (이모지)
  final String icon;
  
  /// 색상
  final Color color;
  
  /// 배터리 용량 (mAh) - 효율 계산에 사용
  final int? batteryCapacity;
  
  /// 배터리 전압 (mV) - 효율 계산에 사용
  final int? batteryVoltage;
  
  /// 세션이 유효한지 여부 (3분 이상, 유의미한 충전)
  final bool isValid;

  ChargingSessionRecord({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.startBatteryLevel,
    required this.endBatteryLevel,
    required this.batteryChange,
    required this.duration,
    required this.avgCurrent,
    required this.avgTemperature,
    required this.maxCurrent,
    required this.minCurrent,
    required this.efficiency,
    required this.timeSlot,
    required this.sessionTitle,
    required this.speedChanges,
    required this.icon,
    required this.color,
    this.batteryCapacity,
    this.batteryVoltage,
    this.isValid = true,
  });

  /// 유효성 검증
  /// 세션이 유효한 충전 세션인지 확인
  bool validate() {
    // 1. 시간 검증
    if (endTime.isBefore(startTime)) {
      return false;
    }
    
    // 2. 최소 충전 시간 검증 (ChargingSessionConfig에서 가져옴)
    if (duration < ChargingSessionConfig.minChargingDuration) {
      return false;
    }
    
    // 3. 유의미한 충전 검증 (평균 전류 100mA 이상)
    if (avgCurrent < 100) {
      return false;
    }
    
    // 4. 배터리 레벨 검증
    if (startBatteryLevel < 0 || startBatteryLevel > 100 ||
        endBatteryLevel < 0 || endBatteryLevel > 100) {
      return false;
    }
    
    // 5. 배터리 변화량 검증 (최소 1% 이상)
    if (batteryChange < 1.0) {
      return false;
    }
    
    // 6. 효율 검증 (0~100% 범위)
    if (efficiency < 0 || efficiency > 100) {
      return false;
    }
    
    return true;
  }

  /// JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'startBatteryLevel': startBatteryLevel,
      'endBatteryLevel': endBatteryLevel,
      'batteryChange': batteryChange,
      'duration': duration.inMilliseconds,
      'avgCurrent': avgCurrent,
      'avgTemperature': avgTemperature,
      'maxCurrent': maxCurrent,
      'minCurrent': minCurrent,
      'efficiency': efficiency,
      'timeSlot': timeSlot.name,
      'sessionTitle': sessionTitle,
      'speedChanges': speedChanges.map((e) => e.toJson()).toList(),
      'icon': icon,
      'color': color.toARGB32(), // ARGB32 값으로 저장
      'batteryCapacity': batteryCapacity,
      'batteryVoltage': batteryVoltage,
      'isValid': isValid,
    };
  }

  /// JSON에서 생성
  factory ChargingSessionRecord.fromJson(Map<String, dynamic> json) {
    return ChargingSessionRecord(
      id: json['id'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      startBatteryLevel: (json['startBatteryLevel'] as num).toDouble(),
      endBatteryLevel: (json['endBatteryLevel'] as num).toDouble(),
      batteryChange: (json['batteryChange'] as num).toDouble(),
      duration: Duration(milliseconds: json['duration'] as int),
      avgCurrent: (json['avgCurrent'] as num).toDouble(),
      avgTemperature: (json['avgTemperature'] as num).toDouble(),
      maxCurrent: json['maxCurrent'] as int,
      minCurrent: json['minCurrent'] as int,
      efficiency: (json['efficiency'] as num).toDouble(),
      timeSlot: TimeSlot.values.firstWhere(
        (e) => e.name == json['timeSlot'],
        orElse: () => TimeSlot.morning,
      ),
      sessionTitle: json['sessionTitle'] as String,
      speedChanges: (json['speedChanges'] as List<dynamic>)
          .map((e) => CurrentChangeEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
      icon: json['icon'] as String,
      color: Color(json['color'] as int),
      batteryCapacity: json['batteryCapacity'] as int?,
      batteryVoltage: json['batteryVoltage'] as int?,
      isValid: json['isValid'] as bool? ?? true,
    );
  }

  /// 복사 생성 (일부 필드만 변경)
  ChargingSessionRecord copyWith({
    String? id,
    DateTime? startTime,
    DateTime? endTime,
    double? startBatteryLevel,
    double? endBatteryLevel,
    double? batteryChange,
    Duration? duration,
    double? avgCurrent,
    double? avgTemperature,
    int? maxCurrent,
    int? minCurrent,
    double? efficiency,
    TimeSlot? timeSlot,
    String? sessionTitle,
    List<CurrentChangeEvent>? speedChanges,
    String? icon,
    Color? color,
    int? batteryCapacity,
    int? batteryVoltage,
    bool? isValid,
  }) {
    return ChargingSessionRecord(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      startBatteryLevel: startBatteryLevel ?? this.startBatteryLevel,
      endBatteryLevel: endBatteryLevel ?? this.endBatteryLevel,
      batteryChange: batteryChange ?? this.batteryChange,
      duration: duration ?? this.duration,
      avgCurrent: avgCurrent ?? this.avgCurrent,
      avgTemperature: avgTemperature ?? this.avgTemperature,
      maxCurrent: maxCurrent ?? this.maxCurrent,
      minCurrent: minCurrent ?? this.minCurrent,
      efficiency: efficiency ?? this.efficiency,
      timeSlot: timeSlot ?? this.timeSlot,
      sessionTitle: sessionTitle ?? this.sessionTitle,
      speedChanges: speedChanges ?? this.speedChanges,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      batteryCapacity: batteryCapacity ?? this.batteryCapacity,
      batteryVoltage: batteryVoltage ?? this.batteryVoltage,
      isValid: isValid ?? this.isValid,
    );
  }

  @override
  String toString() {
    return 'ChargingSessionRecord('
        'id: $id, '
        'title: $sessionTitle, '
        'time: ${startTime.toString().substring(11, 16)} - ${endTime.toString().substring(11, 16)}, '
        'battery: ${startBatteryLevel.toStringAsFixed(1)}% → ${endBatteryLevel.toStringAsFixed(1)}%, '
        'duration: ${duration.inMinutes}분, '
        'efficiency: ${efficiency.toStringAsFixed(1)}%'
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChargingSessionRecord && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

