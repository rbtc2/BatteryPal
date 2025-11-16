// 충전 세션 감지 및 추적 서비스
// 3분 이상 유의미한 충전 세션을 감지하고 추적하는 서비스

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../../../models/models.dart';
import '../../../../../services/battery_service.dart';
import '../../../../../services/last_charging_info_service.dart';
import '../../../../../services/battery_history_database_service.dart';
import '../models/charging_session_models.dart';
import 'charging_session_storage.dart';
import 'session_timer_manager.dart';
import 'session_data_collector.dart';
import 'session_record_builder.dart';
import 'date_change_manager.dart';
import 'session_state_manager.dart';
import '../utils/time_slot_utils.dart';

/// 충전 세션 감지 및 추적 서비스 (싱글톤)
/// 
/// 이 서비스는 충전 세션의 전체 생명주기를 관리하는 오케스트레이터 역할을 합니다.
/// 실제 작업은 다음과 같은 전문 서비스들에 위임합니다:
/// 
/// - [SessionStateManager]: 세션 상태 관리 및 전환
/// - [SessionDataCollector]: 데이터 수집 및 전류 변화 감지
/// - [SessionRecordBuilder]: 세션 기록 생성 및 분석
/// - [SessionTimerManager]: 타이머 관리 (데이터 수집, 종료 대기, 자정)
/// - [DateChangeManager]: 날짜 변경 감지 및 데이터 정리
/// - [ChargingSessionStorage]: 세션 데이터 저장 및 조회
/// 
/// 주요 기능:
/// 1. BatteryService 스트림 구독하여 충전 상태 변화 감지
/// 2. 충전 세션 시작/종료 감지 및 상태 관리
/// 3. 세션 진행 중 실시간 데이터 수집
/// 4. 세션 기록 생성 및 저장
/// 5. 날짜 변경 감지 및 과거 데이터 관리
class ChargingSessionService {
  // 싱글톤 인스턴스
  static final ChargingSessionService _instance = 
      ChargingSessionService._internal();
  factory ChargingSessionService() => _instance;
  ChargingSessionService._internal();

  final BatteryService _batteryService = BatteryService();
  final ChargingSessionStorage _storageService = ChargingSessionStorage();
  final SessionTimerManager _timerManager = SessionTimerManager();
  final SessionDataCollector _dataCollector = SessionDataCollector();
  final SessionRecordBuilder _recordBuilder = SessionRecordBuilder();
  final DateChangeManager _dateChangeManager = DateChangeManager();
  final SessionStateManager _stateManager = SessionStateManager();
  
  // 스트림 구독 관리
  StreamSubscription<BatteryInfo>? _batteryInfoSubscription;
  
  // 서비스 상태 관리
  bool _isInitialized = false;
  bool _isDisposed = false;
  
  // ==================== 세션 목록 관리 ====================
  
  /// 세션 변경 스트림 (UI 업데이트용)
  final StreamController<List<ChargingSessionRecord>> _sessionsController = 
      StreamController<List<ChargingSessionRecord>>.broadcast();
  
  /// 세션 목록 스트림
  Stream<List<ChargingSessionRecord>> get sessionsStream => 
      _sessionsController.stream;
  
  /// 오늘 날짜의 세션 목록 가져오기 (동기)
  /// 메모리에 있는 데이터만 반환 (빠른 접근용)
  List<ChargingSessionRecord> getTodaySessions() {
    if (!_isInitialized || _isDisposed) {
      return [];
    }
    try {
      return _storageService.getTodaySessionsSync();
    } catch (e) {
      debugPrint('ChargingSessionService: 오늘 세션 조회 실패 - $e');
      return [];
    }
  }
  
  /// 오늘 날짜의 세션 목록 가져오기 (비동기)
  /// DB에서도 로드하여 최신 데이터 반환
  Future<List<ChargingSessionRecord>> getTodaySessionsAsync() async {
    if (!_isInitialized || _isDisposed) {
      return [];
    }
    try {
      return await _storageService.getTodaySessions();
    } catch (e) {
      debugPrint('ChargingSessionService: 오늘 세션 조회 실패 - $e');
      return [];
    }
  }
  
