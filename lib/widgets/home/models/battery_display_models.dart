import 'package:flutter/material.dart';

/// 표시할 정보 타입 열거형
enum DisplayInfoType {
  batteryLevel,    // 배터리 레벨
  chargingCurrent, // 충전 전류
  batteryTemp,     // 배터리 온도
}

/// 표시 정보 데이터 모델
class DisplayInfo {
  final String title;
  final String value;
  final String subtitle;
  final Color color;
  final IconData? icon;
  
  DisplayInfo({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
    this.icon,
  });
}

/// 충전 속도 타입 정보
class ChargingSpeedType {
  final String label;
  final IconData icon;
  final Color color;
  
  ChargingSpeedType({
    required this.label,
    required this.icon,
    required this.color,
  });
}

