// 세션 데이터 수집 서비스
// 충전 세션 중 데이터 포인트를 수집하고 관리하는 서비스

import 'package:flutter/foundation.dart';
import '../../../../../models/models.dart';
import 'current_change_detector.dart';

/// 세션 데이터 포인트
class SessionDataPoint {
  final DateTime timestamp;
  final int currentMa;
  final double batteryLevel;
  final double temperature;
  
  SessionDataPoint({
    required this.timestamp,
    required this.currentMa,
    required this.batteryLevel,
    required this.temperature,
  });
}

/// 세션 데이터 수집기
/// 
/// 주요 기능:
/// 1. 데이터 포인트 수집 및 관리
/// 2. 전류 변화 감지 통합
/// 3. 메모리 관리 (최대 1000개 제한)
class SessionDataCollector {
  /// 수집된 데이터 포인트들
  final List<SessionDataPoint> _dataPoints = [];
  
  /// 전류 변화 감지기
  final CurrentChangeDetector _currentChangeDetector;
  
  /// 최대 데이터 포인트 개수 (메모리 관리)
  static const int maxDataPoints = 1000;
  
  /// 생성자
  SessionDataCollector({
    CurrentChangeDetector? currentChangeDetector,
  }) : _currentChangeDetector = currentChangeDetector ?? CurrentChangeDetector();
  
  // ==================== 데이터 수집 ====================
  
  /// 데이터 포인트 추가
  /// 
  /// [batteryInfo] 배터리 정보
  /// [sessionStartTime] 세션 시작 시간 (null이면 추가하지 않음)
  /// [isDisposed] 서비스가 dispose되었는지 확인하는 콜백
  void addDataPoint(
    BatteryInfo batteryInfo, {
    DateTime? sessionStartTime,
    bool Function()? isDisposed,
  }) {
    // 세션 시작 시간이 없거나 dispose된 경우 추가하지 않음
    if (sessionStartTime == null || (isDisposed?.call() ?? false)) {
      return;
    }
    
    final dataPoint = SessionDataPoint(
      timestamp: DateTime.now(),
      currentMa: batteryInfo.chargingCurrent,
      batteryLevel: batteryInfo.level,
      temperature: batteryInfo.temperature,
    );
    
    _dataPoints.add(dataPoint);
    
    // 메모리 관리: 데이터 포인트 리스트 크기 제한
    // 최대 1000개까지만 유지 (약 2.7시간 분량, 10초 간격 기준)
    if (_dataPoints.length > maxDataPoints) {
      // 오래된 데이터 제거 (FIFO)
      _dataPoints.removeAt(0);
    }
    
    // 전류 변화 감지
    _currentChangeDetector.checkCurrentChange(
      batteryInfo.chargingCurrent,
      DateTime.now(),
    );
  }
  
  // ==================== 데이터 접근 ====================
  
  /// 수집된 데이터 포인트 목록 가져오기
  List<SessionDataPoint> getDataPoints() {
    return List.unmodifiable(_dataPoints);
  }
  
  /// 데이터 포인트 개수
  int get dataPointCount => _dataPoints.length;
  
  /// 데이터 포인트가 비어있는지 확인
  bool get isEmpty => _dataPoints.isEmpty;
  
  /// 데이터 포인트가 비어있지 않은지 확인
  bool get isNotEmpty => _dataPoints.isNotEmpty;
  
  // ==================== 전류 변화 감지기 접근 ====================
  
  /// 전류 변화 감지기 가져오기
  CurrentChangeDetector get currentChangeDetector => _currentChangeDetector;
  
  /// 전류 변화 이벤트 목록 가져오기
  List<dynamic> getChangeEvents() {
    return _currentChangeDetector.getChangeEvents();
  }
  
  // ==================== 상태 초기화 ====================
  
  /// 수집기 초기화 (새 세션 시작 시 호출)
  void reset() {
    _dataPoints.clear();
    _currentChangeDetector.reset();
    debugPrint('SessionDataCollector: 초기화 완료');
  }
  
  /// 현재 상태 확인 (디버깅용)
  Map<String, dynamic> getStatus() {
    return {
      'dataPointCount': _dataPoints.length,
      'currentChangeDetectorStatus': _currentChangeDetector.getStatus(),
    };
  }
}

