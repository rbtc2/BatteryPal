import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../notification_service.dart';
import '../settings_service.dart';

/// 배터리 알림 관리를 담당하는 클래스
/// 
/// 충전 완료 알림, 충전 퍼센트 알림, 과충전 방지 알림을 관리하고,
/// 충전 타입 필터링 및 중복 알림 방지를 수행합니다.
class BatteryNotificationManager {
  // 충전 완료 알림 관련
  bool _hasNotifiedChargingComplete = false; // 중복 알림 방지
  
  // 충전 퍼센트 알림 관련
  final Map<double, bool> _chargingPercentNotified = {}; // 각 퍼센트별 알림 여부 추적
  
  // 과충전 방지 알림 관련
  DateTime? _hundredPercentReachedTime; // 100% 도달 시간
  String? _detectedChargingSpeed; // 감지된 충전 속도
  final Set<int> _overchargeAlertsSent = {}; // 전송된 과충전 알림 단계 추적
  Timer? _overchargeCheckTimer; // 과충전 체크 타이머
  BatteryInfo? _lastBatteryInfoForOverchargeCheck; // 과충전 체크용 마지막 배터리 정보
  bool _overchargeAlertsDisabled = false; // 이번 충전 세션 동안 알림 비활성화
  DateTime? _remindAfterTime; // 5분 후 다시 알림 시간
  
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
    try {
      // 설정이 없으면 알림 안 함
      final settings = _settingsService;
      if (settings == null) {
        return;
      }
      
      // 충전 완료 알림이 비활성화되어 있으면 알림 안 함
      if (!settings.appSettings.chargingCompleteNotificationEnabled) {
        return;
      }
      
      // 충전 타입 필터 확인
      final shouldNotify = shouldNotifyForChargingType(
        batteryInfo.chargingType,
        settings.appSettings.chargingCompleteNotifyOnFastCharging,
        settings.appSettings.chargingCompleteNotifyOnNormalCharging,
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
          
          // 100% 도달 시 과충전 추적 시작
          _hundredPercentReachedTime = DateTime.now();
          _detectedChargingSpeed = _getChargingSpeedType(batteryInfo.chargingCurrent);
          _overchargeAlertsSent.clear();
          _lastBatteryInfoForOverchargeCheck = batteryInfo;
          _startOverchargeCheckTimer();
          debugPrint('과충전 추적 시작 - 충전 속도: $_detectedChargingSpeed');
        } catch (e, stackTrace) {
          debugPrint('충전 완료 알림 표시 실패: $e');
          debugPrint('스택 트레이스: $stackTrace');
        }
      }
      