  /// 현재 진행 중인 세션 가져오기
  ChargingSessionRecord? getCurrentSession() {
    return _stateManager.currentSession;
  }
  
  // ==================== 서비스 초기화 및 정리 ====================
  
  /// 서비스 초기화
  /// 앱 시작 시 호출하여 BatteryService 스트림 구독 시작
  Future<void> initialize() async {
    if (_isInitialized || _isDisposed) {
      debugPrint('ChargingSessionService: 이미 초기화되었거나 dispose됨');
      return;
    }
    
    try {
      debugPrint('ChargingSessionService: 초기화 시작...');
      
      // BatteryService가 모니터링 중인지 확인하고, 없다면 시작
      if (_batteryService.currentBatteryInfo == null) {
        await _batteryService.startMonitoring();
      }
      
      // BatteryService 스트림 구독
      _batteryInfoSubscription = _batteryService.batteryInfoStream.listen(
        _onBatteryInfoUpdate,
        onError: _onError,
        cancelOnError: false,
      );
      
      // Phase 2: 백그라운드 세션 복구 확인
      await _recoverBackgroundSession();
      
      // 현재 충전 상태 확인
      final currentInfo = _batteryService.currentBatteryInfo;
      if (currentInfo != null) {
        _stateManager.setWasCharging(currentInfo.isCharging);
        if (currentInfo.isCharging && currentInfo.chargingCurrent > 0) {
          // 이미 충전 중이면 세션 시작
          _startSession(currentInfo);
        }
      }
      
      // 자정 타이머 시작 (배터리 효율적 날짜 변경 감지)
      _timerManager.scheduleMidnightTimer(
        onMidnight: () {
          _dateChangeManager.checkDateChangeAndSave(
            isDisposed: () => _isDisposed,
            isInitialized: () => _isInitialized,
          );
          _dateChangeManager.cleanupOldSessions(
            isDisposed: () => _isDisposed,
            isInitialized: () => _isInitialized,
          );
        },
        isDisposed: () => _isDisposed,
        isInitialized: () => _isInitialized,
      );
      
      _isInitialized = true;
      debugPrint('ChargingSessionService: 초기화 완료');
      
    } catch (e, stackTrace) {
      debugPrint('ChargingSessionService: 초기화 실패 - $e');
      debugPrint('스택 트레이스: $stackTrace');
      rethrow;
    }
  }
  
  /// 서비스 정리
  void dispose() {
    if (_isDisposed) return;
    
    debugPrint('ChargingSessionService: dispose 시작...');
    
    _isDisposed = true;
    
    // 모든 타이머 정리
    _timerManager.dispose();
    
    // 스트림 구독 해제
    _batteryInfoSubscription?.cancel();
    _batteryInfoSubscription = null;
    
    // 현재 세션이 있으면 종료 처리 (dispose는 동기 함수이므로 unawaited 사용)
    if (_stateManager.isActive || _stateManager.isEnding) {
      // 비동기 작업이지만 dispose에서는 await하지 않음
      // _isDisposed 플래그로 _endSession 내부에서 추가 작업 방지
      _endSession().catchError((e) {
        debugPrint('ChargingSessionService: dispose 중 세션 종료 실패 - $e');
      });
    }
    
    // 스트림 컨트롤러 닫기
    if (!_sessionsController.isClosed) {
      _sessionsController.close();
    }
    
    debugPrint('ChargingSessionService: dispose 완료');
  }
  
  // ==================== 날짜 변경 감지 및 저장 ====================
  
  /// 날짜 변경 감지 및 과거 세션 저장
  /// 
  /// 공개 메서드로 만들어서 앱 포그라운드 복귀 시에도 호출 가능
  void checkDateChangeAndSave() {
    _dateChangeManager.checkDateChangeAndSave(
      isDisposed: () => _isDisposed,
      isInitialized: () => _isInitialized,
    );
  }
  
