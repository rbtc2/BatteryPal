// 충전 세션 감지 및 추적 서비스
// 5분 이상 유의미한 충전 세션을 감지하고 추적하는 서비스

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../../../models/app_models.dart';
import '../../../../../services/battery_service.dart';
import '../models/charging_session_models.dart';
import '../config/charging_session_config.dart';
import '../utils/time_slot_utils.dart';
import 'charging_session_analyzer.dart' as charging_session_analyzer;
import 'charging_session_storage.dart';

/// 세션 상태 enum
enum SessionState {
  /// 대기 중 (충전 중이 아님)
  idle,
  
  /// 세션 진행 중 (충전 중, 데이터 수집 중)
  active,
  
  /// 세션 종료 대기 중 (전류가 0이 되었지만 아직 종료 판단 전)
  ending,
}

/// 충전 세션 감지 및 추적 서비스 (싱글톤)
/// 
/// 주요 기능:
/// 1. BatteryService 스트림 구독하여 충전 상태 변화 감지
/// 2. 충전 세션 시작/종료 감지
/// 3. 세션 진행 중 실시간 데이터 수집
/// 4. 전류 변화 이력 추적
/// 5. 세션 유효성 검증
class ChargingSessionService {
  // 싱글톤 인스턴스
  static final ChargingSessionService _instance = 
      ChargingSessionService._internal();
  factory ChargingSessionService() => _instance;
  ChargingSessionService._internal();

  final BatteryService _batteryService = BatteryService();
  final ChargingSessionStorage _storageService = ChargingSessionStorage();
  
  // 스트림 구독 관리
  StreamSubscription<BatteryInfo>? _batteryInfoSubscription;
  
  // 서비스 상태 관리
  bool _isInitialized = false;
  bool _isDisposed = false;
  
  // 날짜 변경 감지를 위한 마지막 저장 날짜 추적
  String? _lastSavedDateKey;
  
  // ==================== 세션 상태 관리 ====================
  
  /// 현재 세션 상태
  SessionState _sessionState = SessionState.idle;
  
  /// 현재 진행 중인 세션 데이터
  ChargingSessionRecord? _currentSession;
  
  /// 세션 시작 시간
  DateTime? _sessionStartTime;
  
  /// 세션 종료 대기 시작 시간 (전류가 0이 된 시점)
  /// 종료 대기 타이머에서 사용
  DateTime? _sessionEndWaitStartTime;
  
  /// 이전 충전 상태 (충전 시작/종료 감지용)
  bool _wasCharging = false;
  
  // ==================== 세션 데이터 수집 ====================
  
  /// 세션 데이터 수집 타이머
  Timer? _dataCollectionTimer;
  
  /// 수집된 데이터 포인트들
  final List<SessionDataPoint> _collectedDataPoints = [];
  
  /// 이전 전류값 (전류 변화 감지용)
  int? _previousCurrent;
  
  /// 이전 전류값의 타임스탬프
  DateTime? _previousCurrentTime;
  
  /// 전류 변화 이벤트 목록
  final List<CurrentChangeEvent> _speedChanges = [];
  
  /// 세션 시작 시 배터리 정보
  BatteryInfo? _startBatteryInfo;
  
  // ==================== 세션 목록 관리 ====================
  
  /// 오늘 날짜의 완료된 세션 목록
  final List<ChargingSessionRecord> _todaySessions = [];
  
  /// 세션 변경 스트림 (UI 업데이트용)
  final StreamController<List<ChargingSessionRecord>> _sessionsController = 
      StreamController<List<ChargingSessionRecord>>.broadcast();
  
  /// 세션 목록 스트림
  Stream<List<ChargingSessionRecord>> get sessionsStream => 
      _sessionsController.stream;
  
  /// 오늘 날짜의 세션 목록 가져오기
  List<ChargingSessionRecord> getTodaySessions() {
    return List.unmodifiable(_todaySessions);
  }
  
  /// 현재 진행 중인 세션 가져오기
  ChargingSessionRecord? getCurrentSession() {
    return _currentSession;
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
      
      // 현재 충전 상태 확인
      final currentInfo = _batteryService.currentBatteryInfo;
      if (currentInfo != null) {
        _wasCharging = currentInfo.isCharging;
        if (_wasCharging && currentInfo.chargingCurrent > 0) {
          // 이미 충전 중이면 세션 시작
          _startSession(currentInfo);
        }
      }
      
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
    
    // 현재 세션이 있으면 종료 처리 (dispose는 동기 함수이므로 unawaited 사용)
    if (_sessionState == SessionState.active) {
      _endSession(); // dispose에서는 await하지 않음
    }
    
    // 타이머 정리
    _dataCollectionTimer?.cancel();
    _dataCollectionTimer = null;
    
    // 스트림 구독 해제
    _batteryInfoSubscription?.cancel();
    _batteryInfoSubscription = null;
    
    // 스트림 컨트롤러 닫기
    _sessionsController.close();
    
    // Storage 서비스 정리
    _storageService.dispose();
    
    debugPrint('ChargingSessionService: dispose 완료');
  }
  
