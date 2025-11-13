// 전류 변화 감지 서비스
// 충전 중 전류 변화를 감지하고 이벤트를 생성하는 서비스

import 'package:flutter/foundation.dart';
import '../models/charging_session_models.dart';
import '../config/charging_session_config.dart';

/// 전류 변화 감지기
/// 
/// 주요 기능:
/// 1. 전류 변화 감지 및 추적
/// 2. 전류 변화 이벤트 생성
/// 3. 전류 변화 이벤트 목록 관리
class CurrentChangeDetector {
  /// 이전 전류값 (전류 변화 감지용)
  int? _previousCurrent;
  
  /// 이전 전류값의 타임스탬프
  DateTime? _previousCurrentTime;
  
  /// 전류 변화 이벤트 목록
  final List<CurrentChangeEvent> _changeEvents = [];
  
  // ==================== 전류 변화 감지 ====================
  
  /// 전류 변화 감지 및 이벤트 생성
  /// 
  /// [current] 현재 전류값 (mA)
  /// [timestamp] 현재 시간
  /// 
  /// 반환: 변화가 감지되고 이벤트가 생성되면 이벤트, 아니면 null
  CurrentChangeEvent? checkCurrentChange(int current, DateTime timestamp) {
    if (_previousCurrent == null) {
      // 첫 전류값
      _previousCurrent = current;
      _previousCurrentTime = timestamp;
      return null;
    }
    
    // 전류 변화가 유의미한지 확인
    if (ChargingSessionConfig.isSignificantCurrentChange(
      _previousCurrent!,
      current,
    )) {
      // 전류 변화 이벤트 생성
      final changeEvent = _createCurrentChangeEvent(
        _previousCurrent!,
        current,
        _previousCurrentTime!,
      );
      
      if (changeEvent != null) {
        _changeEvents.add(changeEvent);
        debugPrint('CurrentChangeDetector: 전류 변화 감지 - ${changeEvent.description}');
      }
      
      _previousCurrent = current;
      _previousCurrentTime = timestamp;
      
      return changeEvent;
    }
    
    return null;
  }
  
  /// 전류 변화 이벤트 생성
  CurrentChangeEvent? _createCurrentChangeEvent(
    int previousCurrent,
    int newCurrent,
    DateTime timestamp,
  ) {
    if (previousCurrent == 0 && newCurrent > 0) {
      // 충전 시작
      final speedType = ChargingSessionConfig.getChargingSpeedType(newCurrent);
      return CurrentChangeEvent(
        timestamp: timestamp,
        previousCurrent: previousCurrent,
        newCurrent: newCurrent,
        changeType: speedType,
        description: '$speedType 시작',
      );
    } else if (previousCurrent > 0 && newCurrent == 0) {
      // 충전 종료
      return CurrentChangeEvent(
        timestamp: timestamp,
        previousCurrent: previousCurrent,
        newCurrent: newCurrent,
        changeType: '종료',
        description: '충전 종료',
      );
    } else if (previousCurrent > 0 && newCurrent > 0) {
      // 충전 속도 변화 - 충전 단위 간 전환만 기록
      final prevSpeedType = ChargingSessionConfig.getChargingSpeedType(previousCurrent);
      final newSpeedType = ChargingSessionConfig.getChargingSpeedType(newCurrent);
      
      // 충전 단위(저속/일반/급속/초고속) 간 전환만 기록
      if (prevSpeedType != newSpeedType) {
        return CurrentChangeEvent(
          timestamp: timestamp,
          previousCurrent: previousCurrent,
          newCurrent: newCurrent,
          changeType: newSpeedType,
          description: '$prevSpeedType → $newSpeedType 전환 ⚡',
        );
      }
      // 같은 충전 단위 내에서의 변화는 기록하지 않음
    }
    
    return null;
  }
  
  // ==================== 이벤트 목록 관리 ====================
  
  /// 전류 변화 이벤트 목록 가져오기
  List<CurrentChangeEvent> getChangeEvents() {
    return List.unmodifiable(_changeEvents);
  }
  
  /// 전류 변화 이벤트 목록 초기화
  void clearChangeEvents() {
    _changeEvents.clear();
  }
  
  /// 전류 변화 이벤트 개수
  int get changeEventCount => _changeEvents.length;
  
  // ==================== 상태 초기화 ====================
  
  /// 감지기 초기화 (새 세션 시작 시 호출)
  void reset() {
    _previousCurrent = null;
    _previousCurrentTime = null;
    _changeEvents.clear();
    debugPrint('CurrentChangeDetector: 초기화 완료');
  }
  
  /// 현재 상태 확인 (디버깅용)
  Map<String, dynamic> getStatus() {
    return {
      'previousCurrent': _previousCurrent,
      'previousCurrentTime': _previousCurrentTime?.toIso8601String(),
      'changeEventCount': _changeEvents.length,
    };
  }
}

