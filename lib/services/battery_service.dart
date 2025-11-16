import 'dart:async';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/material.dart';
import 'native_battery_service.dart';
import '../models/models.dart';
import 'settings_service.dart';
import 'battery/battery_info_validator.dart';
import 'battery/battery_data_collector.dart';
import 'battery/charging_current_monitor.dart';
import 'battery/battery_notification_manager.dart';

/// 배터리 정보를 관리하는 서비스 클래스
/// 
/// 이 클래스는 배터리 정보 수집, 검증, 모니터링, 알림 관리를 조합하여
/// 통합된 배터리 서비스를 제공합니다.
/// 
/// 주요 책임:
/// - 배터리 정보 스트림 관리
/// - 배터리 모니터링 생명주기 관리
/// - 분리된 서비스들 간의 조정 및 통신
/// 
/// 사용 예시:
/// ```dart
/// final batteryService = BatteryService();
/// await batteryService.startMonitoring();
/// batteryService.batteryInfoStream.listen((info) {
///   print('배터리 레벨: ${info.level}%');
/// });
/// ```
class BatteryService {
  static final BatteryService _instance = BatteryService._internal();
  factory BatteryService() => _instance;
  BatteryService._internal();

  final Battery _battery = Battery();
  StreamSubscription<BatteryState>? _batteryStateSubscription;
  
  // 배터리 정보 스트림
  StreamController<BatteryInfo>? _batteryInfoController;
  
  // 배터리 정보 검증 서비스
  final BatteryInfoValidator _validator = BatteryInfoValidator();
  
  // 배터리 정보 수집 서비스
  final BatteryDataCollector _collector = BatteryDataCollector();
  
  // 충전 전류 모니터링 서비스
  final ChargingCurrentMonitor _chargingCurrentMonitor = ChargingCurrentMonitor();
  
  // 알림 관리 서비스
  final BatteryNotificationManager _notificationManager = BatteryNotificationManager();
  
  /// SettingsService 설정 (선택적)
  void setSettingsService(SettingsService? settingsService) {
    _notificationManager.setSettingsService(settingsService);
  }
  
  Stream<BatteryInfo> get batteryInfoStream {
    if (_batteryInfoController == null || _batteryInfoController!.isClosed) {
      _batteryInfoController = StreamController<BatteryInfo>.broadcast();
      _debugLog('배터리 서비스: 새로운 스트림 컨트롤러 생성');
    }
    return _batteryInfoController!.stream;
  }
  
  // ==================== 상태 관리 ====================
  
  /// 현재 배터리 정보
  BatteryInfo? _currentBatteryInfo;
  
  /// 현재 배터리 정보 가져오기
  BatteryInfo? get currentBatteryInfo => _currentBatteryInfo;
  
  // ==================== 공개 API ====================
  
  /// 안정화된 충전 전류 가져오기 (이동 평균 사용)
  /// 
  /// 최근 측정값들의 평균을 사용하여 노이즈를 줄인 충전 전류를 반환합니다.
  int getStableChargingCurrent() {
    return _chargingCurrentMonitor.getStableChargingCurrent(_currentBatteryInfo);
  }
  
  /// 중앙값 충전 전류 가져오기 (극값의 영향을 줄임)
  /// 
  /// 최근 측정값들의 중앙값을 사용하여 이상치의 영향을 최소화합니다.
  int getMedianChargingCurrent() {
    return _chargingCurrentMonitor.getMedianChargingCurrent(_currentBatteryInfo);
  }
  
  /// 충전 전류 안정성 상태 확인
  /// 
  /// Returns: 충전 전류가 안정적이면 true, 그렇지 않으면 false
  bool isChargingCurrentStable() {
    return _chargingCurrentMonitor.isChargingCurrentStable();
  }
  
  /// 최근 충전 전류 측정값 개수
  int get recentChargingCurrentCount => _chargingCurrentMonitor.recentChargingCurrentCount;
  
  // ==================== 내부 상태 ====================
  
  /// 서비스가 dispose되었는지 확인하는 플래그
  bool _isDisposed = false;
  
  /// 업데이트 중인지 확인하는 플래그 (중복 업데이트 방지)
  bool _isUpdating = false;
  
  // ==================== 유틸리티 메서드 ====================
  
  /// 성능 최적화를 위한 로그 레벨 관리
  static const bool _enableDebugLogs = false; // 릴리즈 빌드에서는 false
  
  /// 디버그 로그 출력 (조건부)
  void _debugLog(String message) {
    if (_enableDebugLogs) {
      debugPrint(message);
    }
  }
  
