import 'dart:async';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/material.dart';
import 'native_battery_service.dart';

/// 배터리 정보를 관리하는 서비스 클래스
class BatteryService {
  static final BatteryService _instance = BatteryService._internal();
  factory BatteryService() => _instance;
  BatteryService._internal();

  final Battery _battery = Battery();
  StreamSubscription<BatteryState>? _batteryStateSubscription;
  
  // 배터리 정보 스트림
  final StreamController<BatteryInfo> _batteryInfoController = 
      StreamController<BatteryInfo>.broadcast();
  
  Stream<BatteryInfo> get batteryInfoStream => _batteryInfoController.stream;
  
  /// 배터리 정보 모델
  BatteryInfo? _currentBatteryInfo;
  BatteryInfo? get currentBatteryInfo => _currentBatteryInfo;

  /// 배터리 모니터링 시작
  Future<void> startMonitoring() async {
    try {
      // 초기 배터리 정보 가져오기
      await _updateBatteryInfo();
      
      // 배터리 상태 변화 감지
      _batteryStateSubscription = _battery.onBatteryStateChanged.listen(
        (BatteryState state) async {
          await _updateBatteryInfo();
        },
      );
    } catch (e) {
      debugPrint('배터리 모니터링 시작 실패: $e');
    }
  }

  /// 배터리 모니터링 중지
  void stopMonitoring() {
    _batteryStateSubscription?.cancel();
    _batteryStateSubscription = null;
  }

  /// 배터리 정보 업데이트
  Future<void> _updateBatteryInfo() async {
    try {
      final batteryLevel = await _battery.batteryLevel;
      final batteryState = await _battery.batteryState;
      
      // 배터리 레벨을 더 정확하게 계산 (소숫점 포함)
      double preciseLevel = batteryLevel.toDouble();
      
      // 네이티브 배터리 정보 가져오기
      final temperature = await NativeBatteryService.getBatteryTemperature();
      final voltage = await NativeBatteryService.getBatteryVoltage();
      final capacity = await NativeBatteryService.getBatteryCapacity();
      final health = await NativeBatteryService.getBatteryHealth();
      
      _currentBatteryInfo = BatteryInfo(
        level: preciseLevel,
        state: batteryState,
        timestamp: DateTime.now(),
        temperature: temperature,
        voltage: voltage,
        capacity: capacity,
        health: health,
      );
      
      _batteryInfoController.add(_currentBatteryInfo!);
      
      debugPrint('배터리 정보 업데이트: ${preciseLevel.toStringAsFixed(1)}%, 상태: $batteryState, 온도: ${temperature.toStringAsFixed(1)}°C');
    } catch (e) {
      debugPrint('배터리 정보 업데이트 실패: $e');
    }
  }

  /// 수동으로 배터리 정보 새로고침
  Future<void> refreshBatteryInfo() async {
    await _updateBatteryInfo();
  }

  /// 리소스 정리
  void dispose() {
    stopMonitoring();
    _batteryInfoController.close();
  }
}

/// 배터리 정보 모델
class BatteryInfo {
  final double level; // 배터리 레벨 (0.0 ~ 100.0)
  final BatteryState state; // 배터리 상태
  final DateTime timestamp; // 정보 수집 시간
  final double temperature; // 배터리 온도 (섭씨)
  final int voltage; // 배터리 전압 (mV)
  final int capacity; // 배터리 용량
  final int health; // 배터리 건강도

  BatteryInfo({
    required this.level,
    required this.state,
    required this.timestamp,
    required this.temperature,
    required this.voltage,
    required this.capacity,
    required this.health,
  });

  /// 배터리 레벨을 소숫점 한자리까지 포맷팅
  String get formattedLevel => '${level.toStringAsFixed(1)}%';
  
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
  
  /// 배터리 레벨에 따른 색상 반환
  Color get levelColor {
    if (level > 50) return Colors.green;
    if (level > 20) return Colors.orange;
    return Colors.red;
  }
  
  /// 배터리 온도에 따른 색상 반환
  Color get temperatureColor {
    if (temperature < 0) return Colors.grey; // 온도 정보 없음
    if (temperature < 30) return Colors.blue; // 낮은 온도
    if (temperature < 40) return Colors.green; // 정상 온도
    if (temperature < 50) return Colors.orange; // 높은 온도
    return Colors.red; // 위험 온도
  }
  
  /// 배터리 레벨에 따른 아이콘 반환
  IconData get levelIcon {
    if (level > 75) return Icons.battery_6_bar;
    if (level > 50) return Icons.battery_4_bar;
    if (level > 25) return Icons.battery_2_bar;
    return Icons.battery_1_bar;
  }
}
