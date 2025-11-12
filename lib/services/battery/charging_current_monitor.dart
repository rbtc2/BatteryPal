import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../native_battery_service.dart';
import '../battery_history_database_service.dart';
import '../../models/app_models.dart';

/// 충전 전류 모니터링을 담당하는 클래스
/// 
/// 충전 중일 때 충전 전류를 주기적으로 모니터링하고,
/// 적응형 간격 조정, 안정성 추적, 데이터베이스 저장을 수행합니다.
class ChargingCurrentMonitor {
  // 충전 전류 전용 모니터링 타이머
  Timer? _chargingCurrentTimer;
  
  // 적응형 충전 전류 모니터링 간격 (밀리초)
  int _chargingCurrentInterval = 1000; // 기본 1초
  
  // 충전 전류 안정성 추적
  final List<int> _recentChargingCurrents = <int>[];
  static const int _stabilityCheckCount = 5; // 최근 5회 측정값으로 안정성 판단
  
  // 충전 전류 데이터 저장을 위한 데이터베이스 서비스
  final BatteryHistoryDatabaseService _databaseService = BatteryHistoryDatabaseService();
  bool _isDatabaseInitialized = false;
  
  // 충전 전류 저장을 위한 배치 버퍼 (성능 최적화)
  final List<Map<String, dynamic>> _chargingCurrentBuffer = [];
  Timer? _chargingCurrentSaveTimer;
  
  // 콜백 함수들
  Function(BatteryInfo)? _onChargingCurrentUpdate;
  bool Function()? _isDisposed;
  BatteryInfo? Function()? _getCurrentBatteryInfo;
  
  /// 콜백 함수 설정
  void setCallbacks({
    Function(BatteryInfo)? onChargingCurrentUpdate,
    bool Function()? isDisposed,
    BatteryInfo? Function()? getCurrentBatteryInfo,
  }) {
    _onChargingCurrentUpdate = onChargingCurrentUpdate;
    _isDisposed = isDisposed;
    _getCurrentBatteryInfo = getCurrentBatteryInfo;
  }
  
  /// 배터리 레벨에 따른 적응형 모니터링 간격 계산
  int _getAdaptiveMonitoringInterval(BatteryInfo? batteryInfo) {
    if (batteryInfo == null) return 1000; // 기본 1초
    
    final batteryLevel = batteryInfo.level;
    
    if (batteryLevel >= 80) {
      return 2000; // 80% 이상: 2초 간격 (충전 속도 감소)
    } else if (batteryLevel >= 50) {
      return 1000; // 50-80%: 1초 간격
    } else {
      return 500;  // 50% 미만: 0.5초 간격 (빠른 충전)
    }
  }
  
  /// 충전 전류 안정성 확인
  bool _isChargingCurrentStable() {
    if (_recentChargingCurrents.length < _stabilityCheckCount) {
      return false; // 충분한 데이터가 없으면 불안정으로 간주
    }
    
    // 최근 측정값들의 표준편차 계산
    final average = _recentChargingCurrents.reduce((a, b) => a + b) / _recentChargingCurrents.length;
    final variance = _recentChargingCurrents.map((x) => (x - average) * (x - average)).reduce((a, b) => a + b) / _recentChargingCurrents.length;
    final standardDeviation = sqrt(variance);
    
    // 표준편차가 평균의 10% 미만이면 안정적
    return standardDeviation < (average * 0.1);
  }
  
  /// 충전 전류 안정성에 따른 간격 조정
  void _adjustMonitoringInterval() {
    final currentInfo = _getCurrentBatteryInfo?.call();
    final adaptiveInterval = _getAdaptiveMonitoringInterval(currentInfo);
    final stabilityFactor = _isChargingCurrentStable() ? 1.5 : 1.0; // 안정적이면 간격 늘리기
    
    _chargingCurrentInterval = (adaptiveInterval * stabilityFactor).round();
    
    debugPrint('모니터링 간격 조정: ${_chargingCurrentInterval}ms (적응형: ${adaptiveInterval}ms, 안정성: ${_isChargingCurrentStable()})');
  }
  