  // ==================== 배터리 정보 업데이트 처리 ====================
  
  /// 배터리 정보 업데이트 처리
  void _onBatteryInfoUpdate(BatteryInfo batteryInfo) {
    if (_isDisposed) return;
    
    // 날짜 변경 체크 (1분마다 체크하지만, 배터리 업데이트 시에도 체크)
    _dateChangeManager.checkDateChangeAndSave(
      isDisposed: () => _isDisposed,
      isInitialized: () => _isInitialized,
    );
    
    try {
      final isCurrentlyCharging = batteryInfo.isCharging;
      final chargingCurrent = batteryInfo.chargingCurrent;
      
      // 충전 상태 변화 감지
      if (isCurrentlyCharging && !_stateManager.wasCharging) {
        // 충전 시작
        debugPrint('ChargingSessionService: 충전 시작 감지');
        
        // ending 상태에서 재연결된 경우 (20초 이내 재연결)
        if (_stateManager.isEnding) {
          // 같은 충전기인지 확인
          if (_stateManager.isSameCharger(batteryInfo)) {
            // 같은 충전기 → 세션 재활성화 (한 세션으로 처리)
            debugPrint('ChargingSessionService: 같은 충전기로 재연결 - 세션 재활성화');
            _stateManager.reactivateSession();
            _timerManager.stopEndWaitTimer(); // 종료 대기 타이머 취소
            _stateManager.setWasCharging(true);
            // 충전 중 업데이트 처리 (데이터 수집 재개)
            _handleChargingUpdate(batteryInfo);
          } else {
            // 다른 충전기 → 기존 세션 즉시 저장 후 새 세션 시작
            debugPrint('ChargingSessionService: 다른 충전기로 연결 - 기존 세션 즉시 저장 후 새 세션 시작');
            // 기존 세션 즉시 종료 (30초 대기 없이)
            _endSessionImmediately().then((_) {
              // 세션 종료 후 새 세션 시작
              if (!_isDisposed) {
                _startSession(batteryInfo);
                _stateManager.setWasCharging(true);
              }
            }).catchError((e) {
              debugPrint('ChargingSessionService: 세션 종료 실패 - $e');
              // 에러 발생해도 새 세션 시작 시도
              if (!_isDisposed) {
                _startSession(batteryInfo);
                _stateManager.setWasCharging(true);
              }
            });
          }
        } else {
          // 일반적인 새 세션 시작
          _startSession(batteryInfo);
          _stateManager.setWasCharging(true);
        }
        
      } else if (!isCurrentlyCharging && _stateManager.wasCharging) {
        // 충전 종료
        debugPrint('ChargingSessionService: 충전 종료 감지');
        _handleChargingEnd();
        _stateManager.setWasCharging(false);
        
      } else if (isCurrentlyCharging && chargingCurrent > 0) {
        // 충전 중 - 전류 변화 감지 및 데이터 수집
        _handleChargingUpdate(batteryInfo);
      }
      
    } catch (e, stackTrace) {
      debugPrint('ChargingSessionService: 배터리 정보 업데이트 처리 실패 - $e');
      debugPrint('스택 트레이스: $stackTrace');
    }
  }
  
  /// 에러 처리
  void _onError(dynamic error) {
    debugPrint('ChargingSessionService: 스트림 에러 - $error');
    // 에러 발생 시에도 서비스는 계속 실행
  }
  
  // ==================== 세션 시작 처리 ====================
  
