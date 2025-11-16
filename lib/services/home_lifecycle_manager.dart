import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/models.dart';
import 'battery_service.dart';
import 'settings_service.dart';
import '../../screens/analysis/widgets/charging_patterns/services/charging_session_service.dart';

/// 홈 탭 생명주기 관리 서비스 (싱글톤)
/// 앱 생명주기, 탭 전환, 배터리 모니터링 등의 로직을 관리
/// 배터리 효율성을 위해 전역에서 하나의 인스턴스만 유지
class HomeLifecycleManager {
  // 싱글톤 인스턴스
  static final HomeLifecycleManager _instance = HomeLifecycleManager._internal();
  factory HomeLifecycleManager() => _instance;
  HomeLifecycleManager._internal();
  
  // 배터리 서비스
  final BatteryService _batteryService = BatteryService();
  
  // 설정 서비스 (선택적) - BatteryService에 전달용
  // ignore: unused_field
  SettingsService? _settingsService;
  
  // 스트림 구독 관리
  StreamSubscription<BatteryInfo>? _batteryInfoSubscription;
  
  /// SettingsService 설정
  void setSettingsService(SettingsService? settingsService) {
    _settingsService = settingsService;
    _batteryService.setSettingsService(settingsService);
  }
  
  // 주기적 새로고침 타이머 제거됨 - 이벤트 기반으로 전환
  // Timer? _periodicRefreshTimer; // 더 이상 사용하지 않음
  
  // 충전 전류 변화 감지를 위한 이전 값
  int _previousChargingCurrent = -1;
  
  // 스마트 캐싱 시스템
  BatteryInfo? _cachedBatteryInfo;
  DateTime? _lastCacheTime;
  static const Duration _cacheValidityDuration = Duration(minutes: 1);
  
  // 탭별 콜백 관리 (메모리 효율적)
  final Map<String, Function(BatteryInfo)?> _tabCallbacks = {};
  final Map<String, Function()?> _chargingCallbacks = {};
  final Map<String, Function()?> _appPausedCallbacks = {};
  final Map<String, Function()?> _appResumedCallbacks = {};
  
  // 전역 콜백 함수들 (하위 호환성)
  Function(BatteryInfo)? onBatteryInfoUpdated;
  Function()? onChargingCurrentChanged;
  Function()? onAppPaused;
  Function()? onAppResumed;
  
  /// 배터리 서비스 초기화
  Future<void> initialize() async {
    debugPrint('HomeLifecycleManager: 초기화 시작');
    
    try {
      // 배터리 서비스 상태 초기화 (앱 시작 시)
      await _batteryService.resetService();
      
      // 배터리 모니터링 시작
      await _batteryService.startMonitoring();
      debugPrint('HomeLifecycleManager: 배터리 모니터링 시작 완료');
      
      // 현재 배터리 정보 즉시 가져오기 (강제 새로고침)
      await _batteryService.refreshBatteryInfo();
      
      // 배터리 정보 스트림 구독 설정
      _setupBatteryInfoStream();
      
      // 주기적 새로고침 제거됨 - batteryInfoStream 이벤트 기반으로 자동 업데이트됨
      
      // 앱 생명주기 리스너 설정
      _setupAppLifecycleListener();
      
    } catch (e, stackTrace) {
      debugPrint('HomeLifecycleManager: 초기화 실패: $e');
      debugPrint('스택 트레이스: $stackTrace');
    }
  }
  
