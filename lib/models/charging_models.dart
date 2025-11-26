import 'package:flutter/material.dart';

/// 충전 전류 원본 데이터 포인트 클래스
/// 충전 전류 히스토리 서비스에서 사용하는 기본 데이터 모델
class ChargingCurrentPoint {
  final DateTime timestamp;  // 예: 2025-11-04 13:00:00
  final int currentMa;        // 예: 500 (단위: mA)
  
  ChargingCurrentPoint({
    required this.timestamp,
    required this.currentMa,
  });

  @override
  String toString() {
    return 'ChargingCurrentPoint(timestamp: $timestamp, currentMa: ${currentMa}mA)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChargingCurrentPoint &&
        other.timestamp == timestamp &&
        other.currentMa == currentMa;
  }

  @override
  int get hashCode {
    return Object.hash(timestamp, currentMa);
  }
}

/// 충전 속도 정보 모델
/// 충전 속도 분석 결과를 담는 모델
class ChargingSpeedInfo {
  final String label; // 충전 속도 라벨 (예: "초고속 충전", "고속 충전", "저속 충전")
  final String description; // 충전 속도 설명 (예: "2.1A 충전 중")
  final Color color; // 충전 속도에 따른 색상
  final IconData icon; // 충전 속도에 따른 아이콘
  final List<String> tips; // 충전 최적화 팁 목록

  const ChargingSpeedInfo({
    required this.label,
    required this.description,
    required this.color,
    required this.icon,
    required this.tips,
  });

  @override
  String toString() {
    return 'ChargingSpeedInfo(label: $label, description: $description, color: $color, icon: $icon)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChargingSpeedInfo &&
        other.label == label &&
        other.description == description &&
        other.color == color &&
        other.icon == icon &&
        _listEquals(other.tips, tips);
  }

  @override
  int get hashCode {
    return Object.hash(label, description, color, icon, tips);
  }

  /// 리스트 비교 헬퍼 함수
  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int index = 0; index < a.length; index += 1) {
      if (a[index] != b[index]) return false;
    }
    return true;
  }
}

/// 충전 상태 분석 결과 모델
/// 충전 상태에 대한 종합적인 분석 결과를 담는 모델
class ChargingStatusAnalysis {
  final bool isCharging;
  final ChargingSpeed chargingSpeed;
  final Duration? estimatedTimeToFull;
  final ChargingEfficiency chargingEfficiency;
  final List<String> recommendations;

  const ChargingStatusAnalysis({
    required this.isCharging,
    required this.chargingSpeed,
    this.estimatedTimeToFull,
    required this.chargingEfficiency,
    required this.recommendations,
  });

  @override
  String toString() {
    return 'ChargingStatusAnalysis(isCharging: $isCharging, chargingSpeed: $chargingSpeed, estimatedTimeToFull: $estimatedTimeToFull, chargingEfficiency: $chargingEfficiency)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChargingStatusAnalysis &&
        other.isCharging == isCharging &&
        other.chargingSpeed == chargingSpeed &&
        other.estimatedTimeToFull == estimatedTimeToFull &&
        other.chargingEfficiency == chargingEfficiency &&
        _listEquals(other.recommendations, recommendations);
  }

  @override
  int get hashCode {
    return Object.hash(isCharging, chargingSpeed, estimatedTimeToFull, chargingEfficiency, recommendations);
  }

  /// 리스트 비교 헬퍼 함수
  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int index = 0; index < a.length; index += 1) {
      if (a[index] != b[index]) return false;
    }
    return true;
  }
}

/// 충전 속도 열거형
enum ChargingSpeed {
  verySlow,
  slow,
  medium,
  fast,
  unknown,
}

/// 충전 효율성 열거형
enum ChargingEfficiency {
  excellent,
  good,
  fair,
  poor,
  unknown,
}

/// 충전 방식 열거형
enum ChargingType {
  ac,
  usb,
  wireless,
  unknown,
}

/// 충전 상태 열거형
enum ChargingState {
  charging,
  discharging,
  full,
  unknown,
}

/// 충전 분석 결과 모델
/// 충전 분석의 모든 결과를 포함하는 종합 모델
class ChargingAnalysisResult {
  final ChargingSpeedInfo speedInfo;
  final ChargingStatusAnalysis statusAnalysis;
  final List<String> optimizationTips;
  final DateTime analysisTime;
  final bool isOptimal;

  const ChargingAnalysisResult({
    required this.speedInfo,
    required this.statusAnalysis,
    required this.optimizationTips,
    required this.analysisTime,
    required this.isOptimal,
  });

  /// 분석 결과를 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'speedInfo': {
        'label': speedInfo.label,
        'description': speedInfo.description,
        'color': speedInfo.color.toARGB32(),
        'icon': speedInfo.icon.codePoint,
        'tips': speedInfo.tips,
      },
      'statusAnalysis': {
        'isCharging': statusAnalysis.isCharging,
        'chargingSpeed': statusAnalysis.chargingSpeed.name,
        'estimatedTimeToFull': statusAnalysis.estimatedTimeToFull?.inMinutes,
        'chargingEfficiency': statusAnalysis.chargingEfficiency.name,
        'recommendations': statusAnalysis.recommendations,
      },
      'optimizationTips': optimizationTips,
      'analysisTime': analysisTime.toIso8601String(),
      'isOptimal': isOptimal,
    };
  }

  /// JSON에서 분석 결과 생성
  factory ChargingAnalysisResult.fromJson(Map<String, dynamic> json) {
    return ChargingAnalysisResult(
      speedInfo: ChargingSpeedInfo(
        label: json['speedInfo']['label'],
        description: json['speedInfo']['description'],
        color: Color(json['speedInfo']['color']),
        icon: IconData(json['speedInfo']['icon']),
        tips: List<String>.from(json['speedInfo']['tips']),
      ),
      statusAnalysis: ChargingStatusAnalysis(
        isCharging: json['statusAnalysis']['isCharging'],
        chargingSpeed: ChargingSpeed.values.firstWhere(
          (e) => e.name == json['statusAnalysis']['chargingSpeed'],
          orElse: () => ChargingSpeed.unknown,
        ),
        estimatedTimeToFull: json['statusAnalysis']['estimatedTimeToFull'] != null
            ? Duration(minutes: json['statusAnalysis']['estimatedTimeToFull'])
            : null,
        chargingEfficiency: ChargingEfficiency.values.firstWhere(
          (e) => e.name == json['statusAnalysis']['chargingEfficiency'],
          orElse: () => ChargingEfficiency.unknown,
        ),
        recommendations: List<String>.from(json['statusAnalysis']['recommendations']),
      ),
      optimizationTips: List<String>.from(json['optimizationTips']),
      analysisTime: DateTime.parse(json['analysisTime']),
      isOptimal: json['isOptimal'],
    );
  }

  @override
  String toString() {
    return 'ChargingAnalysisResult(speedInfo: $speedInfo, statusAnalysis: $statusAnalysis, isOptimal: $isOptimal)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChargingAnalysisResult &&
        other.speedInfo == speedInfo &&
        other.statusAnalysis == statusAnalysis &&
        other.optimizationTips == optimizationTips &&
        other.analysisTime == analysisTime &&
        other.isOptimal == isOptimal;
  }

  @override
  int get hashCode {
    return Object.hash(speedInfo, statusAnalysis, optimizationTips, analysisTime, isOptimal);
  }
}