  /// 세션 시작
  void _startSession(BatteryInfo batteryInfo) {
    if (!_stateManager.startSession(batteryInfo)) {
      return;
    }
    
    try {
      debugPrint('ChargingSessionService: 세션 시작');
      
      // 데이터 수집 초기화
      _dataCollector.reset();
      
      // 첫 데이터 포인트 추가
      _dataCollector.addDataPoint(
        batteryInfo,
        sessionStartTime: _stateManager.startTime,
        isDisposed: () => _isDisposed,
      );
      
      // 데이터 수집 타이머 시작
      _timerManager.startDataCollectionTimer(
        onTick: () {
          final batteryInfo = _batteryService.currentBatteryInfo;
          if (batteryInfo != null && 
              batteryInfo.isCharging && 
              batteryInfo.chargingCurrent > 0) {
            _dataCollector.addDataPoint(
              batteryInfo,
              sessionStartTime: _stateManager.startTime,
              isDisposed: () => _isDisposed,
            );
          }
        },
        isActive: () => _stateManager.isActive && !_isDisposed,
      );
      
      debugPrint('ChargingSessionService: 세션 시작 완료 - 시작 배터리: ${batteryInfo.level}%');
      
    } catch (e, stackTrace) {
      debugPrint('ChargingSessionService: 세션 시작 실패 - $e');
      debugPrint('스택 트레이스: $stackTrace');
      _resetSession();
    }
  }
  
  // ==================== 세션 종료 처리 ====================
  
  /// 충전 종료 처리
  void _handleChargingEnd() {
    if (!_stateManager.startEndWait()) {
      return;
    }
    
    debugPrint('ChargingSessionService: 세션 종료 대기 시작');
    
    // 종료 대기 타이머 시작
    _timerManager.startEndWaitTimer(
      onComplete: () {
        if (_stateManager.isEnding && _stateManager.endWaitStartTime != null) {
          final waitDuration = DateTime.now().difference(_stateManager.endWaitStartTime!);
          debugPrint('ChargingSessionService: 종료 대기 완료 (${waitDuration.inSeconds}초 대기)');
          _endSession().catchError((e) {
            debugPrint('ChargingSessionService: 종료 대기 타이머에서 세션 종료 실패 - $e');
          });
        }
      },
      isDisposed: () => _isDisposed,
    );
  }
  
  
  /// 세션 종료 (20초 대기 후)
  Future<void> _endSession() async {
    if (_stateManager.isIdle || _isDisposed) {
      return;
    }
    
    try {
      debugPrint('ChargingSessionService: 세션 종료 처리 시작');
      
      // 데이터 수집 타이머 중지
      _timerManager.stopDataCollectionTimer();
      
      // dispose된 경우 추가 작업 중단
      if (_isDisposed) {
        _resetSession();
        return;
      }
      
      // 마지막 배터리 정보 가져오기
      final endBatteryInfo = _batteryService.currentBatteryInfo;
      if (endBatteryInfo == null || _stateManager.startBatteryInfo == null) {
        debugPrint('ChargingSessionService: 배터리 정보가 없어 세션을 종료할 수 없습니다');
        _resetSession();
        return;
      }
      
      // dispose된 경우 추가 작업 중단
      if (_isDisposed) {
        _resetSession();
        return;
      }
      
      // 세션 데이터 분석 및 기록 생성
      final sessionRecord = await _recordBuilder.buildSessionRecord(
        dataCollector: _dataCollector,
        startTime: _stateManager.startTime!,
        startBatteryInfo: _stateManager.startBatteryInfo!,
        endBatteryInfo: endBatteryInfo,
      );
      
      // dispose된 경우 추가 작업 중단
      if (_isDisposed || sessionRecord == null) {
        _resetSession();
        return;
      }
      
      if (sessionRecord.validate()) {
        // 유효한 세션이면 저장소에 저장
        try {
          final saved = await _storageService.saveSession(sessionRecord, saveToDatabase: true);
          if (saved && !_isDisposed) {
            // 세션 목록 업데이트 알림
            _notifySessionsChanged();
            debugPrint('ChargingSessionService: 세션 저장 완료 - ${sessionRecord.sessionTitle}');
            
            // 마지막 충전 정보 저장
            try {
              await LastChargingInfoService().saveLastChargingInfo(
                endTime: sessionRecord.endTime,
                avgCurrent: sessionRecord.avgCurrent.toInt(),
                batteryLevel: sessionRecord.endBatteryLevel,
              );
              debugPrint('ChargingSessionService: 마지막 충전 정보 저장 완료');
            } catch (e) {
              debugPrint('ChargingSessionService: 마지막 충전 정보 저장 실패 - $e');
            }
          } else if (!saved) {
            debugPrint('ChargingSessionService: 세션 저장 실패 - ${sessionRecord.sessionTitle}');
            // 저장 실패해도 세션 목록은 업데이트 (메모리에만 있을 수 있음)
            if (!_isDisposed) {
              _notifySessionsChanged();
            }
          }
        } catch (e, stackTrace) {
          debugPrint('ChargingSessionService: 세션 저장 중 오류 발생 - $e');
          debugPrint('스택 트레이스: $stackTrace');
          // 저장 실패해도 세션 목록은 업데이트 시도
          if (!_isDisposed) {
            _notifySessionsChanged();
          }
        }
      } else {
        debugPrint('ChargingSessionService: 세션이 유효하지 않아 저장하지 않습니다');
        debugPrint('ChargingSessionService: 세션 검증 실패 - duration: ${sessionRecord.duration.inMinutes}분, avgCurrent: ${sessionRecord.avgCurrent}mA, batteryChange: ${sessionRecord.batteryChange}%');
      }
      
      // 세션 초기화
      _resetSession();
      
      // 세션이 완전히 종료되었으므로 충전기 정보도 초기화
      _stateManager.clearChargerInfo();
      
    } catch (e, stackTrace) {
      debugPrint('ChargingSessionService: 세션 종료 실패 - $e');
      debugPrint('스택 트레이스: $stackTrace');
      _resetSession();
      _stateManager.clearChargerInfo();
    }
  }
  