  // ==================== 날짜 변경 감지 및 저장 ====================
  
  /// 날짜 키 생성
  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
  
  /// 날짜 변경 감지 및 과거 세션 저장
  void _checkDateChangeAndSave() {
    if (_isDisposed || !_isInitialized) return;
    
    try {
      final now = DateTime.now();
      final todayKey = _getDateKey(now);
      
      // 마지막 저장 날짜가 없으면 오늘 날짜로 초기화
      if (_lastSavedDateKey == null) {
        _lastSavedDateKey = todayKey;
        return;
      }
      
      // 날짜가 바뀌었는지 확인
      if (_lastSavedDateKey != todayKey) {
        debugPrint('ChargingSessionService: 날짜 변경 감지 - $_lastSavedDateKey -> $todayKey');
        
        // 어제 날짜의 세션을 DB에 저장
        final yesterday = now.subtract(const Duration(days: 1));
        _storageService.saveDateSessionsToDatabase(yesterday).then((count) {
          if (count > 0) {
            debugPrint('ChargingSessionService: 어제 세션 $count개 DB 저장 완료');
          }
        }).catchError((e) {
          debugPrint('ChargingSessionService: 어제 세션 저장 실패 - $e');
        });
        
        // 모든 과거 세션 저장 (7일 전까지)
        _storageService.saveAllPastSessionsToDatabase(todayKey).then((count) {
          if (count > 0) {
            debugPrint('ChargingSessionService: 과거 세션 $count개 DB 저장 완료');
          }
        }).catchError((e) {
          debugPrint('ChargingSessionService: 과거 세션 저장 실패 - $e');
        });
        
        // 오늘 날짜로 업데이트
        _lastSavedDateKey = todayKey;
      }
    } catch (e, stackTrace) {
      debugPrint('ChargingSessionService: 날짜 변경 감지 실패 - $e');
      debugPrint('스택 트레이스: $stackTrace');
    }
  }
  
  // ==================== 배터리 정보 업데이트 처리 ====================
  
