import 'package:flutter/material.dart';

// 데이터 모델 정의
// Phase 3에서 실제 구현 예정

/// 배터리 정보 모델
class BatteryInfo {
  final double level;
  final double temperature;
  final double voltage;
  final String health;
  final bool isCharging;
  final DateTime timestamp;
  
  const BatteryInfo({
    required this.level,
    required this.temperature,
    required this.voltage,
    required this.health,
    required this.isCharging,
    required this.timestamp,
  });
  
  // Phase 3에서 실제 구현 예정
  String get formattedLevel => '${level.toStringAsFixed(1)}%';
  String get formattedTemperature => '${temperature.toStringAsFixed(1)}°C';
  String get formattedVoltage => '${voltage.toStringAsFixed(0)}mV';
  String get healthText => health;
  String get chargingStatusText => isCharging ? '충전 중' : '방전 중';
  
  Color get levelColor => Colors.green; // 임시
  Color get temperatureColor => Colors.blue; // 임시
  Color get voltageColor => Colors.orange; // 임시
  Color get healthColor => Colors.green; // 임시
  
  IconData get levelIcon => Icons.battery_std; // 임시
}

/// 앱 사용량 데이터 모델
class AppUsageData {
  final String name;
  final int usage;
  final IconData icon;
  
  const AppUsageData({
    required this.name,
    required this.usage,
    required this.icon,
  });
}

/// 설정 데이터 모델
class AppSettings {
  final bool notificationsEnabled;
  final bool darkModeEnabled;
  final String selectedLanguage;
  final bool powerSaveModeEnabled;
  final bool batteryNotificationsEnabled;
  final bool autoOptimizationEnabled;
  final bool batteryProtectionEnabled;
  final double batteryThreshold;
  final bool smartChargingEnabled;
  final bool backgroundAppRestriction;
  
  const AppSettings({
    this.notificationsEnabled = true,
    this.darkModeEnabled = true,
    this.selectedLanguage = '한국어',
    this.powerSaveModeEnabled = false,
    this.batteryNotificationsEnabled = true,
    this.autoOptimizationEnabled = true,
    this.batteryProtectionEnabled = true,
    this.batteryThreshold = 20.0,
    this.smartChargingEnabled = false,
    this.backgroundAppRestriction = false,
  });
}
