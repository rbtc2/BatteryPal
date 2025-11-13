import 'package:flutter/material.dart';
import 'package:battery_plus/battery_plus.dart';
import '../utils/app_utils.dart';

/// 배터리 정보 모델
class BatteryInfo {
  final double level; // 배터리 레벨 (0.0 ~ 100.0)
  final BatteryState state; // 배터리 상태
  final DateTime timestamp; // 정보 수집 시간
  final double temperature; // 배터리 온도 (섭씨)
  final int voltage; // 배터리 전압 (mV)
  final int capacity; // 배터리 용량
  final int health; // 배터리 건강도
  final String chargingType; // 충전 방식 (AC/USB/Wireless)
  final int chargingCurrent; // 충전 전류 (mA)
  final bool isCharging; // 충전 중 여부

  const BatteryInfo({
    required this.level,
    required this.state,
    required this.timestamp,
    required this.temperature,
    required this.voltage,
    required this.capacity,
    required this.health,
    required this.chargingType,
    required this.chargingCurrent,
    required this.isCharging,
  });

  /// 배터리 레벨을 정확하게 포맷팅 (소수점이 의미가 있을 때만 표시)
  String get formattedLevel {
    if (level == level.round()) {
      return '${level.round()}%'; // 정수인 경우 소수점 없이 표시
    } else {
      return '${level.toStringAsFixed(1)}%'; // 소수점이 있는 경우에만 표시
    }
  }
  
  /// 배터리 온도를 소숫점 한자리까지 포맷팅
  String get formattedTemperature => temperature >= 0 ? '${temperature.toStringAsFixed(1)}°C' : '--.-°C';
  
  /// 배터리 전압을 포맷팅
  String get formattedVoltage => voltage >= 0 ? '${voltage}mV' : '--mV';
  
  /// 배터리 용량을 포맷팅
  String get formattedCapacity => capacity >= 0 ? '${capacity}mAh' : '--mAh';
  
  /// 배터리 건강도를 텍스트로 변환
  String get healthText {
    switch (health) {
      case 1: return '알 수 없음';
      case 2: return '양호';
      case 3: return '과열';
      case 4: return '사망';
      case 5: return '과전압';
      case 6: return '지정되지 않은 오류';
      case 7: return '온도 저하';
      default: return '알 수 없음';
    }
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
  
  /// 충전 상태 요약
  String get chargingStatusText {
    if (!isCharging) return '방전 중';
    return '$chargingTypeText ($formattedChargingCurrent)';
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
  
  /// 배터리 레벨에 따른 색상 반환 (유틸리티 사용)
  Color get levelColor => ColorUtils.getBatteryLevelColor(level);
  
  /// 배터리 온도에 따른 색상 반환 (유틸리티 사용)
  Color get temperatureColor => ColorUtils.getTemperatureColor(temperature);
  
  /// 배터리 전압에 따른 색상 반환 (유틸리티 사용)
  Color get voltageColor => ColorUtils.getVoltageColor(voltage.toDouble());
  
  /// 배터리 건강도에 따른 색상 반환 (유틸리티 사용)
  Color get healthColor => ColorUtils.getHealthColor(healthText);
  
  /// 배터리 레벨에 따른 아이콘 반환 (유틸리티 사용)
  IconData get levelIcon => IconUtils.getBatteryLevelIcon(level);
  
  /// 배터리 상태에 따른 아이콘 반환 (유틸리티 사용)
  IconData get statusIcon => IconUtils.getBatteryStatusIcon(isCharging, level);
  
  /// 마지막 업데이트 시간을 상대적 시간으로 표시
  String get lastUpdateText => TimeUtils.formatRelativeTime(timestamp);
  
  /// 배터리 정보를 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'level': level,
      'state': state.toString(),
      'timestamp': timestamp.toIso8601String(),
      'temperature': temperature,
      'voltage': voltage,
      'capacity': capacity,
      'health': health,
      'chargingType': chargingType,
      'chargingCurrent': chargingCurrent,
      'isCharging': isCharging,
    };
  }
  
