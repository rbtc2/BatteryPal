// 세션 타이머 관리 서비스
// 데이터 수집, 종료 대기, 자정 타이머를 통합 관리

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../config/charging_session_config.dart';

/// 세션 타이머 관리자
/// 
/// 주요 기능:
/// 1. 데이터 수집 타이머 관리 (주기적)
/// 2. 종료 대기 타이머 관리 (일회성)
/// 3. 자정 타이머 관리 (일회성, 재귀적)
class SessionTimerManager {
  // ==================== 데이터 수집 타이머 ====================
  
  /// 데이터 수집 타이머
  Timer? _dataCollectionTimer;
  
  /// 데이터 수집 타이머 시작
  /// 
  /// [onTick] 타이머가 실행될 때마다 호출되는 콜백
  /// [isActive] 타이머가 활성화되어야 하는지 확인하는 콜백
  void startDataCollectionTimer({
    required VoidCallback onTick,
    required bool Function() isActive,
  }) {
    stopDataCollectionTimer();
    
    _dataCollectionTimer = Timer.periodic(
      ChargingSessionConfig.dataCollectionInterval,
      (timer) {
        if (!isActive()) {
          timer.cancel();
          _dataCollectionTimer = null;
          return;
        }
        onTick();
      },
    );
    
    debugPrint('SessionTimerManager: 데이터 수집 타이머 시작');
  }
  
  /// 데이터 수집 타이머 중지
  void stopDataCollectionTimer() {
    _dataCollectionTimer?.cancel();
    _dataCollectionTimer = null;
  }
  
  /// 데이터 수집 타이머가 실행 중인지 확인
  bool get isDataCollectionTimerActive => _dataCollectionTimer != null;
  
  // ==================== 종료 대기 타이머 ====================
  
  /// 종료 대기 타이머
  Timer? _endWaitTimer;
  
  /// 종료 대기 타이머 시작
  /// 
  /// [onComplete] 타이머가 완료되었을 때 호출되는 콜백
  /// [isDisposed] 서비스가 dispose되었는지 확인하는 콜백
  void startEndWaitTimer({
    required VoidCallback onComplete,
    required bool Function() isDisposed,
  }) {
    // 기존 타이머가 있으면 취소
    _endWaitTimer?.cancel();
    
    _endWaitTimer = Timer(ChargingSessionConfig.sessionEndWaitDuration, () {
      if (isDisposed()) {
        return;
      }
      onComplete();
      _endWaitTimer = null;
    });
    
    debugPrint('SessionTimerManager: 종료 대기 타이머 시작');
  }
  
  /// 종료 대기 타이머 중지
  void stopEndWaitTimer() {
    _endWaitTimer?.cancel();
    _endWaitTimer = null;
  }
  
  /// 종료 대기 타이머가 실행 중인지 확인
  bool get isEndWaitTimerActive => _endWaitTimer != null;
  
  // ==================== 자정 타이머 ====================
  
  /// 자정 타이머
  Timer? _midnightTimer;
  
  /// 자정 타이머 스케줄링 (배터리 효율적 - 다음 자정까지 한 번만 타이머 설정)
  /// 
  /// [onMidnight] 자정에 호출되는 콜백
  /// [isDisposed] 서비스가 dispose되었는지 확인하는 콜백
  /// [isInitialized] 서비스가 초기화되었는지 확인하는 콜백
  void scheduleMidnightTimer({
    required VoidCallback onMidnight,
    required bool Function() isDisposed,
    required bool Function() isInitialized,
  }) {
    if (isDisposed() || !isInitialized()) return;
    
    // 기존 타이머 취소
    _midnightTimer?.cancel();
    
    try {
      final now = DateTime.now();
      // 다음 자정 시간 계산 (00:00:00)
      final tomorrow = DateTime(now.year, now.month, now.day + 1, 0, 0, 0);
      final durationUntilMidnight = tomorrow.difference(now);
      
      debugPrint('SessionTimerManager: 자정 타이머 스케줄링 - ${durationUntilMidnight.inHours}시간 ${durationUntilMidnight.inMinutes % 60}분 후 실행');
      
      // 다음 자정까지 대기 후 실행
      _midnightTimer = Timer(durationUntilMidnight, () {
        if (isDisposed() || !isInitialized()) return;
        
        // 자정 콜백 실행
        onMidnight();
        
        // 다음 자정까지 다시 스케줄링 (재귀적)
        scheduleMidnightTimer(
          onMidnight: onMidnight,
          isDisposed: isDisposed,
          isInitialized: isInitialized,
        );
      });
    } catch (e, stackTrace) {
      debugPrint('SessionTimerManager: 자정 타이머 스케줄링 실패 - $e');
      debugPrint('스택 트레이스: $stackTrace');
    }
  }
  
  /// 자정 타이머 중지
  void stopMidnightTimer() {
    _midnightTimer?.cancel();
    _midnightTimer = null;
  }
  
  /// 자정 타이머가 실행 중인지 확인
  bool get isMidnightTimerActive => _midnightTimer != null;
  
  // ==================== 모든 타이머 정리 ====================
  
  /// 모든 타이머 정리
  void dispose() {
    stopDataCollectionTimer();
    stopEndWaitTimer();
    stopMidnightTimer();
    debugPrint('SessionTimerManager: 모든 타이머 정리 완료');
  }
  
  /// 타이머 상태 확인 (디버깅용)
  Map<String, dynamic> getTimerStatus() {
    return {
      'isDataCollectionTimerActive': isDataCollectionTimerActive,
      'isEndWaitTimerActive': isEndWaitTimerActive,
      'isMidnightTimerActive': isMidnightTimerActive,
    };
  }
}

