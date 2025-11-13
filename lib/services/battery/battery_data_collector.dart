import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../native_battery_service.dart';

/// 배터리 정보 수집을 담당하는 클래스
/// 
/// 네이티브 및 플러그인을 통해 배터리 정보를 수집하고,
/// 폴백 메커니즘을 제공합니다.
class BatteryDataCollector {
  final Battery _battery = Battery();

  /// 네이티브 배터리 정보 가져오기 (우선 사용)
  /// 
  /// 네이티브 서비스를 통해 상세한 배터리 정보를 수집합니다.
  /// 네이티브 정보가 실패하면 null을 반환합니다.
  /// 
  /// Returns: 배터리 정보 또는 null (실패 시)
  Future<BatteryInfo?> getNativeBatteryInfo() async {
    try {
      debugPrint('네이티브 배터리 정보 수집 시작...');
      
      // 모든 네이티브 정보를 병렬로 가져오기
      final futures = await Future.wait([
        NativeBatteryService.getBatteryLevel(),
        NativeBatteryService.getBatteryTemperature(),
        NativeBatteryService.getBatteryVoltage(),
        NativeBatteryService.getBatteryCapacity(),
        NativeBatteryService.getBatteryHealth(),
        NativeBatteryService.getChargingInfo(),
      ]);
      
      final nativeLevel = futures[0] as double;
      final temperature = futures[1] as double;
      final voltage = futures[2] as int;
      final capacity = futures[3] as int;
      final health = futures[4] as int;
      final chargingInfo = futures[5] as Map<String, dynamic>;
      
      // 네이티브 레벨이 유효한지 확인
      if (nativeLevel < 0) {
        debugPrint('네이티브 레벨이 유효하지 않음: $nativeLevel');
        return null;
      }
      
      // 플러그인에서 기본 상태 정보 가져오기
      final batteryState = await _battery.batteryState;
      
      final batteryInfo = BatteryInfo(
        level: nativeLevel,
        state: batteryState,
        timestamp: DateTime.now(),
        temperature: temperature,
        voltage: voltage,
        capacity: capacity,
        health: health,
        chargingType: chargingInfo['chargingType'] ?? 'Unknown',
        chargingCurrent: chargingInfo['chargingCurrent'] ?? -1,
        isCharging: chargingInfo['isCharging'] ?? (batteryState == BatteryState.charging),
      );
      
      debugPrint('네이티브 배터리 정보 수집 완료: ${batteryInfo.formattedLevel}');
      return batteryInfo;
      
    } catch (e) {
      debugPrint('네이티브 배터리 정보 수집 실패: $e');
      return null;
    }
  }

  /// 플러그인 배터리 정보 가져오기 (폴백)
  /// 
  /// battery_plus 플러그인을 통해 기본 배터리 정보를 수집합니다.
  /// 네이티브 정보가 실패했을 때 사용됩니다.
  /// 
  /// Returns: 배터리 정보 또는 null (실패 시)
  Future<BatteryInfo?> getPluginBatteryInfo() async {
    try {
      debugPrint('플러그인 배터리 정보 수집 시작...');
      
      final batteryLevel = await _battery.batteryLevel;
      final batteryState = await _battery.batteryState;
      
      final batteryInfo = BatteryInfo(
        level: batteryLevel.toDouble(),
        state: batteryState,
        timestamp: DateTime.now(),
        temperature: -1.0,
        voltage: -1,
        capacity: -1,
        health: -1,
        chargingType: 'Unknown',
        chargingCurrent: -1,
        isCharging: batteryState == BatteryState.charging,
      );
      
      debugPrint('플러그인 배터리 정보 수집 완료: ${batteryInfo.formattedLevel}');
      return batteryInfo;
      
    } catch (e) {
      debugPrint('플러그인 배터리 정보 수집 실패: $e');
      return null;
    }
  }

  /// 최소한의 배터리 정보 가져오기 (최종 폴백)
  /// 
  /// 모든 수집 방법이 실패했을 때 사용되는 최소한의 배터리 정보를 반환합니다.
  /// 플러그인 정보 수집도 실패하면 빈 정보를 반환합니다.
  /// 
  /// Returns: 최소한의 배터리 정보
  Future<BatteryInfo> getMinimalBatteryInfo() async {
    try {
      final batteryLevel = await _battery.batteryLevel;
      final batteryState = await _battery.batteryState;
      
      final batteryInfo = BatteryInfo(
        level: batteryLevel.toDouble(),
        state: batteryState,
        timestamp: DateTime.now(),
        temperature: -1.0,
        voltage: -1,
        capacity: -1,
        health: -1,
        chargingType: 'Unknown',
        chargingCurrent: -1,
        isCharging: batteryState == BatteryState.charging,
      );
      
      debugPrint('최소 배터리 정보 수집 완료: ${batteryInfo.formattedLevel}');
      return batteryInfo;
      
    } catch (fallbackError) {
      debugPrint('최종 폴백도 실패: $fallbackError');
      // 완전히 실패한 경우에도 빈 정보라도 반환
      return BatteryInfo(
        level: 0.0,
        state: BatteryState.unknown,
        timestamp: DateTime.now(),
        temperature: -1.0,
        voltage: -1,
        capacity: -1,
        health: -1,
        chargingType: 'Unknown',
        chargingCurrent: -1,
        isCharging: false,
      );
    }
  }

  /// 배터리 정보 수집 (자동 폴백)
  /// 
  /// 네이티브 정보를 먼저 시도하고, 실패하면 플러그인 정보로 폴백합니다.
  /// 
  /// Returns: 배터리 정보 또는 null (모든 방법 실패 시)
  Future<BatteryInfo?> collectBatteryInfo() async {
    // 네이티브 정보를 우선적으로 가져오기
    BatteryInfo? batteryInfo = await getNativeBatteryInfo();
    
    // 네이티브 정보가 실패한 경우 플러그인 정보로 폴백
    if (batteryInfo == null) {
      debugPrint('네이티브 정보 실패, 플러그인 정보로 폴백');
      batteryInfo = await getPluginBatteryInfo();
    }
    
    return batteryInfo;
  }
}