      // 배터리 레벨이 100% 미만으로 떨어지면 알림 플래그 리셋 (다시 충전 시 알림 가능하도록)
      if (batteryInfo.level < 100.0) {
        _hasNotifiedChargingComplete = false;
        _resetOverchargeTracking();
      }
    } catch (e, stackTrace) {
      debugPrint('충전 완료 알림 체크 중 에러 발생: $e');
      debugPrint('스택 트레이스: $stackTrace');
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
  
  /// 개발자 모드 충전 시작/종료 알림 체크 및 표시
  /// 
  /// [batteryInfo]: 현재 배터리 정보
  /// [wasCharging]: 이전 충전 상태
  Future<void> checkDeveloperModeChargingNotification(
    BatteryInfo batteryInfo,
    bool wasCharging,
  ) async {
    // 설정이 없으면 알림 안 함
    if (_settingsService == null) {
      return;
    }
    
    // 개발자 모드 충전 테스트가 비활성화되어 있으면 알림 안 함
    if (!_settingsService!.appSettings.developerModeChargingTestEnabled) {
      return;
    }
    
    // 충전 시작 감지: 이전에는 충전 중이 아니었고, 현재는 충전 중
    if (batteryInfo.isCharging && !wasCharging) {
      try {
        await NotificationService().showChargingStartNotification(
          chargingType: batteryInfo.chargingType,
        );
        debugPrint('개발자 모드: 충전 시작 알림 표시됨 (타입: ${batteryInfo.chargingType})');
      } catch (e) {
        debugPrint('개발자 모드: 충전 시작 알림 표시 실패: $e');
      }
    }
    
    // 충전 종료 감지: 이전에는 충전 중이었고, 현재는 충전 중이 아님
    if (!batteryInfo.isCharging && wasCharging) {
      try {
        await NotificationService().showChargingEndNotification(
          batteryLevel: batteryInfo.level,
        );
        debugPrint('개발자 모드: 충전 종료 알림 표시됨 (배터리: ${batteryInfo.level.toInt()}%)');
      } catch (e) {
        debugPrint('개발자 모드: 충전 종료 알림 표시 실패: $e');
      }
    }
  }
  
  /// 충전 속도 타입 감지
  /// 
  /// [chargingCurrent]: 충전 전류 (mA)
  /// 
  /// Returns: 'ultra_fast', 'fast', 'normal' 중 하나
  String _getChargingSpeedType(int chargingCurrent) {
    if (chargingCurrent >= 3000) {
      return 'ultra_fast'; // 초고속 충전
    } else if (chargingCurrent >= 1500) {
      return 'fast'; // 고속 충전
    } else {
      return 'normal'; // 일반 충전
    }
  }
  
  /// 충전 속도별 과충전 알림 타이밍 가져오기 (분 단위)
  /// 
  /// [speedType]: 충전 속도 타입 ('ultra_fast', 'fast', 'normal')
  /// [batteryInfo]: 배터리 정보 (온도 확인용)
  /// 
  /// Returns: [1차 알림 시간, 2차 알림 시간, 3차 알림 시간] (분)
  List<int> _getOverchargeAlertTimings(String speedType, BatteryInfo? batteryInfo) {
    // 기본 타이밍 가져오기
    final baseTimings = _getBaseTimings(speedType);
    
    // 설정에서 알림 속도 조정 적용
    final adjustedTimings = _applySpeedAdjustment(baseTimings);
    
    // 온도 기반 조정 적용
    return _applyTemperatureAdjustment(adjustedTimings, batteryInfo);
  }
  
  /// 기본 타이밍 가져오기
  List<int> _getBaseTimings(String speedType) {
    switch (speedType) {
      case 'ultra_fast':
        return [3, 5, 10]; // 초고속: 3분, 5분, 10분
      case 'fast':
        return [5, 10, 15]; // 고속: 5분, 10분, 15분
      case 'normal':
        return [10, 20, 30]; // 일반: 10분, 20분, 30분
      default:
        return [10, 20, 30]; // 기본값: 일반 충전과 동일
    }
  }
  
  /// 알림 속도 조정 적용
  List<int> _applySpeedAdjustment(List<int> timings) {
    final settings = _settingsService;
    if (settings == null) {
      return timings;
    }
    
    final alertSpeed = settings.appSettings.overchargeAlertSpeed;
    switch (alertSpeed) {
      case 'fast':
        return timings.map((t) => (t * 0.5).round()).toList();
      case 'slow':
        return timings.map((t) => (t * 1.5).round()).toList();
      case 'normal':
      default:
        return timings;
    }
  }
  
  /// 온도 기반 조정 적용
  List<int> _applyTemperatureAdjustment(List<int> timings, BatteryInfo? batteryInfo) {
    final settings = _settingsService;
    if (settings == null || 
        !settings.appSettings.temperatureBasedAdjustment ||
        batteryInfo == null ||
        batteryInfo.temperature < 40.0) {
      return timings;
    }
    
    // 온도가 40°C 이상이면 타이밍을 50% 단축
    return timings.map((t) => (t * 0.5).round()).toList();
  }
  
  /// 과충전 체크 타이머 시작 (100% 도달 후 1분마다 체크)
  void _startOverchargeCheckTimer() {
    // 기존 타이머가 있으면 취소
    _overchargeCheckTimer?.cancel();
    _overchargeCheckTimer = null;
    
    try {
      _overchargeCheckTimer = Timer.periodic(const Duration(minutes: 1), (timer) async {
        try {
          // 추적 상태 확인
          if (_hundredPercentReachedTime == null || _detectedChargingSpeed == null) {
            timer.cancel();
            _overchargeCheckTimer = null;
            return;
          }
          
          // 마지막 배터리 정보가 있으면 체크
          final lastInfo = _lastBatteryInfoForOverchargeCheck;
          if (lastInfo != null) {
            await _checkOverchargeAlerts(lastInfo);
          }
        } catch (e, stackTrace) {
          debugPrint('과충전 체크 타이머 콜백 에러: $e');
          debugPrint('스택 트레이스: $stackTrace');
          // 에러가 발생해도 타이머는 계속 실행
        }
      });
    } catch (e) {
      debugPrint('과충전 체크 타이머 시작 실패: $e');
      _overchargeCheckTimer = null;
    }
  }
  
  /// 과충전 방지 알림 체크 및 표시
  /// 
  /// [batteryInfo]: 현재 배터리 정보
  /// 
  /// 이 메서드는 주기적으로 호출되어 100% 도달 후 경과 시간을 체크하고
  /// 적절한 시점에 과충전 경고 알림을 표시합니다.
  Future<void> checkOverchargeNotification(
    BatteryInfo batteryInfo,
  ) async {
    try {
      // 설정이 없으면 알림 안 함
      final settings = _settingsService;
      if (settings == null) {
        return;
      }
      
      // 100% 미만이거나 충전 중이 아니면 추적 중지
      if (!batteryInfo.isCharging || batteryInfo.level < 100.0) {
        _resetOverchargeTracking();
        return;
      }
      
      // 100% 도달 시간이 없으면 체크하지 않음 (아직 100%에 도달하지 않음)
      if (_hundredPercentReachedTime == null || _detectedChargingSpeed == null) {
        return;
      }
      
      // 알림 설정 확인 (한 번에 체크)
      if (!_shouldCheckOverchargeNotification(settings, batteryInfo)) {
        _resetOverchargeTracking();
        return;
      }
      
      // 마지막 배터리 정보 업데이트
      _lastBatteryInfoForOverchargeCheck = batteryInfo;
      
      // 과충전 알림 체크
      await _checkOverchargeAlerts(batteryInfo);
    } catch (e, stackTrace) {
      debugPrint('과충전 방지 알림 체크 중 에러 발생: $e');
      debugPrint('스택 트레이스: $stackTrace');
    }
  }
  
  /// 과충전 알림을 체크해야 하는지 확인
  bool _shouldCheckOverchargeNotification(SettingsService settings, BatteryInfo batteryInfo) {
    // 충전 완료 알림이 비활성화되어 있으면 과충전 알림도 안 함
    if (!settings.appSettings.chargingCompleteNotificationEnabled) {
      return false;
    }
    
    // 과충전 방지 알림이 비활성화되어 있으면 알림 안 함
    if (!settings.appSettings.overchargeProtectionEnabled) {
      return false;
    }
    
    // 충전 타입 필터 확인
    return shouldNotifyForChargingType(
      batteryInfo.chargingType,
      settings.appSettings.chargingCompleteNotifyOnFastCharging,
      settings.appSettings.chargingCompleteNotifyOnNormalCharging,
    );
  }
  
  /// 알림 액션 처리
  /// 
  /// [actionId]: 액션 ID ('dismiss', 'remind_5min', 'open_app')
  /// [payload]: 알림 페이로드
  void handleNotificationAction(String actionId, String? payload) {
    try {
      debugPrint('BatteryNotificationManager: 알림 액션 처리 - $actionId, payload: $payload');
      
      switch (actionId) {
        case 'dismiss':
          // 알림 끄기 - 이번 충전 세션 동안 알림 중지
          _overchargeAlertsDisabled = true;
          debugPrint('과충전 알림 비활성화됨 (이번 충전 세션)');
          break;
        case 'remind_5min':
          // 5분 후 다시 알림
          _remindAfterTime = DateTime.now().add(const Duration(minutes: 5));
          _overchargeAlertsSent.clear(); // 알림 플래그 리셋하여 다시 알림 가능하도록
          debugPrint('5분 후 다시 알림 예약됨: $_remindAfterTime');
          break;
        case 'open_app':
          // 앱 열기 - 기본 동작 (이미 구현됨)
          debugPrint('앱 열기');
          break;
        default:
          debugPrint('알 수 없는 액션: $actionId');
      }
    } catch (e, stackTrace) {
      debugPrint('알림 액션 처리 중 에러 발생: $e');
      debugPrint('스택 트레이스: $stackTrace');
    }
  }
  
  /// 과충전 알림 체크 (주기적으로 호출됨)
  /// 
  /// [batteryInfo]: 현재 배터리 정보
  Future<void> _checkOverchargeAlerts(BatteryInfo batteryInfo) async {
    try {
      // null 체크
      final reachedTime = _hundredPercentReachedTime;
      final speedType = _detectedChargingSpeed;
      if (reachedTime == null || speedType == null) {
        return;
      }
      
      // 충전 상태 확인
      if (!batteryInfo.isCharging || batteryInfo.level < 100.0) {
        _resetOverchargeTracking();
        return;
      }
      
      // 이번 충전 세션 동안 알림이 비활성화되어 있으면 알림 안 함
      if (_overchargeAlertsDisabled) {
        return;
      }
      
      // 5분 후 다시 알림 처리
      final now = DateTime.now();
      if (_remindAfterTime != null) {
        if (now.isBefore(_remindAfterTime!)) {
          // 아직 시간이 안 됐으면 알림 안 함
          return;
        } else {
          // 시간이 지났으면 리셋
          _remindAfterTime = null;
        }
      }
      
      // 과충전 방지 알림이 비활성화되어 있으면 알림 안 함
      if (_settingsService != null && 
          !_settingsService!.appSettings.overchargeProtectionEnabled) {
        return;
      }
      
      // 경과 시간 계산 (분)
      final elapsedMinutes = now.difference(reachedTime).inMinutes;
      
      // 음수 경과 시간 방지
      if (elapsedMinutes < 0) {
        debugPrint('경과 시간이 음수입니다. 추적 리셋.');
        _resetOverchargeTracking();
        return;
      }
      
      // 알림 타이밍 가져오기 (온도 기반 조정 포함)
      final timings = _getOverchargeAlertTimings(speedType, batteryInfo);
      
      // 타이밍이 비어있으면 리턴
      if (timings.isEmpty) {
        return;
      }
      
      // 각 단계별 알림 체크
      for (int i = 0; i < timings.length; i++) {
        final alertTime = timings[i];
        final alertLevel = i + 1; // 1, 2, 3
        
        // 경과 시간이 알림 시간에 도달했고, 아직 알림을 보내지 않았으면
        if (elapsedMinutes >= alertTime && !_overchargeAlertsSent.contains(alertLevel)) {
          try {
            final message = _getAlertMessage(alertLevel);
            
            await NotificationService().showOverchargeWarningNotification(
              minutes: elapsedMinutes,
              level: alertLevel,
              message: message,
              chargingSpeed: speedType,
              temperature: batteryInfo.temperature >= 0 ? batteryInfo.temperature : null,
            );
            
            _overchargeAlertsSent.add(alertLevel);
            debugPrint('과충전 알림 표시됨: $alertLevel단계 (경과: $elapsedMinutes분)');
          } catch (e, stackTrace) {
            debugPrint('과충전 알림 표시 실패: $e');
            debugPrint('스택 트레이스: $stackTrace');
            // 에러가 발생해도 다음 알림은 계속 체크
          }
        }
      }
    } catch (e, stackTrace) {
      debugPrint('과충전 알림 체크 중 에러 발생: $e');
      debugPrint('스택 트레이스: $stackTrace');
    }
  }
  
  /// 알림 단계별 메시지 가져오기
  String _getAlertMessage(int alertLevel) {
    switch (alertLevel) {
      case 1:
        return '충전 완료! 곧 분리해주세요';
      case 2:
        return '과충전 주의! 분리 권장';
      case 3:
        return '과충전 위험! 지금 바로 분리하세요';
      default:
        return '과충전 주의';
    }
  }
  
  /// 과충전 추적 리셋
  void _resetOverchargeTracking() {
    try {
      _hundredPercentReachedTime = null;
      _detectedChargingSpeed = null;
      _overchargeAlertsSent.clear();
      _lastBatteryInfoForOverchargeCheck = null;
      _overchargeAlertsDisabled = false; // 알림 비활성화 플래그도 리셋
      _remindAfterTime = null; // 5분 후 다시 알림 시간도 리셋
      
      // 타이머 안전하게 취소
      final timer = _overchargeCheckTimer;
      if (timer != null) {
        timer.cancel();
        _overchargeCheckTimer = null;
      }
    } catch (e) {
      debugPrint('과충전 추적 리셋 중 에러 발생: $e');
    }
  }
  
  /// 알림 플래그 리셋 (충전 시작/종료 시 호출)
  void resetNotificationFlags() {
    _hasNotifiedChargingComplete = false;
    _chargingPercentNotified.clear();
    _resetOverchargeTracking();
  }
  
  /// 리소스 정리
  void dispose() {
    try {
      _chargingPercentNotified.clear();
      _hasNotifiedChargingComplete = false;
      _resetOverchargeTracking();
      _settingsService = null;
    } catch (e) {
      debugPrint('BatteryNotificationManager dispose 중 에러 발생: $e');
    }
  }
}

