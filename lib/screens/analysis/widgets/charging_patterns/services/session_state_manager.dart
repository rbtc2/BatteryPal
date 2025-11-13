// 세션 상태 관리 서비스
// 세션 상태 전환 및 관리를 담당하는 서비스

import 'package:flutter/foundation.dart';
import '../../../../../models/models.dart';
import '../models/charging_session_models.dart';

/// 세션 상태 enum
enum SessionState {
  /// 대기 중 (충전 중이 아님)
  idle,
  
  /// 세션 진행 중 (충전 중, 데이터 수집 중)
  active,
  
  /// 세션 종료 대기 중 (전류가 0이 되었지만 아직 종료 판단 전)
  ending,
}

/// 세션 상태 관리자
/// 
/// 주요 기능:
/// 1. 세션 상태 관리 및 전환
/// 2. 세션 시작/종료 시간 추적
/// 3. 세션 시작 시 배터리 정보 저장
/// 4. 이전 충전 상태 추적
class SessionStateManager {
  /// 현재 세션 상태
  SessionState _state = SessionState.idle;
  
  /// 현재 진행 중인 세션 데이터
  ChargingSessionRecord? _currentSession;
  
  /// 세션 시작 시간
  DateTime? _startTime;
  
  /// 세션 종료 대기 시작 시간 (전류가 0이 된 시점)
  DateTime? _endWaitStartTime;
  
  /// 이전 충전 상태 (충전 시작/종료 감지용)
  bool _wasCharging = false;
  
  /// 세션 시작 시 배터리 정보
  BatteryInfo? _startBatteryInfo;
  
  // ==================== 상태 접근 ====================
  
  /// 현재 세션 상태
  SessionState get state => _state;
  
  /// 세션 진행 중인지 확인
  bool get isActive => _state == SessionState.active;
  
  /// 세션 종료 대기 중인지 확인
  bool get isEnding => _state == SessionState.ending;
  
  /// 세션 대기 중인지 확인
  bool get isIdle => _state == SessionState.idle;
  
  /// 세션 시작 시간
  DateTime? get startTime => _startTime;
  
  /// 세션 종료 대기 시작 시간
  DateTime? get endWaitStartTime => _endWaitStartTime;
  
  /// 현재 진행 중인 세션 데이터
  ChargingSessionRecord? get currentSession => _currentSession;
  
  /// 이전 충전 상태
  bool get wasCharging => _wasCharging;
  
  /// 세션 시작 시 배터리 정보
  BatteryInfo? get startBatteryInfo => _startBatteryInfo;
  
  // ==================== 상태 전환 ====================
  
  /// 세션 시작
  /// 
  /// [batteryInfo] 세션 시작 시 배터리 정보
  /// 
  /// 반환: 세션이 시작되면 true, 이미 진행 중이면 false
  bool startSession(BatteryInfo batteryInfo) {
    if (_state != SessionState.idle) {
      debugPrint('SessionStateManager: 세션이 이미 진행 중입니다');
      return false;
    }
    
    _state = SessionState.active;
    _startTime = DateTime.now();
    _startBatteryInfo = batteryInfo;
    _endWaitStartTime = null;
    _currentSession = null;
    
    debugPrint('SessionStateManager: 세션 시작 - 상태: ${_state.name}, 시작 시간: $_startTime');
    return true;
  }
  
  /// 세션 종료 대기 시작
  /// 
  /// 반환: 종료 대기가 시작되면 true, 이미 idle이면 false
  bool startEndWait() {
    if (_state == SessionState.idle) {
      return false;
    }
    
    if (_state == SessionState.active) {
      _state = SessionState.ending;
      _endWaitStartTime = DateTime.now();
      debugPrint('SessionStateManager: 세션 종료 대기 시작 - 상태: ${_state.name}');
      return true;
    }
    
    return false;
  }
  
  /// 세션 다시 활성화 (종료 대기 중 충전이 재개된 경우)
  void reactivateSession() {
    if (_state == SessionState.ending) {
      _state = SessionState.active;
      _endWaitStartTime = null;
      debugPrint('SessionStateManager: 세션이 다시 활성화됨 - 상태: ${_state.name}');
    }
  }
  
  /// 세션 리셋 (idle 상태로 전환)
  void reset() {
    _state = SessionState.idle;
    _currentSession = null;
    _startTime = null;
    _endWaitStartTime = null;
    _startBatteryInfo = null;
    debugPrint('SessionStateManager: 세션 리셋 - 상태: ${_state.name}');
  }
  
  // ==================== 충전 상태 추적 ====================
  
  /// 이전 충전 상태 설정
  void setWasCharging(bool wasCharging) {
    _wasCharging = wasCharging;
  }
  
  /// 현재 세션 기록 설정
  void setCurrentSession(ChargingSessionRecord? session) {
    _currentSession = session;
  }
  
  // ==================== 상태 확인 ====================
  
  /// 현재 상태 확인 (디버깅용)
  Map<String, dynamic> getStatus() {
    return {
      'state': _state.name,
      'isActive': isActive,
      'isEnding': isEnding,
      'isIdle': isIdle,
      'startTime': _startTime?.toIso8601String(),
      'endWaitStartTime': _endWaitStartTime?.toIso8601String(),
      'hasCurrentSession': _currentSession != null,
      'wasCharging': _wasCharging,
      'hasStartBatteryInfo': _startBatteryInfo != null,
    };
  }
}

