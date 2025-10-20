import 'dart:async';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/material.dart';
import 'native_battery_service.dart';
import '../models/app_models.dart';

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
      debugPrint('배터리 정보 업데이트 시작...');
      
      final batteryState = await _battery.batteryState;
      debugPrint('기본 배터리 상태: $batteryState');
      
      // 네이티브에서 더 정확한 배터리 레벨 가져오기
      final nativeLevel = await NativeBatteryService.getBatteryLevel();
      debugPrint('네이티브 배터리 레벨: $nativeLevel');
      
      double preciseLevel;
      
      if (nativeLevel >= 0) {
        // 네이티브에서 정확한 레벨을 가져온 경우
        preciseLevel = nativeLevel;
        debugPrint('네이티브 레벨 사용: $preciseLevel%');
      } else {
        // 네이티브에서 실패한 경우 기본 플러그인 사용
        final batteryLevel = await _battery.batteryLevel;
        preciseLevel = batteryLevel.toDouble();
        debugPrint('기본 플러그인 레벨 사용: $preciseLevel%');
      }
      
      // 네이티브 배터리 정보 가져오기
      debugPrint('네이티브 배터리 정보 수집 시작...');
      final temperature = await NativeBatteryService.getBatteryTemperature();
      final voltage = await NativeBatteryService.getBatteryVoltage();
      final capacity = await NativeBatteryService.getBatteryCapacity();
      final health = await NativeBatteryService.getBatteryHealth();
      final chargingInfo = await NativeBatteryService.getChargingInfo();
      
      debugPrint('네이티브 정보 - 온도: $temperature, 전압: $voltage, 용량: $capacity, 건강도: $health');
      debugPrint('충전 정보: $chargingInfo');
      
      _currentBatteryInfo = BatteryInfo(
        level: preciseLevel,
        state: batteryState,
        timestamp: DateTime.now(),
        temperature: temperature,
        voltage: voltage,
        capacity: capacity,
        health: health,
        chargingType: chargingInfo['chargingType'] ?? 'Unknown',
        chargingCurrent: chargingInfo['chargingCurrent'] ?? -1,
        isCharging: chargingInfo['isCharging'] ?? false,
      );
      
      _batteryInfoController.add(_currentBatteryInfo!);
      
      debugPrint('배터리 정보 업데이트 완료: ${preciseLevel.toStringAsFixed(2)}%, 상태: $batteryState, 온도: ${temperature.toStringAsFixed(1)}°C, 전압: ${voltage}mV, 용량: ${capacity}mAh, 건강도: $health');
    } catch (e, stackTrace) {
      debugPrint('배터리 정보 업데이트 실패: $e');
      debugPrint('스택 트레이스: $stackTrace');
      
      // 오류 발생 시에도 기본 배터리 정보라도 표시
      try {
        final batteryLevel = await _battery.batteryLevel;
        final batteryState = await _battery.batteryState;
        
        _currentBatteryInfo = BatteryInfo(
          level: batteryLevel.toDouble(),
          state: batteryState,
          timestamp: DateTime.now(),
          temperature: -1.0,
          voltage: -1,
          capacity: -1,
          health: -1,
          chargingType: 'Unknown',
          chargingCurrent: -1,
          isCharging: false,
        );
        
        _batteryInfoController.add(_currentBatteryInfo!);
        debugPrint('기본 배터리 정보로 폴백: $batteryLevel%, 상태: $batteryState');
      } catch (fallbackError) {
        debugPrint('폴백 배터리 정보도 실패: $fallbackError');
      }
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