  /// 충전 전류 전용 모니터링 시작 (적응형 간격)
  void startMonitoring() {
    if (_chargingCurrentTimer != null) {
      debugPrint('충전 전류 모니터링이 이미 실행 중입니다');
      return;
    }
    
    // 초기 간격 설정
    _adjustMonitoringInterval();
    
    debugPrint('충전 전류 전용 모니터링 시작 (${_chargingCurrentInterval}ms 간격)');
    
    _chargingCurrentTimer = Timer.periodic(
      Duration(milliseconds: _chargingCurrentInterval),
      (timer) async {
        if (_isDisposed?.call() == true) {
          stopMonitoring();
          return;
        }
        
        final currentInfo = _getCurrentBatteryInfo?.call();
        if (currentInfo?.isCharging != true) {
          stopMonitoring();
          return;
        }
        
        await updateChargingCurrent();
        
        // 간격 동적 조정 (매 5회마다)
        if (_recentChargingCurrents.length % 5 == 0) {
          _adjustMonitoringInterval();
          // 타이머 재시작 (새로운 간격으로)
          _restartChargingCurrentTimer();
        }
      },
    );
  }
  
  /// 충전 전류 모니터링 타이머 재시작 (새로운 간격으로)
  void _restartChargingCurrentTimer() {
    _chargingCurrentTimer?.cancel();
    _chargingCurrentTimer = null;
    
    final currentInfo = _getCurrentBatteryInfo?.call();
    if (currentInfo?.isCharging == true) {
      debugPrint('충전 전류 모니터링 재시작 (${_chargingCurrentInterval}ms 간격)');
      
      _chargingCurrentTimer = Timer.periodic(
        Duration(milliseconds: _chargingCurrentInterval),
        (timer) async {
          if (_isDisposed?.call() == true) {
            stopMonitoring();
            return;
          }
          
          final currentInfo = _getCurrentBatteryInfo?.call();
          if (currentInfo?.isCharging != true) {
            stopMonitoring();
            return;
          }
          
          await updateChargingCurrent();
          
          // 간격 동적 조정 (매 5회마다)
          if (_recentChargingCurrents.length % 5 == 0) {
            _adjustMonitoringInterval();
            _restartChargingCurrentTimer();
          }
        },
      );
    }
  }
  
  /// 충전 전류 전용 모니터링 중지
  void stopMonitoring() {
    debugPrint('충전 전류 전용 모니터링 중지');
    _chargingCurrentTimer?.cancel();
    _chargingCurrentTimer = null;
  }
  
  /// 충전 전류만 빠르게 업데이트 (안정성 추적 포함)
  Future<void> updateChargingCurrent() async {
    if (_isDisposed?.call() == true) {
      debugPrint('서비스가 이미 dispose됨, 충전 전류 업데이트 건너뜀');
      return;
    }
    
    try {
      debugPrint('충전 전류만 업데이트 시작...');
      
      // 네이티브에서 충전 전류만 빠르게 가져오기
      final chargingCurrent = await NativeBatteryService.getChargingCurrentOnly();
      
      final currentInfo = _getCurrentBatteryInfo?.call();
      if (chargingCurrent >= 0 && currentInfo != null) {
        // 충전 전류 안정성 추적을 위한 데이터 수집
        _recentChargingCurrents.add(chargingCurrent);
        if (_recentChargingCurrents.length > _stabilityCheckCount) {
          _recentChargingCurrents.removeAt(0); // 오래된 데이터 제거
        }
        
        // 충전 전류가 실제로 변경된 경우에만 업데이트 및 저장
        if (currentInfo.chargingCurrent != chargingCurrent) {
          debugPrint('충전 전류 변화 감지: ${currentInfo.chargingCurrent}mA → ${chargingCurrent}mA');
          
          // 기존 배터리 정보의 충전 전류만 업데이트
          final updatedBatteryInfo = currentInfo.copyWith(
            chargingCurrent: chargingCurrent,
            timestamp: DateTime.now(),
          );
          
          // 콜백을 통해 업데이트된 정보 전달
          _onChargingCurrentUpdate?.call(updatedBatteryInfo);
          
          // 충전 전류 데이터를 데이터베이스에 저장 (배치 처리)
          await _saveChargingCurrentToDatabase(chargingCurrent);
          
          debugPrint('충전 전류 업데이트 완료: ${chargingCurrent}mA');
        }
      }
      
    } catch (e) {
      debugPrint('충전 전류 업데이트 실패: $e');
    }
  }
  
