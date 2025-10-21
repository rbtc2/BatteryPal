import 'package:flutter/material.dart';

/// 충전 관련 상수
/// 충전 속도, 임계값, 색상, 아이콘 등의 상수를 정의
class ChargingConstants {
  // 충전 속도 임계값 (mA)
  static const int ultraFastChargingThreshold = 2000; // 2A 이상
  static const int fastChargingThreshold = 1000;      // 1A 이상
  static const int normalChargingThreshold = 500;     // 0.5A 이상
  
  // 충전 속도 라벨
  static const String ultraFastChargingLabel = '초고속 충전';
  static const String fastChargingLabel = '고속 충전';
  static const String normalChargingLabel = '일반 충전';
  static const String slowChargingLabel = '저속 충전';
  static const String unknownChargingLabel = '충전 중';
  
  // 충전 속도 색상
  static const Color ultraFastChargingColor = Colors.red;
  static const Color fastChargingColor = Colors.orange;
  static const Color normalChargingColor = Colors.blue;
  static const Color slowChargingColor = Colors.grey;
  static const Color unknownChargingColor = Colors.grey;
  
  // 충전 속도 아이콘
  static const IconData ultraFastChargingIcon = Icons.flash_on;
  static const IconData fastChargingIcon = Icons.electric_bolt;
  static const IconData normalChargingIcon = Icons.battery_charging_full;
  static const IconData slowChargingIcon = Icons.battery_charging_full;
  static const IconData unknownChargingIcon = Icons.electric_bolt_outlined;
  
  // 충전 최적화 팁
  static const List<String> ultraFastChargingTips = [
    '초고속 충전으로 빠르게 충전 중입니다',
    '80% 이상 충전 시 속도가 감소합니다',
    '충전 완료 후 즉시 분리 권장',
    '충전 중 고성능 작업은 피하세요',
  ];
  
  static const List<String> fastChargingTips = [
    '고속 충전으로 충전 중입니다',
    '80% 이상 충전 시 속도가 감소합니다',
    '충전 완료 후 30분 이내 분리 권장',
    '충전 중 고성능 작업은 피하세요',
  ];
  
  static const List<String> normalChargingTips = [
    '일반 충전으로 충전 중입니다',
    '충전 속도가 느릴 수 있습니다',
    '충전 완료 후 분리해주세요',
    '배터리 온도가 높으면 충전 속도가 느려집니다',
  ];
  
  static const List<String> slowChargingTips = [
    '저속 충전으로 충전 중입니다',
    '충전 속도가 매우 느립니다',
    '고전력 충전기 사용을 권장합니다',
    '충전 중 사용을 최소화하세요',
  ];
  
  static const List<String> unknownChargingTips = [
    '충전 정보를 확인하고 있습니다',
    '잠시만 기다려주세요',
  ];
  
  // 배터리 온도 임계값 (°C)
  static const double lowTemperatureThreshold = 20.0;
  static const double normalTemperatureThreshold = 30.0;
  static const double highTemperatureThreshold = 40.0;
  static const double criticalTemperatureThreshold = 45.0;
  static const double dangerousTemperatureThreshold = 50.0;
  
  // 배터리 레벨 임계값 (%)
  static const double lowBatteryThreshold = 20.0;
  static const double highBatteryThreshold = 80.0;
  static const double criticalBatteryThreshold = 10.0;
  
  // 충전 효율성 임계값
  static const double excellentEfficiencyThreshold = 30.0;
  static const double goodEfficiencyThreshold = 40.0;
  static const double fairEfficiencyThreshold = 50.0;
  
  // 시간 관련 상수
  static const Duration chargingUpdateInterval = Duration(seconds: 30);
  static const Duration chargingAnimationDuration = Duration(milliseconds: 1000);
  
  // 충전 예상 시간 관련 상수
  static const double defaultBatteryCapacity = 4000.0; // mAh (평균 배터리 용량)
  static const double chargingEfficiency = 0.85; // 85% 충전 효율성
  static const int minEstimatedMinutes = 1; // 최소 예상 시간 (분)
  static const int maxEstimatedMinutes = 1440; // 최대 예상 시간 (분, 24시간)
  
  // UI 관련 상수
  static const double chargingProgressBarHeight = 3.0;
  static const double chargingIconSize = 24.0;
  static const double chargingHeaderIconSize = 16.0;
  static const double chargingAnimationDotSize = 4.0;
  
  // 텍스트 상수
  static const String chargingAnalysisTitle = '충전 분석';
  static const String realTimeMonitoringText = '실시간 모니터링';
  static const String optimizationTipsTitle = '최적화 팁';
  static const String chargingProgressLabel = '진행률';
  static const String lastUpdatePrefix = '마지막 업데이트: ';
  static const String estimatedCompletionText = '예상 완료';
  static const String estimatedCompletionPrefix = '예상 완료: ';
  
  // 충전 방식 텍스트
  static const String acChargingText = 'AC 충전';
  static const String usbChargingText = 'USB 충전';
  static const String wirelessChargingText = '무선 충전';
  static const String unknownChargingTypeText = '알 수 없음';
  
  // 충전 상태 텍스트
  static const String dischargingText = '방전 중';
  static const String chargingText = '충전 중';
  static const String fullChargedText = '충전 완료';
  static const String unknownStateText = '알 수 없음';
}