  /// 안전하게 스트림에 이벤트 추가 (Phase 3: 이벤트 필터링 추가)
  /// 의미있는 변화가 있을 때만 이벤트를 전달하여 불필요한 업데이트를 방지합니다.
  void _safeAddEvent(BatteryInfo batteryInfo) {
    if (!_isDisposed && _batteryInfoController != null && !_batteryInfoController!.isClosed) {
      try {
        // Phase 3: 이벤트 필터링 - 의미있는 변화가 있을 때만 전달
        if (_shouldEmitEvent(batteryInfo)) {
          _batteryInfoController!.add(batteryInfo);
          _debugLog('배터리 정보 스트림에 추가됨: ${batteryInfo.formattedLevel}');
        } else {
          _debugLog('배터리 정보 변화가 없어 이벤트 건너뜀: ${batteryInfo.formattedLevel}');
        }
      } catch (e) {
        debugPrint('스트림에 이벤트 추가 실패: $e');
      }
    } else {
      _debugLog('스트림이 닫혔거나 서비스가 dispose됨, 이벤트 추가 건너뜀');
    }
  }
  
  /// Phase 3: 이벤트를 전달해야 하는지 확인
  /// 의미있는 변화가 있을 때만 true를 반환합니다.
  bool _shouldEmitEvent(BatteryInfo newInfo) {
    final previousInfo = _currentBatteryInfo;
    
    // 첫 업데이트는 항상 전달
    if (previousInfo == null) {
      return true;
    }
    
    // 충전 상태 변화는 항상 전달
    if (previousInfo.isCharging != newInfo.isCharging) {
      return true;
    }
    
    // 배터리 레벨 변화 (0.5% 이상)는 전달
    final levelDiff = (newInfo.level - previousInfo.level).abs();
    if (levelDiff >= 0.5) {
      return true;
    }
    
    // 충전 중일 때 충전 전류 변화 (50mA 이상)는 전달
    if (newInfo.isCharging && previousInfo.isCharging) {
      final currentDiff = (newInfo.chargingCurrent - previousInfo.chargingCurrent).abs();
      if (currentDiff >= 50) {
        return true;
      }
    }
    
    // 온도 변화 (2°C 이상)는 전달
    if (newInfo.temperature != -1.0 && previousInfo.temperature != -1.0) {
      final tempDiff = (newInfo.temperature - previousInfo.temperature).abs();
      if (tempDiff >= 2.0) {
        return true;
      }
    }
    
    // 전압 변화 (50mV 이상)는 전달
    if (newInfo.voltage != -1 && previousInfo.voltage != -1) {
      final voltageDiff = (newInfo.voltage - previousInfo.voltage).abs();
      if (voltageDiff >= 50) {
        return true;
      }
    }
    
    // 의미있는 변화가 없으면 전달하지 않음
    return false;
  }

  // ==================== 모니터링 관리 ====================
  
  /// 배터리 모니터링 시작
  /// 
  /// 배터리 상태 변화를 감지하고, 충전 전류 모니터링 및 알림을 시작합니다.
  /// 
  /// Throws: 모니터링 시작 실패 시 예외 발생
  Future<void> startMonitoring() async {
    if (_isDisposed) {
      debugPrint('서비스가 이미 dispose됨, 모니터링 시작 건너뜀');
      return;
    }
    
    try {
      debugPrint('배터리 모니터링 시작...');
      
      // 충전 전류 모니터 콜백 설정
      _chargingCurrentMonitor.setCallbacks(
        onChargingCurrentUpdate: (updatedInfo) {
          _currentBatteryInfo = updatedInfo;
          _safeAddEvent(updatedInfo);
        },
        isDisposed: () => _isDisposed,
        getCurrentBatteryInfo: () => _currentBatteryInfo,
      );
      
      // 기존 구독 정리
      await _batteryStateSubscription?.cancel();
      _batteryStateSubscription = null;
      
      // 네이티브 배터리 상태 변화 리스너 초기화 (실시간 감지)
      NativeBatteryService.initializeBatteryStateListener(_handleNativeBatteryStateChange);
      
      // 초기 배터리 정보 강제 업데이트
      await _updateBatteryInfo(forceUpdate: true);
      
      // 배터리 상태 변화 감지 (디바운싱 적용)
      _batteryStateSubscription = _battery.onBatteryStateChanged.listen(
        (BatteryState state) async {
          if (!_isDisposed && _validator.shouldUpdate()) {
            debugPrint('배터리 상태 변화 감지: $state');
            await _updateBatteryInfo();
            
            // 충전 상태 변화 시 충전 전류 모니터링 시작/중지
            if (state == BatteryState.charging) {
              _chargingCurrentMonitor.startMonitoring();
            } else {
              _chargingCurrentMonitor.stopMonitoring();
            }
          }
        },
        onError: (error) {
          debugPrint('배터리 상태 변화 감지 오류: $error');
        },
      );
      
      // 초기 충전 상태 확인하여 충전 전류 모니터링 시작
      if (_currentBatteryInfo?.isCharging == true) {
        _chargingCurrentMonitor.startMonitoring();
      }
      
      debugPrint('배터리 모니터링 시작 완료');
    } catch (e, stackTrace) {
      debugPrint('배터리 모니터링 시작 실패: $e');
      debugPrint('스택 트레이스: $stackTrace');
      rethrow;
    }
  }