  /// JSON에서 배터리 정보 생성
  factory BatteryInfo.fromJson(Map<String, dynamic> json) {
    return BatteryInfo(
      level: json['level']?.toDouble() ?? 0.0,
      state: BatteryState.values.firstWhere(
        (e) => e.toString() == json['state'],
        orElse: () => BatteryState.unknown,
      ),
      timestamp: DateTime.parse(json['timestamp']),
      temperature: json['temperature']?.toDouble() ?? 0.0,
      voltage: json['voltage'] ?? 0,
      capacity: json['capacity'] ?? 0,
      health: json['health'] ?? 1,
      chargingType: json['chargingType'] ?? 'Unknown',
      chargingCurrent: json['chargingCurrent'] ?? -1,
      isCharging: json['isCharging'] ?? false,
    );
  }

  /// 네이티브 충전 정보에서 배터리 정보 생성
  factory BatteryInfo.fromChargingInfo(Map<String, dynamic> chargingInfo) {
    final isCharging = chargingInfo['isCharging'] ?? false;
    final chargingType = chargingInfo['chargingType'] ?? 'Unknown';
    final chargingCurrent = chargingInfo['chargingCurrent'] ?? -1;
    
    // 충전 상태에 따른 BatteryState 결정
    BatteryState state;
    if (isCharging) {
      state = BatteryState.charging;
    } else {
      state = BatteryState.discharging;
    }
    
    return BatteryInfo(
      level: 0.0, // 네이티브에서 레벨 정보가 없으므로 기본값
      state: state,
      timestamp: DateTime.now(),
      temperature: -1.0, // 네이티브에서 온도 정보가 없으므로 기본값
      voltage: -1, // 네이티브에서 전압 정보가 없으므로 기본값
      capacity: -1, // 네이티브에서 용량 정보가 없으므로 기본값
      health: -1, // 네이티브에서 건강도 정보가 없으므로 기본값
      chargingType: chargingType,
      chargingCurrent: chargingCurrent,
      isCharging: isCharging,
    );
  }

  /// 네이티브 충전 정보에서 배터리 정보 생성 (기존 데이터 유지)
  factory BatteryInfo.fromChargingInfoWithExistingData(
    Map<String, dynamic> chargingInfo, {
    required double level,
    required double temperature,
    required int voltage,
    required int capacity,
    required int health,
  }) {
    final isCharging = chargingInfo['isCharging'] ?? false;
    final chargingType = chargingInfo['chargingType'] ?? 'Unknown';
    final chargingCurrent = chargingInfo['chargingCurrent'] ?? -1;
    
    // 충전 상태에 따른 BatteryState 결정
    BatteryState state;
    if (isCharging) {
      state = BatteryState.charging;
    } else {
      state = BatteryState.discharging;
    }
    
    return BatteryInfo(
      level: level, // 기존 레벨 유지
      state: state,
      timestamp: DateTime.now(),
      temperature: temperature, // 기존 온도 유지
      voltage: voltage, // 기존 전압 유지
      capacity: capacity, // 기존 용량 유지
      health: health, // 기존 건강도 유지
      chargingType: chargingType,
      chargingCurrent: chargingCurrent,
      isCharging: isCharging,
    );
  }
  
  /// 배터리 정보 복사본 생성 (일부 필드 수정)
  BatteryInfo copyWith({
    double? level,
    BatteryState? state,
    DateTime? timestamp,
    double? temperature,
    int? voltage,
    int? capacity,
    int? health,
    String? chargingType,
    int? chargingCurrent,
    bool? isCharging,
  }) {
    return BatteryInfo(
      level: level ?? this.level,
      state: state ?? this.state,
      timestamp: timestamp ?? this.timestamp,
      temperature: temperature ?? this.temperature,
      voltage: voltage ?? this.voltage,
      capacity: capacity ?? this.capacity,
      health: health ?? this.health,
      chargingType: chargingType ?? this.chargingType,
      chargingCurrent: chargingCurrent ?? this.chargingCurrent,
      isCharging: isCharging ?? this.isCharging,
    );
  }
  
  @override
  String toString() {
    return 'BatteryInfo(level: $level%, state: $stateText, temperature: $formattedTemperature, voltage: $formattedVoltage, health: $healthText)';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BatteryInfo &&
        other.level == level &&
        other.state == state &&
        other.timestamp == timestamp &&
        other.temperature == temperature &&
        other.voltage == voltage &&
        other.capacity == capacity &&
        other.health == health &&
        other.chargingType == chargingType &&
        other.chargingCurrent == chargingCurrent &&
        other.isCharging == isCharging;
  }
  
  @override
  int get hashCode {
    return Object.hash(
      level,
      state,
      timestamp,
      temperature,
      voltage,
      capacity,
      health,
      chargingType,
      chargingCurrent,
      isCharging,
    );
  }
}