  /// 배터리 정보 스트림 구독 설정
  void _setupBatteryInfoStream() {
    debugPrint('HomeLifecycleManager: 배터리 정보 스트림 구독 설정');
    
    // 기존 구독 정리
    _batteryInfoSubscription?.cancel();
    
    // 새로운 스트림 구독 생성 (Phase 3: 중복 업데이트 방지 강화)
    _batteryInfoSubscription = _batteryService.batteryInfoStream.listen((batteryInfo) {
      try {
        // Phase 3: 중복 업데이트 방지 - 캐시된 정보와 비교하여 의미있는 변화만 처리
        if (!_shouldProcessBatteryInfo(batteryInfo)) {
          return; // 의미있는 변화가 없으면 처리하지 않음
        }
        
        debugPrint('HomeLifecycleManager: 배터리 정보 수신 - ${batteryInfo.toString()}');
        
        // 이전 충전 상태 확인
        final wasCharging = _cachedBatteryInfo?.isCharging ?? false;
        final isCharging = batteryInfo.isCharging;
        
        // 스마트 캐시 업데이트
        _updateCache(batteryInfo);
        
        // 충전 상태 변화 감지 (충전 시작/종료)
        if (wasCharging != isCharging) {
          debugPrint('HomeLifecycleManager: 충전 상태 변화 감지 - ${wasCharging ? "충전 중" : "방전 중"} → ${isCharging ? "충전 중" : "방전 중"}');
          // 주기적 새로고침 제거됨 - batteryInfoStream 이벤트 기반으로 자동 업데이트됨
        }
        
        // 충전 전류 변화 감지
        if (batteryInfo.isCharging) {
          final currentChargingCurrent = batteryInfo.chargingCurrent;
          if (_previousChargingCurrent != currentChargingCurrent && currentChargingCurrent >= 0) {
            debugPrint('HomeLifecycleManager: 충전 전류 변화 감지 - ${_previousChargingCurrent}mA → ${currentChargingCurrent}mA');
            _previousChargingCurrent = currentChargingCurrent;
            
            // 전역 콜백 호출 (하위 호환성)
            onChargingCurrentChanged?.call();
            
            // 탭별 콜백 호출
            for (final callback in _chargingCallbacks.values) {
              callback?.call();
            }
          }
        }
        
        // 전역 콜백 호출 (하위 호환성)
        onBatteryInfoUpdated?.call(batteryInfo);
        
        // 탭별 콜백 호출
        for (final callback in _tabCallbacks.values) {
          callback?.call(batteryInfo);
        }
        
        debugPrint('HomeLifecycleManager: 배터리 정보 업데이트 콜백 호출 - 배터리 레벨: ${batteryInfo.formattedLevel}');
      } catch (e, stackTrace) {
        // Phase 3: 에러 처리 강화 - 에러 발생 시에도 서비스는 계속 작동
        debugPrint('HomeLifecycleManager: 배터리 정보 처리 중 오류 발생 - $e');
        debugPrint('스택 트레이스: $stackTrace');
      }
    }, onError: (error) {
      // Phase 3: 에러 처리 강화
      debugPrint('HomeLifecycleManager: 배터리 정보 스트림 오류 - $error');
      // 에러 발생 시에도 서비스는 계속 작동
    });
    
    debugPrint('HomeLifecycleManager: 배터리 정보 스트림 구독 설정 완료');
  }
  
  // 주기적 새로고침 메서드 제거됨 - batteryInfoStream 이벤트 기반으로 자동 업데이트됨
  // 더 이상 Timer.periodic을 사용하지 않으며, batteryInfoStream의 이벤트만으로 충분합니다.
  
  /// 앱 생명주기 리스너 설정
  void _setupAppLifecycleListener() {
    SystemChannels.lifecycle.setMessageHandler((message) async {
      debugPrint('HomeLifecycleManager: 앱 생명주기 변화 - $message');
      
      switch (message) {
        case 'AppLifecycleState.paused':
        case 'AppLifecycleState.inactive':
          debugPrint('HomeLifecycleManager: 앱이 백그라운드로 이동, 모니터링 최적화');
          _optimizeForBackground();
          
          // 전역 콜백 호출 (하위 호환성)
          onAppPaused?.call();
          
          // 탭별 콜백 호출
          for (final callback in _appPausedCallbacks.values) {
            callback?.call();
          }
          break;
        case 'AppLifecycleState.resumed':
          debugPrint('HomeLifecycleManager: 앱이 포그라운드로 복귀, 모니터링 재시작');
          _optimizeForForeground();
          
          // 충전 세션 서비스 날짜 변경 체크 (배터리 효율적 - 앱 사용 시에만)
          _checkChargingSessionDateChange();
          
          // 전역 콜백 호출 (하위 호환성)
          onAppResumed?.call();
          
          // 탭별 콜백 호출
          for (final callback in _appResumedCallbacks.values) {
            callback?.call();
          }
          break;
      }
      return null;
    });
  }
  
  /// 백그라운드 최적화 (배터리 절약 모드)
  void _optimizeForBackground() {
    debugPrint('HomeLifecycleManager: 백그라운드 최적화 시작');
    
    // 주기적 새로고침 제거됨 - batteryInfoStream 이벤트 기반으로 자동 업데이트됨
    // 백그라운드에서도 스트림 구독은 유지되며, 시스템 이벤트가 발생할 때만 업데이트됨
    debugPrint('HomeLifecycleManager: 백그라운드 최적화 완료 (이벤트 기반 모드)');
  }
  