  /// 세션 즉시 종료 (20초 대기 없이)
  /// 다른 충전기로 연결된 경우 기존 세션을 즉시 저장하기 위해 사용
  Future<void> _endSessionImmediately() async {
    if (_stateManager.isIdle || _isDisposed) {
      return;
    }
    
    debugPrint('ChargingSessionService: 세션 즉시 종료 처리 시작 (20초 대기 없이)');
    
    // 종료 대기 타이머 취소
    _timerManager.stopEndWaitTimer();
    
    // _endSession과 동일한 로직이지만 즉시 실행
    await _endSession();
  }
  
  /// 세션 초기화
  void _resetSession() {
    // 종료 대기 타이머 취소
    _timerManager.stopEndWaitTimer();
    
    // 데이터 수집 타이머 중지
    _timerManager.stopDataCollectionTimer();
    
    // 모든 데이터 포인트 정리
    _dataCollector.reset();
    
    // 상태 리셋
    _stateManager.reset();
  }
  
  // ==================== 충전 중 업데이트 처리 ====================
  
  /// 충전 중 업데이트 처리
  void _handleChargingUpdate(BatteryInfo batteryInfo) {
    // active 또는 ending 상태에서 모두 처리 가능
    // ending 상태에서 재연결된 경우는 _onBatteryInfoUpdate에서 이미 reactivateSession 호출됨
    if (!_stateManager.isActive && !_stateManager.isEnding) {
      return;
    }
    
    // 종료 대기 상태였다면 다시 활성 상태로 (추가 안전장치)
    if (_stateManager.isEnding) {
      _stateManager.reactivateSession();
      _timerManager.stopEndWaitTimer(); // 종료 대기 타이머 취소
    }
    
    // 전류 변화 감지 및 데이터 포인트 추가
    // (타이머가 자동으로 추가하지만, 전류 변화 시 즉시 추가)
    _dataCollector.addDataPoint(
      batteryInfo,
      sessionStartTime: _stateManager.startTime,
      isDisposed: () => _isDisposed,
    );
  }
  
  
  
