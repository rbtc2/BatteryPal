import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../notification_service.dart';
import '../settings_service.dart';

/// 배터리 알림 관리를 담당하는 클래스
/// 
/// 충전 완료 알림, 충전 퍼센트 알림을 관리하고,
/// 충전 타입 필터링 및 중복 알림 방지를 수행합니다.
class BatteryNotificationManager {
  // 충전 완료 알림 관련
  bool _hasNotifiedChargingComplete = false; // 중복 알림 방지
  
  // 충전 퍼센트 알림 관련
  final Map<double, bool> _chargingPercentNotified = {}; // 각 퍼센트별 알림 여부 추적
  
  // 설정 서비스 (선택적)
  SettingsService? _settingsService;
  
  /// SettingsService 설정
  void setSettingsService(SettingsService? settingsService) {
    _settingsService = settingsService;
  }
  
  /// 충전 타입이 알림 대상인지 확인
  /// 
  /// [chargingType]: 충전 타입 (AC/USB/Wireless)
  /// [notifyOnFastCharging]: 고속 충전 알림 여부
  /// [notifyOnNormalCharging]: 일반 충전 알림 여부
  /// 
  /// Returns: 알림 대상이면 true, 그렇지 않으면 false
  bool shouldNotifyForChargingType(
    String chargingType,
    bool notifyOnFastCharging,
    bool notifyOnNormalCharging,
  ) {
    // 둘 다 false면 알림 안 함
    if (!notifyOnFastCharging && !notifyOnNormalCharging) {
      return false;
    }
    
    // 둘 다 true면 모든 타입 알림
    if (notifyOnFastCharging && notifyOnNormalCharging) {
      return true;
    }
    
    // AC는 고속 충전, USB/Wireless는 일반 충전
    final isFastCharging = chargingType == 'AC';
    final isNormalCharging = chargingType == 'USB' || chargingType == 'Wireless';
    
    if (notifyOnFastCharging && isFastCharging) {
      return true;
    }
    
    if (notifyOnNormalCharging && isNormalCharging) {
      return true;
    }
    
    return false;
  }

  /// 충전 완료 알림 체크 및 표시
  /// 
  /// [batteryInfo]: 현재 배터리 정보
  /// [previousLevel]: 이전 배터리 레벨
  /// [wasCharging]: 이전 충전 상태
  Future<void> checkChargingCompleteNotification(
    BatteryInfo batteryInfo,
    double previousLevel,
    bool wasCharging,
  ) async {
    // 설정이 없으면 알림 안 함
    if (_settingsService == null) {
      return;
    }
    
    // 충전 완료 알림이 비활성화되어 있으면 알림 안 함
    if (!_settingsService!.appSettings.chargingCompleteNotificationEnabled) {
      return;
    }
    
    // 충전 타입 필터 확인
    final shouldNotify = shouldNotifyForChargingType(
      batteryInfo.chargingType,
      _settingsService!.appSettings.chargingCompleteNotifyOnFastCharging,
      _settingsService!.appSettings.chargingCompleteNotifyOnNormalCharging,
    );
    
    if (!shouldNotify) {
      return;
    }
    
    // 이미 알림을 보냈으면 다시 보내지 않음
    if (_hasNotifiedChargingComplete) {
      return;
    }
    
    // 조건 확인:
    // 1. 현재 충전 중이어야 함
    // 2. 배터리 레벨이 100%여야 함
    // 3. 이전 레벨이 100% 미만이어야 함 (100%에 도달한 순간 감지)
    if (batteryInfo.isCharging &&
        batteryInfo.level >= 100.0 &&
        previousLevel < 100.0) {
      try {
        await NotificationService().showChargingCompleteNotification();
        _hasNotifiedChargingComplete = true;
        debugPrint('충전 완료 알림 표시됨');
      } catch (e) {
        debugPrint('충전 완료 알림 표시 실패: $e');
      }
    }
    
    // 배터리 레벨이 100% 미만으로 떨어지면 알림 플래그 리셋 (다시 충전 시 알림 가능하도록)
    if (batteryInfo.level < 100.0) {
      _hasNotifiedChargingComplete = false;
    }
  }

  /// 충전 퍼센트 알림 체크 및 표시
  /// 
  /// [batteryInfo]: 현재 배터리 정보
  /// [previousLevel]: 이전 배터리 레벨
  Future<void> checkChargingPercentNotification(
    BatteryInfo batteryInfo,
    double previousLevel,
  ) async {
    // 설정이 없으면 알림 안 함
    if (_settingsService == null) {
      return;
    }
    
    // 충전 퍼센트 알림이 비활성화되어 있으면 알림 안 함
    if (!_settingsService!.appSettings.chargingPercentNotificationEnabled) {
      return;
    }
    
    // 충전 중이 아니면 알림 안 함
    if (!batteryInfo.isCharging) {
      // 충전 종료 시 알림 플래그 리셋
      _chargingPercentNotified.clear();
      return;
    }
    
    // 알림 받을 퍼센트 목록이 비어있으면 알림 안 함
    final thresholds = _settingsService!.appSettings.chargingPercentThresholds;
    if (thresholds.isEmpty) {
      return;
    }
    
    // 충전 타입 필터 확인
    final shouldNotify = shouldNotifyForChargingType(
      batteryInfo.chargingType,
      _settingsService!.appSettings.chargingPercentNotifyOnFastCharging,
      _settingsService!.appSettings.chargingPercentNotifyOnNormalCharging,
    );
    
    if (!shouldNotify) {
      return;
    }
    
    // 각 임계값에 대해 확인
    for (final threshold in thresholds) {
      // 현재 레벨이 임계값 이상이고, 이전 레벨이 임계값 미만인 경우 알림
      if (batteryInfo.level >= threshold && previousLevel < threshold) {
        // 이미 알림을 보낸 퍼센트인지 확인
        if (!(_chargingPercentNotified[threshold] ?? false)) {
          try {
            await NotificationService().showChargingPercentNotification(threshold.toInt());
            _chargingPercentNotified[threshold] = true;
            debugPrint('충전 퍼센트 알림 표시됨: ${threshold.toInt()}%');
          } catch (e) {
            debugPrint('충전 퍼센트 알림 표시 실패: $e');
          }
        }
      }
      
      // 레벨이 임계값 미만으로 떨어지면 알림 플래그 리셋
      if (batteryInfo.level < threshold) {
        _chargingPercentNotified[threshold] = false;
      }
    }
  }
  
  /// 알림 플래그 리셋 (충전 시작/종료 시 호출)
  void resetNotificationFlags() {
    _hasNotifiedChargingComplete = false;
    _chargingPercentNotified.clear();
  }
  
  /// 리소스 정리
  void dispose() {
    _chargingPercentNotified.clear();
    _hasNotifiedChargingComplete = false;
  }
}