  /// 포그라운드 최적화 (정상 모드)
  void _optimizeForForeground() {
    debugPrint('HomeLifecycleManager: 포그라운드 최적화 시작');
    
    // 스트림 구독 재생성 (필요시)
    if (_batteryInfoSubscription == null) {
      debugPrint('HomeLifecycleManager: 포그라운드 복귀 - 스트림 구독 재생성');
      _setupBatteryInfoStream();
    }
    
    // 포그라운드 복귀 시 한 번만 배터리 정보 새로고침 (최신 상태 확인용)
    debugPrint('HomeLifecycleManager: 포그라운드 복귀 - 배터리 정보 한 번 새로고침');
    _batteryService.refreshBatteryInfo();
    // 주기적 새로고침 제거됨 - 이후 batteryInfoStream 이벤트 기반으로 자동 업데이트됨
    
    debugPrint('HomeLifecycleManager: 포그라운드 최적화 완료');
  }
  
  /// 충전 세션 서비스 날짜 변경 체크 (앱 포그라운드 복귀 시)
  /// 배터리 효율적 - 앱을 사용할 때만 체크
  void _checkChargingSessionDateChange() {
    try {
      final sessionService = ChargingSessionService();
      if (sessionService.isInitialized) {
        sessionService.checkDateChangeAndSave();
        debugPrint('HomeLifecycleManager: 충전 세션 날짜 변경 체크 완료');
      }
    } catch (e) {
      debugPrint('HomeLifecycleManager: 충전 세션 날짜 변경 체크 실패 - $e');
    }
  }
  
  /// 탭 복귀 시 배터리 정보 새로고침 (즉시 복원 + 비동기 업데이트)
  Future<void> handleTabReturn() async {
    debugPrint('HomeLifecycleManager: 탭 복귀 처리 시작');
    
    // 1. 즉시 캐시된 정보 반환 (UI 즉시 업데이트)
    final cachedInfo = getCachedBatteryInfo();
    if (cachedInfo != null) {
      debugPrint('HomeLifecycleManager: 캐시된 정보로 즉시 복원 - ${cachedInfo.formattedLevel}');
      
      // 모든 등록된 탭에 즉시 알림
      for (final callback in _tabCallbacks.values) {
        callback?.call(cachedInfo);
      }
      
      // 전역 콜백도 호출 (하위 호환성)
      onBatteryInfoUpdated?.call(cachedInfo);
    }
    
    // 2. 스트림 구독이 없다면 재생성
    if (_batteryInfoSubscription == null) {
      debugPrint('HomeLifecycleManager: 스트림 구독이 없음, 재생성 시도');
      _setupBatteryInfoStream();
    }
    
    // 3. 백그라운드에서 최신 정보 새로고침 (비동기)
    _refreshBatteryInfoInBackground();
    // 주기적 새로고침 제거됨 - 이후 batteryInfoStream 이벤트 기반으로 자동 업데이트됨
    
    debugPrint('HomeLifecycleManager: 탭 복귀 처리 완료');
  }
  
  /// 백그라운드에서 배터리 정보 새로고침 (비동기)
  Future<void> _refreshBatteryInfoInBackground() async {
    try {
      await _refreshBatteryInfoIfNeeded();
      debugPrint('HomeLifecycleManager: 백그라운드 새로고침 완료');
    } catch (e) {
      debugPrint('HomeLifecycleManager: 백그라운드 새로고침 실패: $e');
    }
  }
  
  /// 필요시 배터리 정보 새로고침
  Future<void> _refreshBatteryInfoIfNeeded() async {
    final currentInfo = _batteryService.currentBatteryInfo;
    
    if (currentInfo == null) {
      debugPrint('HomeLifecycleManager: 배터리 정보가 없음, 강제 새로고침 시도');
      await _batteryService.refreshBatteryInfo();
    } else {
      // 탭 복귀 시에는 항상 최신 정보로 새로고침
      debugPrint('HomeLifecycleManager: 탭 복귀 시 최신 정보 새로고침');
      await _batteryService.refreshBatteryInfo();
    }
  }
  
  /// 현재 배터리 정보 가져오기 (캐시 우선)
  BatteryInfo? get currentBatteryInfo => getCachedBatteryInfo() ?? _batteryService.currentBatteryInfo;
  
  /// 스마트 캐싱된 배터리 정보 가져오기
  BatteryInfo? getCachedBatteryInfo() {
    if (_cachedBatteryInfo != null && 
        _lastCacheTime != null &&
        DateTime.now().difference(_lastCacheTime!) < _cacheValidityDuration) {
      debugPrint('HomeLifecycleManager: 캐시된 배터리 정보 반환 - ${_cachedBatteryInfo!.formattedLevel}');
      return _cachedBatteryInfo;
    }
    debugPrint('HomeLifecycleManager: 캐시 만료 또는 없음');
    return null;
  }
  
  /// 배터리 정보 캐시 업데이트
  void _updateCache(BatteryInfo batteryInfo) {
    _cachedBatteryInfo = batteryInfo;
    _lastCacheTime = DateTime.now();
    debugPrint('HomeLifecycleManager: 배터리 정보 캐시 업데이트 - ${batteryInfo.formattedLevel}');
  }
  
