import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/app_models.dart';
import 'battery_service.dart';

/// 홈 탭 생명주기 관리 서비스
/// 앱 생명주기, 탭 전환, 배터리 모니터링 등의 로직을 관리
class HomeLifecycleManager {
  // 배터리 서비스
  final BatteryService _batteryService = BatteryService();
  
  // 스트림 구독 관리
  StreamSubscription<BatteryInfo>? _batteryInfoSubscription;
  
  // 주기적 새로고침 타이머
  Timer? _periodicRefreshTimer;
  
  // 주기적 새로고침 간격 (초)
  static const int _refreshIntervalSeconds = 30;
  
  // 충전 전류 변화 감지를 위한 이전 값
  int _previousChargingCurrent = -1;
  
  // 콜백 함수들
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
      
      // 충전 전류 변화 감지
      if (batteryInfo.isCharging) {
        final currentChargingCurrent = batteryInfo.chargingCurrent;
        if (_previousChargingCurrent != currentChargingCurrent && currentChargingCurrent >= 0) {
          debugPrint('HomeLifecycleManager: 충전 전류 변화 감지 - ${_previousChargingCurrent}mA → ${currentChargingCurrent}mA');
          _previousChargingCurrent = currentChargingCurrent;
          onChargingCurrentChanged?.call();
        }
      }
      
      // 배터리 정보 업데이트 콜백 호출
      onBatteryInfoUpdated?.call(batteryInfo);
      debugPrint('HomeLifecycleManager: 배터리 정보 업데이트 콜백 호출 - 배터리 레벨: ${batteryInfo.formattedLevel}');
    });
    
    debugPrint('HomeLifecycleManager: 배터리 정보 스트림 구독 설정 완료');
  }
  
  /// 주기적 새로고침 시작
  void _startPeriodicRefresh() {
    debugPrint('HomeLifecycleManager: 주기적 새로고침 시작 ($_refreshIntervalSeconds초 간격)');
    
    _periodicRefreshTimer?.cancel();
    _periodicRefreshTimer = Timer.periodic(
      const Duration(seconds: _refreshIntervalSeconds),
      (timer) {
        debugPrint('HomeLifecycleManager: 주기적 새로고침 실행');
        _batteryService.refreshBatteryInfo();
      },
    );
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
          onAppPaused?.call();
          break;
        case 'AppLifecycleState.resumed':
          debugPrint('HomeLifecycleManager: 앱이 포그라운드로 복귀, 모니터링 재시작');
          _optimizeForForeground();
          onAppResumed?.call();
          break;
      }
      return null;
    });
  }
  
  /// 백그라운드 최적화
  void _optimizeForBackground() {
    // 주기적 새로고침 중지 (배터리 절약)
    _stopPeriodicRefresh();
    debugPrint('HomeLifecycleManager: 백그라운드 최적화 완료');
  }
  
  /// 포그라운드 최적화
  void _optimizeForForeground() {
    // 주기적 새로고침 재시작
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
  
  /// 탭 복귀 시 배터리 정보 새로고침
  Future<void> handleTabReturn() async {
    debugPrint('HomeLifecycleManager: 탭 복귀 처리 시작');
    
    // 스트림 구독이 없다면 재생성
    if (_batteryInfoSubscription == null) {
      debugPrint('HomeLifecycleManager: 스트림 구독이 없음, 재생성 시도');
      _setupBatteryInfoStream();
    }
    
    // 배터리 정보 새로고침
    await _refreshBatteryInfoIfNeeded();
    
    debugPrint('HomeLifecycleManager: 탭 복귀 처리 완료');
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
  
  /// 현재 배터리 정보 가져오기
  BatteryInfo? get currentBatteryInfo => _batteryService.currentBatteryInfo;
  
  /// 배터리 정보 수동 새로고침
  Future<void> refreshBatteryInfo() async {
    debugPrint('HomeLifecycleManager: 수동 새로고침 시작');
    await _batteryService.refreshBatteryInfo();
    debugPrint('HomeLifecycleManager: 수동 새로고침 완료');
  }
  
  /// 서비스 정리
  void dispose() {
    debugPrint('HomeLifecycleManager: dispose 시작');
    
    // 스트림 구독 정리
    _batteryInfoSubscription?.cancel();
    _batteryInfoSubscription = null;
    
    // 주기적 새로고침 중지
    _stopPeriodicRefresh();
    
    // 배터리 서비스는 전역 싱글톤이므로 dispose하지 않음
    // 탭 전환 시에도 서비스가 계속 작동하도록 유지
    
    debugPrint('HomeLifecycleManager: dispose 완료 (배터리 서비스 유지)');
  }
}