  // ==================== 이벤트 핸들러 ====================
  
  /// 충전 상태 변화 처리 (헬퍼 메서드)
  /// 
  /// 충전 상태 변화에 따라 충전 전류 모니터링을 시작/중지하고,
  /// 알림을 체크합니다.
  Future<void> _handleChargingStateChange(
    BatteryInfo batteryInfo,
    bool wasCharging,
    double previousLevel,
  ) async {
    if (batteryInfo.isCharging && !wasCharging) {
      // 충전 시작
      debugPrint('충전 시작 감지 - 충전 전류 모니터링 시작');
      _chargingCurrentMonitor.startMonitoring();
      _notificationManager.resetNotificationFlags();
    } else if (!batteryInfo.isCharging && wasCharging) {
      // 충전 종료
      debugPrint('충전 종료 감지 - 충전 전류 모니터링 중지');
      _chargingCurrentMonitor.stopMonitoring();
      await _chargingCurrentMonitor.flushBuffer();
      _notificationManager.resetNotificationFlags();
    }
    
    // 알림 체크
    await _notificationManager.checkChargingCompleteNotification(
      batteryInfo,
      previousLevel,
      wasCharging,
    );
    await _notificationManager.checkChargingPercentNotification(
      batteryInfo,
      previousLevel,
    );
  }
  
  /// 네이티브에서 오는 배터리 상태 변화 즉시 처리
  /// 
  /// 네이티브 서비스에서 실시간으로 전달되는 충전 정보를 처리합니다.
  Future<void> _handleNativeBatteryStateChange(Map<String, dynamic> chargingInfo) async {
    if (_isDisposed) {
      debugPrint('서비스가 이미 dispose됨, 네이티브 배터리 상태 변화 처리 건너뜀');
      return;
    }
    
    try {
      debugPrint('네이티브 배터리 상태 변화 즉시 처리: $chargingInfo');
      
      // 기존 배터리 정보의 레벨을 유지하면서 충전 정보만 업데이트
      final wasCharging = _currentBatteryInfo?.isCharging ?? false;
      final currentLevel = _currentBatteryInfo?.level ?? 0.0;
      final currentTemperature = _currentBatteryInfo?.temperature ?? -1.0;
      final currentVoltage = _currentBatteryInfo?.voltage ?? -1;
      final currentCapacity = _currentBatteryInfo?.capacity ?? -1;
      final currentHealth = _currentBatteryInfo?.health ?? -1;
      
      // 충전 정보를 BatteryInfo로 변환하되 기존 정보 유지
      final batteryInfo = BatteryInfo.fromChargingInfoWithExistingData(
        chargingInfo,
        level: currentLevel,
        temperature: currentTemperature,
        voltage: currentVoltage,
        capacity: currentCapacity,
        health: currentHealth,
      );
      
      if (_validator.isValidBatteryInfo(batteryInfo)) {
        final previousLevel = _currentBatteryInfo?.level ?? 0.0;
        _currentBatteryInfo = batteryInfo;
        
        // 즉시 스트림에 이벤트 추가 (디바운싱 없이)
        _safeAddEvent(batteryInfo);
        
        // 충전 상태 변화 처리
        await _handleChargingStateChange(batteryInfo, wasCharging, previousLevel);
        
        debugPrint('네이티브 배터리 상태 변화 처리 완료: ${batteryInfo.formattedLevel}');
      } else {
        debugPrint('네이티브 배터리 정보가 유효하지 않아 처리 건너뜀');
      }
    } catch (e, stackTrace) {
      debugPrint('네이티브 배터리 상태 변화 처리 실패: $e');
      debugPrint('스택 트레이스: $stackTrace');
    }
  }

  /// 배터리 모니터링 중지
  /// 
  /// 모든 모니터링을 중지하고 리소스를 정리합니다.
  void stopMonitoring() {
    _batteryStateSubscription?.cancel();
    _batteryStateSubscription = null;
    
    // 충전 전류 모니터링도 중지
    _chargingCurrentMonitor.stopMonitoring();
    
    // 남은 충전 전류 데이터 저장
    _chargingCurrentMonitor.flushBuffer();
  }

  // ==================== 배터리 정보 업데이트 ====================
  