  /// Phase 3: 배터리 정보를 처리해야 하는지 확인
  /// 중복 업데이트를 방지하기 위해 의미있는 변화가 있을 때만 true를 반환합니다.
  bool _shouldProcessBatteryInfo(BatteryInfo newInfo) {
    final cachedInfo = _cachedBatteryInfo;
    
    // 캐시가 없으면 항상 처리
    if (cachedInfo == null) {
      return true;
    }
    
    // 캐시가 만료되었으면 처리
    if (_lastCacheTime == null || 
        DateTime.now().difference(_lastCacheTime!) >= _cacheValidityDuration) {
      return true;
    }
    
    // 충전 상태 변화는 항상 처리
    if (cachedInfo.isCharging != newInfo.isCharging) {
      return true;
    }
    
    // 배터리 레벨 변화 (0.5% 이상)는 처리
    final levelDiff = (newInfo.level - cachedInfo.level).abs();
    if (levelDiff >= 0.5) {
      return true;
    }
    
    // 충전 중일 때 충전 전류 변화 (50mA 이상)는 처리
    if (newInfo.isCharging && cachedInfo.isCharging) {
      final currentDiff = (newInfo.chargingCurrent - cachedInfo.chargingCurrent).abs();
      if (currentDiff >= 50) {
        return true;
      }
    }
    
    // 의미있는 변화가 없으면 처리하지 않음
    return false;
  }
  
  /// 탭별 콜백 등록
  void registerTabCallbacks(String tabId, {
    Function(BatteryInfo)? onBatteryInfoUpdated,
    Function()? onChargingCurrentChanged,
    Function()? onAppPaused,
    Function()? onAppResumed,
  }) {
    debugPrint('HomeLifecycleManager: 탭 콜백 등록 - $tabId');
    
    if (onBatteryInfoUpdated != null) {
      _tabCallbacks[tabId] = onBatteryInfoUpdated;
    }
    if (onChargingCurrentChanged != null) {
      _chargingCallbacks[tabId] = onChargingCurrentChanged;
    }
    if (onAppPaused != null) {
      _appPausedCallbacks[tabId] = onAppPaused;
    }
    if (onAppResumed != null) {
      _appResumedCallbacks[tabId] = onAppResumed;
    }
  }
  
  /// 탭별 콜백 해제
  void unregisterTabCallbacks(String tabId) {
    debugPrint('HomeLifecycleManager: 탭 콜백 해제 - $tabId');
    
    _tabCallbacks.remove(tabId);
    _chargingCallbacks.remove(tabId);
    _appPausedCallbacks.remove(tabId);
    _appResumedCallbacks.remove(tabId);
  }
  
  /// 배터리 정보 수동 새로고침
  Future<void> refreshBatteryInfo() async {
    debugPrint('HomeLifecycleManager: 수동 새로고침 시작');
    await _batteryService.refreshBatteryInfo();
    debugPrint('HomeLifecycleManager: 수동 새로고침 완료');
  }
  
  /// 서비스 정리 (싱글톤에서는 완전 정리하지 않음)
  void dispose() {
    debugPrint('HomeLifecycleManager: dispose 시작 (싱글톤 - 부분 정리)');
    
    // 탭별 콜백만 정리 (전역 콜백은 유지)
    _tabCallbacks.clear();
    _chargingCallbacks.clear();
    _appPausedCallbacks.clear();
    _appResumedCallbacks.clear();
    
    // 스트림 구독은 유지 (다른 탭에서 사용할 수 있음)
    // _batteryInfoSubscription?.cancel(); // 주석 처리
    
    debugPrint('HomeLifecycleManager: dispose 완료 (싱글톤 - 핵심 서비스 유지)');
  }
  
  /// 완전 정리 (앱 종료 시에만 호출)
  void disposeCompletely() {
    debugPrint('HomeLifecycleManager: 완전 정리 시작');
    
    // 스트림 구독 정리
    _batteryInfoSubscription?.cancel();
    _batteryInfoSubscription = null;
    
    // 주기적 새로고침 제거됨 (더 이상 사용하지 않음)
    
    // 모든 콜백 정리
    _tabCallbacks.clear();
    _chargingCallbacks.clear();
    _appPausedCallbacks.clear();
    _appResumedCallbacks.clear();
    
    // 전역 콜백 정리
    onBatteryInfoUpdated = null;
    onChargingCurrentChanged = null;
    onAppPaused = null;
    onAppResumed = null;
    
    // 캐시 정리
    _cachedBatteryInfo = null;
    _lastCacheTime = null;
    
    debugPrint('HomeLifecycleManager: 완전 정리 완료');
  }
}