  /// 세션 목록 변경 알림
  void _notifySessionsChanged() {
    if (!_sessionsController.isClosed && !_isDisposed) {
      // 동기 메서드로 빠르게 알림
      final sessions = getTodaySessions();
      _sessionsController.add(sessions);
      
      // 비동기로 최신 데이터도 로드하여 업데이트 (백그라운드)
      getTodaySessionsAsync().then((latestSessions) {
        if (!_sessionsController.isClosed && !_isDisposed) {
          _sessionsController.add(latestSessions);
        }
      }).catchError((e) {
        debugPrint('ChargingSessionService: 최신 세션 로드 실패 - $e');
      });
    }
  }
  
  // ==================== 백그라운드 세션 복구 ====================
  
  /// Phase 2: 백그라운드 세션 복구 (개선됨)
  /// 네이티브에서 저장한 세션 정보와 데이터베이스의 백그라운드 데이터를 확인하여 복구합니다.
  Future<void> _recoverBackgroundSession() async {
    if (_isDisposed) return;
    
    try {
      debugPrint('ChargingSessionService: 백그라운드 세션 복구 확인 시작...');
      
      // 1. 네이티브에서 충전 세션 정보 가져오기
      final sessionInfo = await NativeBatteryService.getChargingSessionInfo();
      
      // 2. 데이터베이스에서 백그라운드 데이터로부터 완료된 세션 분석
      await _analyzeBackgroundSessionsFromDatabase();
      
      if (sessionInfo == null) {
        debugPrint('ChargingSessionService: 네이티브 세션 정보 없음');
        return;
      }
      
      debugPrint('ChargingSessionService: 네이티브 세션 정보 발견 - $sessionInfo');
      
      // 3. 세션이 아직 진행 중인 경우 복구
      if (sessionInfo.isChargingActive && sessionInfo.startTime != null) {
        final currentInfo = _batteryService.currentBatteryInfo;
        
        // 현재 배터리 정보가 있고 충전 중이면 세션 복구
        if (currentInfo != null && currentInfo.isCharging) {
          debugPrint('ChargingSessionService: 진행 중인 백그라운드 세션 복구 - 시작 시간: ${sessionInfo.startTime}');
          
          // 세션 시작 시간을 네이티브에서 가져온 시간으로 설정
          if (sessionInfo.startBatteryLevel != null) {
            _stateManager.setWasCharging(true);
            
            // 세션 시작 (시작 시간은 네이티브 시간 사용)
            if (!_stateManager.isActive) {
              _startSession(currentInfo);
              
              // 시작 시간을 네이티브 시간으로 업데이트
              if (sessionInfo.startTime != null) {
                _stateManager.updateStartTime(sessionInfo.startTime!);
                debugPrint('ChargingSessionService: 세션 시작 시간을 네이티브 시간으로 업데이트 - ${sessionInfo.startTime}');
              }
            }
          } else {
            // 시작 배터리 레벨이 없으면 일반적으로 세션 시작
            _stateManager.setWasCharging(true);
            if (!_stateManager.isActive) {
              _startSession(currentInfo);
              if (sessionInfo.startTime != null) {
                _stateManager.updateStartTime(sessionInfo.startTime!);
              }
            }
          }
        } else {
          debugPrint('ChargingSessionService: 현재 충전 중이 아니므로 세션 복구 불가');
        }
      } else {
        debugPrint('ChargingSessionService: 진행 중인 세션 없음');
      }
      
      debugPrint('ChargingSessionService: 백그라운드 세션 복구 완료');
    } catch (e, stackTrace) {
      debugPrint('ChargingSessionService: 백그라운드 세션 복구 실패 - $e');
      debugPrint('스택 트레이스: $stackTrace');
    }
  }
  
