import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/app_models.dart';
import 'battery_service.dart';
import 'settings_service.dart';

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
  
  // 주기적 새로고침 타이머
  Timer? _periodicRefreshTimer;
  
  // 적응형 새로고침 간격 (초)
  static const int _refreshIntervalSeconds = 30;
  static const int _backgroundRefreshIntervalSeconds = 60; // 백그라운드에서는 더 긴 간격
  static const int _chargingRefreshIntervalSeconds = 10; // 충전 중에는 더 짧은 간격
  
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
      
      // 주기적 새로고침 시작
      _startPeriodicRefresh();
      
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
    
    // 새로운 스트림 구독 생성
    _batteryInfoSubscription = _batteryService.batteryInfoStream.listen((batteryInfo) {
      debugPrint('HomeLifecycleManager: 배터리 정보 수신 - ${batteryInfo.toString()}');
      
      // 스마트 캐시 업데이트
      _updateCache(batteryInfo);
      
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
    });
    
    debugPrint('HomeLifecycleManager: 배터리 정보 스트림 구독 설정 완료');
  }
  
  /// 적응형 주기적 새로고침 시작
  void _startPeriodicRefresh() {
    final interval = _getOptimalRefreshInterval();
    debugPrint('HomeLifecycleManager: 적응형 주기적 새로고침 시작 ($interval초 간격)');
    
    _periodicRefreshTimer?.cancel();
    _periodicRefreshTimer = Timer.periodic(
      Duration(seconds: interval),
      (timer) {
        debugPrint('HomeLifecycleManager: 적응형 주기적 새로고침 실행');
        _batteryService.refreshBatteryInfo();
        
        // 간격 재조정 (충전 상태 변화 시)
        final newInterval = _getOptimalRefreshInterval();
        if (newInterval != interval) {
          debugPrint('HomeLifecycleManager: 새로고침 간격 재조정 - $interval초 → $newInterval초');
          _startPeriodicRefresh(); // 재시작
        }
      },
    );
  }
  
  /// 최적의 새로고침 간격 계산
  int _getOptimalRefreshInterval() {
    final currentInfo = _cachedBatteryInfo ?? _batteryService.currentBatteryInfo;
    
    if (currentInfo == null) {
      return _refreshIntervalSeconds; // 기본값
    }
    
    // 충전 중이면 더 자주 새로고침
    if (currentInfo.isCharging) {
      return _chargingRefreshIntervalSeconds;
    }
    
    // 배터리가 낮으면 더 자주 새로고침
    if (currentInfo.level < 20) {
      return 15; // 15초
    }
    
    // 배터리가 높으면 덜 자주 새로고침
    if (currentInfo.level > 80) {
      return 45; // 45초
    }
    
    return _refreshIntervalSeconds; // 기본값
  }
  
  /// 주기적 새로고침 중지
  void _stopPeriodicRefresh() {
    debugPrint('HomeLifecycleManager: 주기적 새로고침 중지');
    _periodicRefreshTimer?.cancel();
    _periodicRefreshTimer = null;
  }
  
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
    
    // 주기적 새로고침 간격을 더 길게 조정
    _periodicRefreshTimer?.cancel();
    _periodicRefreshTimer = Timer.periodic(
      const Duration(seconds: _backgroundRefreshIntervalSeconds),
      (timer) {
        debugPrint('HomeLifecycleManager: 백그라운드 주기적 새로고침 실행');
        _batteryService.refreshBatteryInfo();
      },
    );
    
    debugPrint('HomeLifecycleManager: 백그라운드 최적화 완료 ($_backgroundRefreshIntervalSeconds초 간격)');
  }
  
  /// 포그라운드 최적화 (정상 모드)
  void _optimizeForForeground() {
    debugPrint('HomeLifecycleManager: 포그라운드 최적화 시작');
    
    // 적응형 주기적 새로고침 재시작
    _startPeriodicRefresh();
    
    // 스트림 구독 재생성 (필요시)
    if (_batteryInfoSubscription == null) {
      debugPrint('HomeLifecycleManager: 포그라운드 복귀 - 스트림 구독 재생성');
      _setupBatteryInfoStream();
    }
    
    // 포그라운드 복귀 시 항상 배터리 정보 새로고침
    debugPrint('HomeLifecycleManager: 포그라운드 복귀 - 배터리 정보 강제 새로고침');
    _batteryService.refreshBatteryInfo();
    
    debugPrint('HomeLifecycleManager: 포그라운드 최적화 완료');
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
    
    // 스트림 구독과 타이머는 유지 (다른 탭에서 사용할 수 있음)
    // _batteryInfoSubscription?.cancel(); // 주석 처리
    // _stopPeriodicRefresh(); // 주석 처리
    
    debugPrint('HomeLifecycleManager: dispose 완료 (싱글톤 - 핵심 서비스 유지)');
  }
  
  /// 완전 정리 (앱 종료 시에만 호출)
  void disposeCompletely() {
    debugPrint('HomeLifecycleManager: 완전 정리 시작');
    
    // 스트림 구독 정리
    _batteryInfoSubscription?.cancel();
    _batteryInfoSubscription = null;
    
    // 주기적 새로고침 중지
    _stopPeriodicRefresh();
    
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