  /// 배터리 정보 업데이트
  /// 
  /// 배터리 정보를 수집하고 검증한 후, 상태 변화에 따라
  /// 충전 전류 모니터링 및 알림을 처리합니다.
  /// 
  /// [forceUpdate]: true이면 업데이트 간격 검증을 건너뜁니다.
  Future<void> _updateBatteryInfo({bool forceUpdate = false}) async {
    if (_isDisposed) {
      debugPrint('서비스가 이미 dispose됨, 배터리 정보 업데이트 건너뜀');
      return;
    }
    
    // 중복 업데이트 방지
    if (_isUpdating && !forceUpdate) {
      debugPrint('이미 업데이트 중이므로 건너뜀');
      return;
    }
    
    // 업데이트 간격 검증 (강제 업데이트가 아닌 경우)
    if (!forceUpdate && !_validator.shouldUpdate()) {
      debugPrint('업데이트 간격이 너무 짧아서 건너뜀');
      return;
    }
    
    _isUpdating = true;
    _validator.setLastUpdateTime(DateTime.now());
    
    try {
      debugPrint('배터리 정보 업데이트 시작... (강제: $forceUpdate)');
      
      // 배터리 정보 수집 (자동 폴백)
      BatteryInfo? batteryInfo = await _collector.collectBatteryInfo();
      
      // 최종 검증 및 업데이트
      if (batteryInfo != null && _validator.isValidBatteryInfo(batteryInfo)) {
        final wasCharging = _currentBatteryInfo?.isCharging ?? false;
        final previousLevel = _currentBatteryInfo?.level ?? 0.0;
        _currentBatteryInfo = batteryInfo;
        _safeAddEvent(batteryInfo);
        
        // 충전 상태 변화 처리
        await _handleChargingStateChange(batteryInfo, wasCharging, previousLevel);
        
        debugPrint('배터리 정보 업데이트 완료: ${batteryInfo.formattedLevel}');
      } else {
        debugPrint('배터리 정보가 유효하지 않아 업데이트 건너뜀');
      }
      
    } catch (e, stackTrace) {
      debugPrint('배터리 정보 업데이트 실패: $e');
      debugPrint('스택 트레이스: $stackTrace');
      
      // 최종 폴백: 최소한의 배터리 정보라도 표시
      final fallbackInfo = await _collector.getMinimalBatteryInfo();
      _currentBatteryInfo = fallbackInfo;
      _safeAddEvent(fallbackInfo);
      debugPrint('최소 배터리 정보로 폴백: ${fallbackInfo.formattedLevel}');
    } finally {
      _isUpdating = false;
    }
  }
  
  // ==================== 공개 메서드 ====================
  
  /// 수동으로 배터리 정보 새로고침
  /// 
  /// 사용자가 명시적으로 배터리 정보를 새로고침할 때 사용합니다.
  Future<void> refreshBatteryInfo() async {
    if (_isDisposed) {
      debugPrint('서비스가 이미 dispose됨, 배터리 정보 새로고침 건너뜀');
      return;
    }
    
    debugPrint('수동 배터리 정보 새로고침 시작...');
    await _updateBatteryInfo(forceUpdate: true);
  }
  
  // ==================== 생명주기 관리 ====================
  
  /// 배터리 서비스 상태 초기화 (앱 시작 시 호출)
  /// 
  /// 모든 상태를 초기화하고 스트림 컨트롤러를 재생성합니다.
  Future<void> resetService() async {
    debugPrint('배터리 서비스 상태 초기화...');
    
    // 기존 정보 초기화
    _currentBatteryInfo = null;
    _validator.resetLastUpdateTime();
    _isUpdating = false;
    
    // 충전 전류 모니터 초기화
    _chargingCurrentMonitor.reset();
    
    // 알림 플래그 초기화
    _notificationManager.resetNotificationFlags();
    
    // 기존 구독 정리
    await _batteryStateSubscription?.cancel();
    _batteryStateSubscription = null;
    
    // 충전 전류 모니터링 중지
    _chargingCurrentMonitor.stopMonitoring();
    
    // 스트림 컨트롤러 재생성
    if (_batteryInfoController != null && !_batteryInfoController!.isClosed) {
      _batteryInfoController!.close();
    }
    _batteryInfoController = null;
    
    debugPrint('배터리 서비스 상태 초기화 완료');
  }

  /// 리소스 정리
  /// 
  /// 모든 모니터링을 중지하고 리소스를 해제합니다.
  /// 앱 종료 시 반드시 호출해야 합니다.
  void dispose() {
    debugPrint('배터리 서비스 dispose 시작...');
    _isDisposed = true;
    stopMonitoring();
    
    if (_batteryInfoController != null && !_batteryInfoController!.isClosed) {
      _batteryInfoController!.close();
    }
    _batteryInfoController = null;
    
    _currentBatteryInfo = null;
    _validator.resetLastUpdateTime();
    _isUpdating = false;
    
    // 충전 전류 모니터 정리
    _chargingCurrentMonitor.dispose();
    
    // 알림 관리자 정리
    _notificationManager.dispose();
    
    debugPrint('배터리 서비스 dispose 완료');
  }
}