  /// Phase 2: 데이터베이스의 백그라운드 데이터로부터 완료된 세션 분석 및 복구
  /// WorkManager에서 수집한 백그라운드 데이터를 분석하여 완료된 세션을 복구합니다.
  Future<void> _analyzeBackgroundSessionsFromDatabase() async {
    if (_isDisposed) return;
    
    try {
      debugPrint('ChargingSessionService: 백그라운드 데이터로부터 세션 분석 시작...');
      
      // 데이터베이스 서비스를 통해 데이터베이스 접근
      final databaseService = BatteryHistoryDatabaseService();
      final db = databaseService.database;
      if (db == null) {
        debugPrint('ChargingSessionService: 데이터베이스가 초기화되지 않음');
        return;
      }
      
      // 최근 24시간 내의 백그라운드 데이터 확인
      final cutoffTime = DateTime.now().subtract(const Duration(hours: 24));
      final cutoffTimestamp = cutoffTime.millisecondsSinceEpoch;
      
      // 백그라운드 데이터 조회 (collection_method = 'background_workmanager')
      final results = await db.query(
        'battery_history',
        columns: ['timestamp', 'is_charging', 'battery_level', 'charging_current'],
        where: 'timestamp >= ? AND collection_method = ?',
        whereArgs: [cutoffTimestamp, 'background_workmanager'],
        orderBy: 'timestamp ASC',
      );
      
      if (results.isEmpty) {
        debugPrint('ChargingSessionService: 백그라운드 데이터 없음');
        return;
      }
      
      debugPrint('ChargingSessionService: 백그라운드 데이터 ${results.length}개 발견, 세션 분석 시작...');
      
      // 충전 시작/종료 패턴 분석하여 세션 추출
      final sessions = <Map<String, dynamic>>[];
      DateTime? sessionStart;
      int? startBatteryLevel;
      int? startChargingCurrent;
      
      for (final row in results) {
        final timestamp = DateTime.fromMillisecondsSinceEpoch(row['timestamp'] as int);
        final isCharging = (row['is_charging'] as int) == 1;
        final batteryLevel = row['battery_level'] as double? ?? 0.0;
        final chargingCurrent = row['charging_current'] as int? ?? 0;
        
        if (isCharging && sessionStart == null) {
          // 충전 시작
          sessionStart = timestamp;
          startBatteryLevel = batteryLevel.toInt();
          startChargingCurrent = chargingCurrent;
        } else if (!isCharging && sessionStart != null) {
          // 충전 종료 - 세션 완료
          final duration = timestamp.difference(sessionStart!);
          
          // 최소 3분 이상 지속된 세션만 저장
          if (duration.inMinutes >= 3) {
            sessions.add({
              'startTime': sessionStart,
              'endTime': timestamp,
              'duration': duration,
              'startBatteryLevel': startBatteryLevel,
              'endBatteryLevel': batteryLevel.toInt(),
              'startChargingCurrent': startChargingCurrent,
            });
            debugPrint('ChargingSessionService: 백그라운드 세션 발견 - ${sessionStart} ~ ${timestamp} (${duration.inMinutes}분)');
          }
          
          sessionStart = null;
          startBatteryLevel = null;
          startChargingCurrent = null;
        }
      }
      
      // 마지막 세션이 아직 종료되지 않은 경우 (현재 충전 중)
      if (sessionStart != null) {
        final currentInfo = _batteryService.currentBatteryInfo;
        if (currentInfo != null && currentInfo.isCharging) {
          // 현재 충전 중이면 세션 복구 (위에서 처리됨)
          debugPrint('ChargingSessionService: 진행 중인 백그라운드 세션 발견 - ${sessionStart}');
        }
      }
      
      // 완료된 세션들을 저장소에 저장 (중복 체크 포함)
      int recoveredCount = 0;
      for (final session in sessions) {
        try {
          // 이미 저장된 세션인지 확인 (시작 시간 기준)
          final existingSessions = await storageService.getTodaySessions();
          final isDuplicate = existingSessions.any((s) => 
            s.startTime.difference(session['startTime'] as DateTime).abs().inMinutes < 1
          );
          
          if (!isDuplicate) {
            // 백그라운드 세션을 위한 간단한 세션 기록 생성
            // SessionRecordBuilder를 사용하지 않고 직접 생성 (백그라운드 데이터는 상세 정보 없음)
            final startTime = session['startTime'] as DateTime;
            final endTime = session['endTime'] as DateTime;
            final duration = session['duration'] as Duration;
            final startBatteryLevel = session['startBatteryLevel'] as int;
            final endBatteryLevel = session['endBatteryLevel'] as int;
            final batteryChange = endBatteryLevel - startBatteryLevel;
            final avgCurrent = session['startChargingCurrent'] as int? ?? 0;
            
            // 세션 ID 생성
            final sessionId = 'session_${startTime.millisecondsSinceEpoch}';
            
            // 시간대 계산 (TimeSlotUtils 사용)
            final timeSlot = TimeSlotUtils.getTimeSlot(startTime);
            
            // 세션 제목 생성 (기존 제목과 중복되지 않도록)
            final existingTitles = existingSessions
                .map((s) => s.sessionTitle)
                .toList();
            final sessionTitle = TimeSlotUtils.generateSessionTitle(timeSlot, existingTitles);
            
            // 세션 기록 생성 (최소한의 정보만 포함)
            final sessionRecord = ChargingSessionRecord(
              id: sessionId,
              startTime: startTime,
              endTime: endTime,
              startBatteryLevel: startBatteryLevel.toDouble(),
              endBatteryLevel: endBatteryLevel.toDouble(),
              batteryChange: batteryChange.toDouble(),
              duration: duration,
              avgCurrent: avgCurrent.toDouble(),
              avgTemperature: 0.0, // 백그라운드 데이터에는 온도 정보 없음
              maxCurrent: avgCurrent,
              minCurrent: avgCurrent,
              efficiency: 0.0, // 백그라운드 데이터에는 효율 계산 불가
              timeSlot: timeSlot,
              sessionTitle: sessionTitle,
              speedChanges: [], // 백그라운드 데이터에는 상세 변화 이력 없음
              icon: TimeSlotUtils.getTimeSlotIcon(timeSlot),
              color: TimeSlotUtils.getTimeSlotColor(timeSlot),
              batteryCapacity: null,
              batteryVoltage: null,
              isValid: true,
            );
            
            if (sessionRecord.validate()) {
              await storageService.saveSession(sessionRecord, saveToDatabase: true);
              recoveredCount++;
              debugPrint('ChargingSessionService: 백그라운드 세션 복구 완료 - ${session['startTime']}');
            } else {
              debugPrint('ChargingSessionService: 백그라운드 세션이 유효하지 않음 - ${session['startTime']}');
            }
          }
        } catch (e) {
          debugPrint('ChargingSessionService: 백그라운드 세션 저장 실패 - $e');
        }
      }
      
      if (recoveredCount > 0) {
        debugPrint('ChargingSessionService: 백그라운드 세션 ${recoveredCount}개 복구 완료');
        _notifySessionsChanged();
      } else {
        debugPrint('ChargingSessionService: 복구할 백그라운드 세션 없음');
      }
      
    } catch (e, stackTrace) {
      debugPrint('ChargingSessionService: 백그라운드 세션 분석 실패 - $e');
      debugPrint('스택 트레이스: $stackTrace');
    }
  }

  // ==================== 유틸리티 ====================

  /// 초기화 상태 확인
  bool get isInitialized => _isInitialized;

  /// 현재 세션 상태 확인
  SessionState get sessionState => _stateManager.state;

  /// 세션 진행 중인지 확인
  bool get isSessionActive => _stateManager.isActive;
  
  /// 세션 시작 시간 가져오기
  DateTime? get sessionStartTime => _stateManager.startTime;
  
  /// 세션 시작 시 배터리 정보 가져오기
  BatteryInfo? get startBatteryInfo => _stateManager.startBatteryInfo;

  /// 서비스 상태 검증 (디버깅 및 통합 테스트용)
  Map<String, dynamic> getServiceStatus() {
    return {
      'isInitialized': _isInitialized,
      'isDisposed': _isDisposed,
      'stateManagerStatus': _stateManager.getStatus(),
      'dataCollectorStatus': _dataCollector.getStatus(),
      'timerStatus': _timerManager.getTimerStatus(),
      'dateChangeManagerStatus': _dateChangeManager.getStatus(),
    };
  }
}