  /// 충전 전류 데이터를 데이터베이스에 저장 (배치 처리)
  Future<void> _saveChargingCurrentToDatabase(int currentMa) async {
    try {
      // 데이터베이스 초기화 확인
      if (!_isDatabaseInitialized) {
        await _databaseService.initialize();
        _isDatabaseInitialized = true;
      }
      
      // 현재 시간과 충전 전류를 버퍼에 추가
      _chargingCurrentBuffer.add({
        'timestamp': DateTime.now(),
        'currentMa': currentMa,
      });
      
      // 배치 저장 타이머가 없으면 시작 (10초마다 저장)
      _chargingCurrentSaveTimer ??= Timer.periodic(Duration(seconds: 10), (timer) async {
        if (_chargingCurrentBuffer.isNotEmpty) {
          final pointsToSave = List<Map<String, dynamic>>.from(_chargingCurrentBuffer);
          _chargingCurrentBuffer.clear();
          
          try {
            await _databaseService.insertChargingCurrentPoints(pointsToSave);
            debugPrint('충전 전류 데이터 ${pointsToSave.length}개 배치 저장 완료');
            
            // 저장 후 7일 이상 된 데이터 자동 정리 (주기적으로만 실행)
            // 매 저장마다 실행하면 성능 저하가 있으므로, 10번 중 1번만 실행
            if (DateTime.now().second % 10 == 0) {
              await _databaseService.cleanupOldChargingCurrentData();
            }
          } catch (e) {
            debugPrint('충전 전류 데이터 배치 저장 실패: $e');
            // 실패 시 다시 버퍼에 추가
            _chargingCurrentBuffer.addAll(pointsToSave);
          }
        }
      });
      
      // 버퍼가 너무 크면 (100개 이상) 즉시 저장
      if (_chargingCurrentBuffer.length >= 100) {
        final pointsToSave = List<Map<String, dynamic>>.from(_chargingCurrentBuffer);
        _chargingCurrentBuffer.clear();
        
        try {
          await _databaseService.insertChargingCurrentPoints(pointsToSave);
          debugPrint('충전 전류 데이터 ${pointsToSave.length}개 즉시 저장 완료 (버퍼 초과)');
          
          // 저장 후 7일 이상 된 데이터 자동 정리 (드물게만 실행)
          if (DateTime.now().second % 30 == 0) {
            await _databaseService.cleanupOldChargingCurrentData();
          }
        } catch (e) {
          debugPrint('충전 전류 데이터 즉시 저장 실패: $e');
          // 실패 시 다시 버퍼에 추가
          _chargingCurrentBuffer.addAll(pointsToSave);
        }
      }
    } catch (e) {
      debugPrint('충전 전류 데이터 저장 준비 실패: $e');
    }
  }
  
  /// 충전 전류 버퍼에 남은 데이터를 즉시 저장
  Future<void> flushBuffer() async {
    _chargingCurrentSaveTimer?.cancel();
    _chargingCurrentSaveTimer = null;
    
    if (_chargingCurrentBuffer.isNotEmpty) {
      final pointsToSave = List<Map<String, dynamic>>.from(_chargingCurrentBuffer);
      _chargingCurrentBuffer.clear();
      
      try {
        if (_isDatabaseInitialized) {
          await _databaseService.insertChargingCurrentPoints(pointsToSave);
          debugPrint('충전 전류 데이터 ${pointsToSave.length}개 최종 저장 완료');
        }
      } catch (e) {
        debugPrint('충전 전류 데이터 최종 저장 실패: $e');
      }
    }
  }
  
  /// 안정화된 충전 전류 가져오기 (이동 평균 사용)
  int getStableChargingCurrent(BatteryInfo? currentInfo) {
    if (_recentChargingCurrents.isEmpty) {
      return currentInfo?.chargingCurrent ?? -1;
    }
    
    // 최근 측정값들의 평균 사용 (이동 평균)
    final average = _recentChargingCurrents.reduce((a, b) => a + b) / _recentChargingCurrents.length;
    return average.round();
  }
  
  /// 중앙값 충전 전류 가져오기 (극값의 영향을 줄임)
  int getMedianChargingCurrent(BatteryInfo? currentInfo) {
    if (_recentChargingCurrents.isEmpty) {
      return currentInfo?.chargingCurrent ?? -1;
    }
    
    final sorted = List<int>.from(_recentChargingCurrents)..sort();
    final middle = sorted.length ~/ 2;
    
    if (sorted.length % 2 == 1) {
      return sorted[middle];
    } else {
      return ((sorted[middle - 1] + sorted[middle]) / 2).round();
    }
  }
  
  /// 충전 전류 안정성 상태 확인
  bool isChargingCurrentStable() {
    return _isChargingCurrentStable();
  }
  
  /// 최근 충전 전류 측정값 개수
  int get recentChargingCurrentCount => _recentChargingCurrents.length;
  
  /// 리소스 정리
  void dispose() {
    stopMonitoring();
    flushBuffer();
    _recentChargingCurrents.clear();
    _chargingCurrentInterval = 1000; // 기본값으로 리셋
  }
  
  /// 상태 초기화
  void reset() {
    _recentChargingCurrents.clear();
    _chargingCurrentInterval = 1000; // 기본값으로 리셋
  }
}