  /// 배터리 정보 업데이트 처리
  void _onBatteryInfoUpdate(BatteryInfo batteryInfo) {
    if (_isDisposed) return;
    
    // 날짜 변경 체크 (1분마다 체크하지만, 배터리 업데이트 시에도 체크)
    _checkDateChangeAndSave();
    
    try {
      final isCurrentlyCharging = batteryInfo.isCharging;
      final chargingCurrent = batteryInfo.chargingCurrent;
      
      // 충전 상태 변화 감지
      if (isCurrentlyCharging && !_wasCharging) {
        // 충전 시작
        debugPrint('ChargingSessionService: 충전 시작 감지');
        _startSession(batteryInfo);
        _wasCharging = true;
        
      } else if (!isCurrentlyCharging && _wasCharging) {
        // 충전 종료
        debugPrint('ChargingSessionService: 충전 종료 감지');
        _handleChargingEnd();
        _wasCharging = false;
        
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
    if (_sessionState != SessionState.idle) {
      debugPrint('ChargingSessionService: 세션이 이미 진행 중입니다');
      return;
    }
    
    try {
      debugPrint('ChargingSessionService: 세션 시작');
      
      _sessionState = SessionState.active;
      _sessionStartTime = DateTime.now();
      _startBatteryInfo = batteryInfo;
      
      // 데이터 수집 초기화
      _collectedDataPoints.clear();
      _speedChanges.clear();
      _previousCurrent = null;
      _previousCurrentTime = null;
      
      // 첫 데이터 포인트 추가
      _addDataPoint(batteryInfo);
      
      // 데이터 수집 타이머 시작
      _startDataCollectionTimer();
      
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
    if (_sessionState == SessionState.idle) {
      return;
    }
    
    // 세션 종료 대기 상태로 전환
    if (_sessionState == SessionState.active) {
      _sessionState = SessionState.ending;
      _sessionEndWaitStartTime = DateTime.now();
      debugPrint('ChargingSessionService: 세션 종료 대기 시작');
      
      // 종료 대기 타이머 시작
      _startEndWaitTimer();
    }
  }
  
  /// 종료 대기 타이머 시작
  void _startEndWaitTimer() {
    _sessionEndWaitStartTime = DateTime.now();
    Timer(ChargingSessionConfig.sessionEndWaitDuration, () {
      if (_sessionState == SessionState.ending && _sessionEndWaitStartTime != null) {
        // 대기 시간이 지났으면 세션 종료
        final waitDuration = DateTime.now().difference(_sessionEndWaitStartTime!);
        debugPrint('ChargingSessionService: 종료 대기 완료 (${waitDuration.inSeconds}초 대기)');
        _endSession(); // Timer 콜백에서는 await 불가, unawaited로 처리
      }
    });
  }
  
  /// 세션 종료
  Future<void> _endSession() async {
    if (_sessionState == SessionState.idle) {
      return;
    }
    
    try {
      debugPrint('ChargingSessionService: 세션 종료 처리 시작');
      
      // 데이터 수집 타이머 중지
      _stopDataCollectionTimer();
      
      // 마지막 배터리 정보 가져오기
      final endBatteryInfo = _batteryService.currentBatteryInfo;
      if (endBatteryInfo == null || _startBatteryInfo == null) {
        debugPrint('ChargingSessionService: 배터리 정보가 없어 세션을 종료할 수 없습니다');
        _resetSession();
        return;
      }
      
      // 세션 데이터 분석 및 기록 생성
      final sessionRecord = await _createSessionRecord(endBatteryInfo);
      
      if (sessionRecord != null && sessionRecord.validate()) {
        // 유효한 세션이면 저장소에 저장
        final saved = await _storageService.saveSession(sessionRecord, saveToDatabase: true);
        if (saved) {
          _notifySessionsChanged();
          debugPrint('ChargingSessionService: 세션 저장 완료 - ${sessionRecord.sessionTitle}');
        } else {
          debugPrint('ChargingSessionService: 세션 저장 실패 - ${sessionRecord.sessionTitle}');
        }
      } else {
        debugPrint('ChargingSessionService: 세션이 유효하지 않아 저장하지 않습니다');
        if (sessionRecord != null) {
          debugPrint('ChargingSessionService: 세션 검증 실패 - duration: ${sessionRecord.duration.inMinutes}분, avgCurrent: ${sessionRecord.avgCurrent}mA, batteryChange: ${sessionRecord.batteryChange}%');
        }
      }
      
      // 세션 초기화
      _resetSession();
      
    } catch (e, stackTrace) {
      debugPrint('ChargingSessionService: 세션 종료 실패 - $e');
      debugPrint('스택 트레이스: $stackTrace');
      _resetSession();
    }
  }
  
  /// 세션 초기화
  void _resetSession() {
    _sessionState = SessionState.idle;
    _currentSession = null;
    _sessionStartTime = null;
    _sessionEndWaitStartTime = null;
    _collectedDataPoints.clear();
    _speedChanges.clear();
    _previousCurrent = null;
    _previousCurrentTime = null;
    _startBatteryInfo = null;
    _stopDataCollectionTimer();
  }
  
  // ==================== 충전 중 업데이트 처리 ====================
  
  /// 충전 중 업데이트 처리
  void _handleChargingUpdate(BatteryInfo batteryInfo) {
    if (_sessionState != SessionState.active) {
      return;
    }
    
    // 종료 대기 상태였다면 다시 활성 상태로
    if (_sessionState == SessionState.ending) {
      _sessionState = SessionState.active;
      _sessionEndWaitStartTime = null;
      debugPrint('ChargingSessionService: 세션이 다시 활성화됨');
    }
    
    // 전류 변화 감지
    _checkCurrentChange(batteryInfo);
    
    // 데이터 포인트 추가 (타이머가 자동으로 추가하지만, 전류 변화 시 즉시 추가)
    // 실제로는 타이머가 주기적으로 추가하므로 여기서는 전류 변화만 처리
  }
  
  // ==================== 데이터 수집 ====================
  
  /// 데이터 수집 타이머 시작
  void _startDataCollectionTimer() {
    _stopDataCollectionTimer();
    
    _dataCollectionTimer = Timer.periodic(
      ChargingSessionConfig.dataCollectionInterval,
      (timer) {
        if (_sessionState != SessionState.active || _isDisposed) {
          timer.cancel();
          _dataCollectionTimer = null;
          return;
        }
        
        final batteryInfo = _batteryService.currentBatteryInfo;
        if (batteryInfo != null && 
            batteryInfo.isCharging && 
            batteryInfo.chargingCurrent > 0) {
          _addDataPoint(batteryInfo);
        } else {
          // 충전이 종료되었으면 타이머 중지
          timer.cancel();
          _dataCollectionTimer = null;
        }
      },
    );
    
    debugPrint('ChargingSessionService: 데이터 수집 타이머 시작');
  }
  
  /// 데이터 수집 타이머 중지
  void _stopDataCollectionTimer() {
    _dataCollectionTimer?.cancel();
    _dataCollectionTimer = null;
  }
  
  /// 데이터 포인트 추가
  void _addDataPoint(BatteryInfo batteryInfo) {
    if (_sessionStartTime == null) {
      return;
    }
    
    final dataPoint = SessionDataPoint(
      timestamp: DateTime.now(),
      currentMa: batteryInfo.chargingCurrent,
      batteryLevel: batteryInfo.level,
      temperature: batteryInfo.temperature,
    );
    
    _collectedDataPoints.add(dataPoint);
    
    // 전류 변화 감지
    _checkCurrentChange(batteryInfo);
  }
  
  // ==================== 전류 변화 감지 ====================
  
  /// 전류 변화 감지
  void _checkCurrentChange(BatteryInfo batteryInfo) {
    final current = batteryInfo.chargingCurrent;
    final now = DateTime.now();
    
    if (_previousCurrent == null) {
      // 첫 전류값
      _previousCurrent = current;
      _previousCurrentTime = now;
      return;
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
        _speedChanges.add(changeEvent);
        debugPrint('ChargingSessionService: 전류 변화 감지 - ${changeEvent.description}');
      }
      
      _previousCurrent = current;
      _previousCurrentTime = now;
    }
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
      // 충전 속도 변화
      final prevSpeedType = ChargingSessionConfig.getChargingSpeedType(previousCurrent);
      final newSpeedType = ChargingSessionConfig.getChargingSpeedType(newCurrent);
      
      if (prevSpeedType != newSpeedType) {
        return CurrentChangeEvent(
          timestamp: timestamp,
          previousCurrent: previousCurrent,
          newCurrent: newCurrent,
          changeType: newSpeedType,
          description: '$prevSpeedType → $newSpeedType 전환 ⚡',
        );
      } else if (newCurrent > previousCurrent * 1.5) {
        // 같은 타입이지만 크게 증가
        return CurrentChangeEvent(
          timestamp: timestamp,
          previousCurrent: previousCurrent,
          newCurrent: newCurrent,
          changeType: newSpeedType,
          description: '$newSpeedType 증가 ($previousCurrent mA → $newCurrent mA)',
        );
      }
    }
    
    return null;
  }
  
  // ==================== 세션 기록 생성 ====================
  
  /// 세션 기록 생성
  Future<ChargingSessionRecord?> _createSessionRecord(BatteryInfo endBatteryInfo) async {
    if (_sessionStartTime == null || _startBatteryInfo == null) {
      return null;
    }
    
    if (_collectedDataPoints.isEmpty) {
      debugPrint('ChargingSessionService: 수집된 데이터가 없습니다');
      return null;
    }
    
    final endTime = DateTime.now();
    final duration = endTime.difference(_sessionStartTime!);
    
    // 데이터 분석
    final analysis = _analyzeSessionData();
    
    // 배터리 변화량 계산
    final batteryChange = endBatteryInfo.level - _startBatteryInfo!.level;
    
    // 유효성 검증
    if (!ChargingSessionConfig.isValidSession(
      duration: duration,
      avgCurrent: analysis.avgCurrent,
      batteryChange: batteryChange,
    )) {
      debugPrint('ChargingSessionService: 세션이 유효하지 않습니다');
      return null;
    }
    
    // 시간대 분류
    final timeSlot = TimeSlotUtils.getTimeSlot(_sessionStartTime!);
    
    // 세션 제목 생성 (오늘 세션 목록에서 가져오기)
    final todaySessions = await _storageService.getTodaySessions();
    final existingTitles = todaySessions
        .where((s) => TimeSlotUtils.getTimeSlot(s.startTime) == timeSlot)
        .map((s) => s.sessionTitle)
        .toList();
    final sessionTitle = TimeSlotUtils.generateSessionTitle(timeSlot, existingTitles);
    
    // 전류 변화 이력 분석 (PHASE 3의 ChargingSessionAnalyzer 사용)
    final speedChanges = charging_session_analyzer.ChargingSessionAnalyzer.analyzeCurrentChanges(
      _collectedDataPoints.map((p) => charging_session_analyzer.SessionDataPoint(
        timestamp: p.timestamp,
        currentMa: p.currentMa,
        batteryLevel: p.batteryLevel,
        temperature: p.temperature,
      )).toList(),
    );
    
    // 세션 기록 생성
    final sessionRecord = ChargingSessionRecord(
      id: _generateSessionId(),
      startTime: _sessionStartTime!,
      endTime: endTime,
      startBatteryLevel: _startBatteryInfo!.level,
      endBatteryLevel: endBatteryInfo.level,
      batteryChange: batteryChange,
      duration: duration,
      avgCurrent: analysis.avgCurrent,
      avgTemperature: analysis.avgTemperature,
      maxCurrent: analysis.maxCurrent,
      minCurrent: analysis.minCurrent,
      efficiency: analysis.efficiency, // PHASE 3의 ChargingSessionAnalyzer에서 계산된 효율 사용
      timeSlot: timeSlot,
      sessionTitle: sessionTitle,
      speedChanges: speedChanges.isNotEmpty ? speedChanges : List.unmodifiable(_speedChanges),
      icon: TimeSlotUtils.getTimeSlotIcon(timeSlot),
      color: TimeSlotUtils.getTimeSlotColor(timeSlot),
      batteryCapacity: endBatteryInfo.capacity > 0 ? endBatteryInfo.capacity : null,
      batteryVoltage: endBatteryInfo.voltage > 0 ? endBatteryInfo.voltage : null,
      isValid: true,
    );
    
    return sessionRecord;
  }
  
  /// 세션 데이터 분석
  /// PHASE 3의 ChargingSessionAnalyzer 사용
  charging_session_analyzer.SessionAnalysisResult _analyzeSessionData() {
    if (_collectedDataPoints.isEmpty || _startBatteryInfo == null) {
      return charging_session_analyzer.SessionAnalysisResult(
        avgCurrent: 0.0,
        avgTemperature: 0.0,
        maxCurrent: 0,
        minCurrent: 0,
        medianCurrent: 0,
        currentStdDev: 0.0,
        startBatteryLevel: _startBatteryInfo?.level ?? 0.0,
        endBatteryLevel: _startBatteryInfo?.level ?? 0.0,
        batteryChange: 0.0,
        duration: Duration.zero,
        efficiency: 0.0,
        efficiencyGrade: '낮음',
        currentStabilityScore: 0.0,
      );
    }
    
    // SessionDataPoint를 ChargingSessionAnalyzer의 SessionDataPoint로 변환
    final dataPoints = _collectedDataPoints.map((p) => charging_session_analyzer.SessionDataPoint(
      timestamp: p.timestamp,
      currentMa: p.currentMa,
      batteryLevel: p.batteryLevel,
      temperature: p.temperature,
    )).toList();
    
    // ChargingSessionAnalyzer 사용
    final endBatteryInfo = _batteryService.currentBatteryInfo ?? _startBatteryInfo!;
    final duration = _sessionStartTime != null
        ? DateTime.now().difference(_sessionStartTime!)
        : Duration.zero;
    
    return charging_session_analyzer.ChargingSessionAnalyzer.analyzeSession(
      dataPoints: dataPoints,
      startBatteryInfo: _startBatteryInfo!,
      endBatteryInfo: endBatteryInfo,
      duration: duration,
      batteryCapacity: endBatteryInfo.capacity > 0 ? endBatteryInfo.capacity : null,
      batteryVoltage: endBatteryInfo.voltage > 0 ? endBatteryInfo.voltage : null,
    );
  }
  
  
  /// 세션 ID 생성
  String _generateSessionId() {
    return 'session_${_sessionStartTime?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch}';
  }
  
  /// 세션 목록 변경 알림
  void _notifySessionsChanged() async {
    if (!_sessionsController.isClosed) {
      final sessions = getTodaySessions();
      _sessionsController.add(sessions);
    }
  }
  
  // ==================== 유틸리티 ====================
  
  /// 초기화 상태 확인
  bool get isInitialized => _isInitialized;
  
  /// 현재 세션 상태 확인
  SessionState get sessionState => _sessionState;
  
  /// 세션 진행 중인지 확인
  bool get isSessionActive => _sessionState == SessionState.active;
}

// ==================== 내부 데이터 클래스 ====================

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

/// 세션 분석 결과
/// PHASE 3에서 SessionAnalysisResult로 대체됨
/// 하위 호환성을 위해 유지하지만 사용하지 않음
@Deprecated('SessionAnalysisResult를 사용하세요')
class SessionAnalysis {
  final double avgCurrent;
  final double avgTemperature;
  final int maxCurrent;
  final int minCurrent;
  
  SessionAnalysis({
    required this.avgCurrent,
    required this.avgTemperature,
    required this.maxCurrent,
    required this.minCurrent,
  });
}

