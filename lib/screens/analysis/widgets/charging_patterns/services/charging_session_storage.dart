// 충전 세션 저장소 서비스
// 세션 데이터를 메모리 및 데이터베이스에 저장하고 관리하는 서비스

import 'dart:async';
import 'dart:convert'; // JSON 인코딩/디코딩용
import 'package:flutter/material.dart';
import '../../../../../services/battery_history_database_service.dart';
import '../models/charging_session_models.dart';
import '../config/charging_session_config.dart';

/// 충전 세션 저장소 서비스 (싱글톤)
/// 
/// 주요 기능:
/// 1. 메모리 저장 (오늘 세션만)
/// 2. 데이터베이스 저장
/// 3. 세션 데이터 조회
/// 4. 날짜별 세션 조회
/// 5. 데이터 동기화
class ChargingSessionStorage {
  // 싱글톤 인스턴스
  static final ChargingSessionStorage _instance = 
      ChargingSessionStorage._internal();
  factory ChargingSessionStorage() => _instance;
  ChargingSessionStorage._internal();

  final BatteryHistoryDatabaseService _databaseService = BatteryHistoryDatabaseService();
  
  // 서비스 상태 관리
  bool _isInitialized = false;
  bool _isDisposed = false;
  
  // ==================== 메모리 저장 ====================
  
  /// 오늘 날짜의 세션 목록 (메모리)
  /// 날짜 키: "YYYY-MM-DD" 형식
  final Map<String, List<ChargingSessionRecord>> _dailySessions = {};
  
  /// 오늘 날짜 키 가져오기
  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
  
  // ==================== 서비스 초기화 ====================
  
  /// 서비스 초기화
  Future<void> initialize() async {
    if (_isInitialized || _isDisposed) {
      debugPrint('ChargingSessionStorage: 이미 초기화되었거나 dispose됨');
      return;
    }
    
    try {
      debugPrint('ChargingSessionStorage: 초기화 시작...');
      
      // 데이터베이스 서비스 초기화
      await _databaseService.initialize();
      
      // 오늘 날짜의 세션 데이터 로드
      await _loadTodaySessions();
      
      // 오래된 메모리 데이터 정리 (7일 이전 데이터 제거)
      _cleanupOldMemoryData();
      
      _isInitialized = true;
      debugPrint('ChargingSessionStorage: 초기화 완료');
      
    } catch (e, stackTrace) {
      debugPrint('ChargingSessionStorage: 초기화 실패 - $e');
      debugPrint('스택 트레이스: $stackTrace');
      rethrow;
    }
  }
  
  /// 오래된 메모리 데이터 정리 (7일 이전 데이터 제거)
  void _cleanupOldMemoryData() {
    if (_isDisposed) return;
    
    try {
      final now = DateTime.now();
      final cutoffDate = now.subtract(Duration(days: ChargingSessionConfig.sessionRetentionDays));
      final cutoffDateKey = _getDateKey(cutoffDate);
      
      final keysToRemove = <String>[];
      for (final dateKey in _dailySessions.keys) {
        if (dateKey.compareTo(cutoffDateKey) < 0) {
          keysToRemove.add(dateKey);
        }
      }
      
      for (final key in keysToRemove) {
        _dailySessions.remove(key);
        debugPrint('ChargingSessionStorage: 오래된 메모리 데이터 제거 - $key');
      }
      
      if (keysToRemove.isNotEmpty) {
        debugPrint('ChargingSessionStorage: ${keysToRemove.length}개 날짜의 오래된 메모리 데이터 정리 완료');
      }
    } catch (e) {
      debugPrint('ChargingSessionStorage: 메모리 데이터 정리 실패 - $e');
    }
  }
  
  /// 서비스 정리
  void dispose() {
    if (_isDisposed) return;
    
    debugPrint('ChargingSessionStorage: dispose 시작...');
    
    _isDisposed = true;
    
    // 메모리 데이터 정리
    _dailySessions.clear();
    
    debugPrint('ChargingSessionStorage: dispose 완료');
  }
  
  // ==================== 세션 저장 ====================
  
  /// 세션 저장 (메모리 + DB)
  /// 
  /// [session] 저장할 세션 기록
  /// [saveToDatabase] DB에 저장할지 여부 (기본값: true)
  /// 
  /// 반환: 저장 성공 여부
  Future<bool> saveSession(
    ChargingSessionRecord session, {
    bool saveToDatabase = true,
  }) async {
    if (_isDisposed || !_isInitialized) {
      debugPrint('ChargingSessionStorage: 서비스가 초기화되지 않았거나 dispose됨');
      return false;
    }
    
    try {
      // 유효성 검증
      if (!session.validate()) {
        debugPrint('ChargingSessionStorage: 세션이 유효하지 않아 저장하지 않습니다');
        return false;
      }
      
      // 날짜 키 생성
      final dateKey = _getDateKey(session.startTime);
      
      // 메모리에 저장
      if (!_dailySessions.containsKey(dateKey)) {
        _dailySessions[dateKey] = [];
      }
      
      // 중복 체크 (같은 ID가 있으면 업데이트)
      final existingIndex = _dailySessions[dateKey]!
          .indexWhere((s) => s.id == session.id);
      
      if (existingIndex >= 0) {
        _dailySessions[dateKey]![existingIndex] = session;
        debugPrint('ChargingSessionStorage: 세션 업데이트 - ${session.id}');
      } else {
        _dailySessions[dateKey]!.add(session);
        debugPrint('ChargingSessionStorage: 세션 추가 - ${session.id}');
      }
      
      // DB에 저장
      if (saveToDatabase) {
        await _saveSessionToDatabase(session);
      }
      
      return true;
      
    } catch (e, stackTrace) {
      debugPrint('ChargingSessionStorage: 세션 저장 실패 - $e');
      debugPrint('스택 트레이스: $stackTrace');
      return false;
    }
  }
  
  /// 여러 세션 일괄 저장
  Future<int> saveSessions(
    List<ChargingSessionRecord> sessions, {
    bool saveToDatabase = true,
  }) async {
    if (_isDisposed || !_isInitialized) {
      return 0;
    }
    
    int savedCount = 0;
    for (final session in sessions) {
      final success = await saveSession(session, saveToDatabase: saveToDatabase);
      if (success) {
        savedCount++;
      }
    }
    
    debugPrint('ChargingSessionStorage: ${sessions.length}개 중 $savedCount개 세션 저장 완료');
    return savedCount;
  }
  
  // ==================== 세션 조회 ====================
  
  /// 오늘 날짜의 세션 목록 가져오기
  /// 메모리에서 가져오고, 없으면 DB에서 로드
  Future<List<ChargingSessionRecord>> getTodaySessions() async {
    if (_isDisposed || !_isInitialized) {
      return [];
    }
    
    try {
      final today = DateTime.now();
      final todayKey = _getDateKey(today);
      
      // 메모리에 있으면 반환
      if (_dailySessions.containsKey(todayKey)) {
        return List.unmodifiable(_dailySessions[todayKey]!);
      }
      
      // 메모리에 없으면 DB에서 로드
      await _loadTodaySessions();
      
      return List.unmodifiable(_dailySessions[todayKey] ?? []);
      
    } catch (e, stackTrace) {
      debugPrint('ChargingSessionStorage: 오늘 세션 조회 실패 - $e');
      debugPrint('스택 트레이스: $stackTrace');
      return [];
    }
  }
  
  /// 오늘 날짜의 세션 목록 가져오기 (동기 버전 - 메모리에서만)
  /// DB에서 로드하지 않고 메모리에 있는 데이터만 반환
  List<ChargingSessionRecord> getTodaySessionsSync() {
    if (_isDisposed || !_isInitialized) {
      return [];
    }
    
    try {
      final today = DateTime.now();
      final todayKey = _getDateKey(today);
      
      // 메모리에 있으면 반환
      if (_dailySessions.containsKey(todayKey)) {
        return List.unmodifiable(_dailySessions[todayKey]!);
      }
      
      // 메모리에 없으면 빈 리스트 반환 (비동기 로드는 호출자가 처리)
      return [];
      
    } catch (e) {
      debugPrint('ChargingSessionStorage: 오늘 세션 동기 조회 실패 - $e');
      return [];
    }
  }
  
  /// 특정 날짜의 세션 목록 가져오기
  /// 오늘이 아닌 경우 DB에서만 조회
  Future<List<ChargingSessionRecord>> getSessionsByDate(DateTime date) async {
    if (_isDisposed || !_isInitialized) {
      return [];
    }
    
    try {
      final dateKey = _getDateKey(date);
      final todayKey = _getDateKey(DateTime.now());
      
      // 오늘 날짜면 메모리에서 가져오기
      if (dateKey == todayKey) {
        return await getTodaySessions();
      }
      
      // 오늘이 아닌 경우 DB에서 조회
      return await _loadSessionsFromDatabase(date);
      
    } catch (e, stackTrace) {
      debugPrint('ChargingSessionStorage: 날짜별 세션 조회 실패 - $e');
      debugPrint('스택 트레이스: $stackTrace');
      return [];
    }
  }
  
  /// 특정 기간의 세션 목록 가져오기
  Future<List<ChargingSessionRecord>> getSessionsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (_isDisposed || !_isInitialized) {
      return [];
    }
    
    try {
      final allSessions = <ChargingSessionRecord>[];
      
      // 각 날짜별로 조회
      final currentDate = DateTime(startDate.year, startDate.month, startDate.day);
      final end = DateTime(endDate.year, endDate.month, endDate.day);
      
      var date = currentDate;
      while (date.isBefore(end) || date.isAtSameMomentAs(end)) {
        final sessions = await getSessionsByDate(date);
        allSessions.addAll(sessions);
        
        date = date.add(const Duration(days: 1));
      }
      
      // 시작 시간 순으로 정렬
      allSessions.sort((a, b) => a.startTime.compareTo(b.startTime));
      
      return allSessions;
      
    } catch (e, stackTrace) {
      debugPrint('ChargingSessionStorage: 기간별 세션 조회 실패 - $e');
      debugPrint('스택 트레이스: $stackTrace');
      return [];
    }
  }
  
  /// 세션 ID로 세션 가져오기
  Future<ChargingSessionRecord?> getSessionById(String sessionId) async {
    if (_isDisposed || !_isInitialized) {
      return null;
    }
    
    try {
      // 먼저 메모리에서 찾기
      for (final sessions in _dailySessions.values) {
        final session = sessions.firstWhere(
          (s) => s.id == sessionId,
          orElse: () => throw StateError('Session not found'),
        );
        if (session.id == sessionId) {
          return session;
        }
      }
      
      // 메모리에 없으면 DB에서 조회
      return await _loadSessionFromDatabase(sessionId);
      
    } catch (e) {
      debugPrint('ChargingSessionStorage: 세션 조회 실패 - $e');
      return null;
    }
  }
  
  // ==================== 데이터베이스 저장 ====================
  
  /// 세션을 데이터베이스에 저장
  Future<void> _saveSessionToDatabase(ChargingSessionRecord session) async {
    if (_isDisposed || !_isInitialized) {
      return;
    }
    
    try {
      await _databaseService.initialize();
      
      // 세션 데이터를 Map으로 변환
      final sessionMap = _sessionToMap(session);
      
      // DB에 저장 (충전 세션 테이블에 저장)
      await _databaseService.insertChargingSession(sessionMap);
      
      debugPrint('ChargingSessionStorage: 세션 DB 저장 완료 - ${session.id}');
      
    } catch (e, stackTrace) {
      debugPrint('ChargingSessionStorage: 세션 DB 저장 실패 - $e');
      debugPrint('스택 트레이스: $stackTrace');
      // DB 저장 실패해도 메모리는 유지
    }
  }
  
  /// 여러 세션을 데이터베이스에 일괄 저장
  Future<void> _saveSessionsToDatabase(List<ChargingSessionRecord> sessions) async {
    if (_isDisposed || !_isInitialized || sessions.isEmpty) {
      return;
    }
    
    try {
      await _databaseService.initialize();
      
      // 세션 데이터를 Map 리스트로 변환
      final sessionMaps = sessions.map((s) => _sessionToMap(s)).toList();
      
      // DB에 일괄 저장
      await _databaseService.insertChargingSessions(sessionMaps);
      
      debugPrint('ChargingSessionStorage: ${sessions.length}개 세션 DB 일괄 저장 완료');
      
    } catch (e, stackTrace) {
      debugPrint('ChargingSessionStorage: 세션 DB 일괄 저장 실패 - $e');
      debugPrint('스택 트레이스: $stackTrace');
    }
  }
  
  // ==================== 데이터베이스 조회 ====================
  
  /// 오늘 날짜의 세션을 DB에서 로드하여 메모리에 저장
  Future<void> _loadTodaySessions() async {
    if (_isDisposed || !_isInitialized) {
      return;
    }
    
    try {
      final today = DateTime.now();
      final todayKey = _getDateKey(today);
      
      // 이미 메모리에 있으면 스킵
      if (_dailySessions.containsKey(todayKey) && 
          _dailySessions[todayKey]!.isNotEmpty) {
        return;
      }
      
      // DB에서 오늘 세션 로드
      final sessions = await _loadSessionsFromDatabase(today);
      
      // 메모리에 저장
      _dailySessions[todayKey] = sessions;
      
      debugPrint('ChargingSessionStorage: 오늘 세션 ${sessions.length}개 DB에서 로드 완료');
      
    } catch (e, stackTrace) {
      debugPrint('ChargingSessionStorage: 오늘 세션 로드 실패 - $e');
      debugPrint('스택 트레이스: $stackTrace');
    }
  }
  
  /// 특정 날짜의 세션을 DB에서 로드
  Future<List<ChargingSessionRecord>> _loadSessionsFromDatabase(DateTime date) async {
    if (_isDisposed || !_isInitialized) {
      return [];
    }
    
    try {
      await _databaseService.initialize();
      
      // DB에서 세션 조회
      final sessionMaps = await _databaseService.getChargingSessionsByDate(date);
      
      // ChargingSessionRecord로 변환
      final sessions = sessionMaps
          .map((map) => _mapToSession(map))
          .where((session) => session != null)
          .cast<ChargingSessionRecord>()
          .toList();
      
      debugPrint('ChargingSessionStorage: ${date.toString().split(' ')[0]} 날짜 세션 ${sessions.length}개 DB에서 로드 완료');
      
      return sessions;
      
    } catch (e, stackTrace) {
      debugPrint('ChargingSessionStorage: 날짜별 세션 로드 실패 - $e');
      debugPrint('스택 트레이스: $stackTrace');
      return [];
    }
  }
  
  /// 세션 ID로 DB에서 세션 로드
  Future<ChargingSessionRecord?> _loadSessionFromDatabase(String sessionId) async {
    if (_isDisposed || !_isInitialized) {
      return null;
    }
    
    try {
      await _databaseService.initialize();
      
      // DB에서 세션 조회
      final sessionMap = await _databaseService.getChargingSessionById(sessionId);
      
      if (sessionMap == null) {
        return null;
      }
      
      // ChargingSessionRecord로 변환
      return _mapToSession(sessionMap);
      
    } catch (e, stackTrace) {
      debugPrint('ChargingSessionStorage: 세션 ID로 조회 실패 - $e');
      debugPrint('스택 트레이스: $stackTrace');
      return null;
    }
  }
  
  // ==================== 데이터 동기화 ====================
  
  /// 특정 날짜의 세션을 DB에 저장 (날짜 변경 시 호출)
  /// 
  /// [date] 저장할 날짜
  /// 
  /// 반환: 저장된 세션 수
  Future<int> saveDateSessionsToDatabase(DateTime date) async {
    if (_isDisposed || !_isInitialized) {
      return 0;
    }
    
    try {
      final dateKey = _getDateKey(date);
      final sessions = _dailySessions[dateKey] ?? [];
      
      if (sessions.isEmpty) {
        return 0;
      }
      
      // DB에 저장
      await _saveSessionsToDatabase(sessions);
      
      debugPrint('ChargingSessionStorage: $dateKey 날짜 세션 ${sessions.length}개 DB 저장 완료');
      
      return sessions.length;
      
    } catch (e, stackTrace) {
      debugPrint('ChargingSessionStorage: 날짜별 세션 DB 저장 실패 - $e');
      debugPrint('스택 트레이스: $stackTrace');
      return 0;
    }
  }
  
  /// 모든 과거 날짜의 세션을 DB에 저장 (7일 전까지)
  /// 
  /// [todayKey] 오늘 날짜 키
  /// 
  /// 반환: 저장된 세션 수
  Future<int> saveAllPastSessionsToDatabase(String todayKey) async {
    if (_isDisposed || !_isInitialized) {
      return 0;
    }
    
    try {
      final now = DateTime.now();
      final cutoffDate = now.subtract(const Duration(days: 7)); // 7일 전
      final cutoffDateKey = _getDateKey(cutoffDate);
      
      int totalSaved = 0;
      
      // 저장할 날짜 목록 (오늘 제외, 7일 전 이후만)
      final datesToSave = <String>[];
      for (final dateKey in _dailySessions.keys) {
        // 오늘 데이터는 제외
        if (dateKey == todayKey) continue;
        
        // 7일 이전 데이터는 저장하지 않음
        if (dateKey.compareTo(cutoffDateKey) < 0) {
          // 7일 이전 데이터는 메모리에서만 제거
          _dailySessions.remove(dateKey);
          debugPrint('ChargingSessionStorage: 7일 이전 세션 데이터 메모리에서 제거 ($dateKey)');
          continue;
        }
        
        datesToSave.add(dateKey);
      }
      
      // 각 날짜의 세션을 DB에 저장
      for (final dateKey in datesToSave) {
        final sessions = _dailySessions[dateKey] ?? [];
        if (sessions.isNotEmpty) {
          await _saveSessionsToDatabase(sessions);
          totalSaved += sessions.length;
        }
      }
      
      if (totalSaved > 0) {
        debugPrint('ChargingSessionStorage: ${datesToSave.length}개 날짜 세션 $totalSaved개 DB 저장 완료');
      }
      
      return totalSaved;
      
    } catch (e, stackTrace) {
      debugPrint('ChargingSessionStorage: 과거 세션 DB 저장 실패 - $e');
      debugPrint('스택 트레이스: $stackTrace');
      return 0;
    }
  }
  
  // ==================== 데이터 변환 ====================
  
  /// ChargingSessionRecord를 Map으로 변환 (DB 저장용)
  Map<String, dynamic> _sessionToMap(ChargingSessionRecord session) {
    try {
      // speed_changes를 JSON 문자열로 변환
      final speedChangesJson = session.speedChanges.map((e) => e.toJson()).toList();
      
      return {
        'id': session.id,
        'start_time': session.startTime.millisecondsSinceEpoch,
        'end_time': session.endTime.millisecondsSinceEpoch,
        'start_battery_level': session.startBatteryLevel,
        'end_battery_level': session.endBatteryLevel,
        'battery_change': session.batteryChange,
        'duration_ms': session.duration.inMilliseconds,
        'avg_current': session.avgCurrent,
        'avg_temperature': session.avgTemperature,
        'max_current': session.maxCurrent,
        'min_current': session.minCurrent,
        'efficiency': session.efficiency,
        'time_slot': session.timeSlot.name,
        'session_title': session.sessionTitle,
        'speed_changes': speedChangesJson, // List<Map> 형태로 전달 (DB 서비스에서 JSON 변환)
        'icon': session.icon,
        'color': session.color.toARGB32(),
        'battery_capacity': session.batteryCapacity,
        'battery_voltage': session.batteryVoltage,
        'is_valid': session.isValid ? 1 : 0,
      };
    } catch (e, stackTrace) {
      debugPrint('ChargingSessionStorage: 세션 Map 변환 실패 - $e');
      debugPrint('스택 트레이스: $stackTrace');
      rethrow;
    }
  }
  
  /// Map을 ChargingSessionRecord로 변환 (DB 조회용)
  ChargingSessionRecord? _mapToSession(Map<String, dynamic> map) {
    try {
      // speed_changes 파싱 (JSON 문자열 또는 List)
      List<CurrentChangeEvent> speedChanges = [];
      try {
        final speedChangesData = map['speed_changes'];
        if (speedChangesData is String) {
          // JSON 문자열인 경우
          final decoded = jsonDecode(speedChangesData) as List<dynamic>;
          speedChanges = decoded
              .map((e) => CurrentChangeEvent.fromJson(e as Map<String, dynamic>))
              .toList();
        } else if (speedChangesData is List) {
          // 이미 List인 경우
          speedChanges = speedChangesData
              .map((e) => CurrentChangeEvent.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      } catch (e) {
        debugPrint('ChargingSessionStorage: speed_changes 파싱 실패 - $e');
        speedChanges = []; // 파싱 실패 시 빈 리스트
      }
      
      return ChargingSessionRecord(
        id: map['id'] as String,
        startTime: DateTime.fromMillisecondsSinceEpoch(map['start_time'] as int),
        endTime: DateTime.fromMillisecondsSinceEpoch(map['end_time'] as int),
        startBatteryLevel: (map['start_battery_level'] as num).toDouble(),
        endBatteryLevel: (map['end_battery_level'] as num).toDouble(),
        batteryChange: (map['battery_change'] as num).toDouble(),
        duration: Duration(milliseconds: map['duration_ms'] as int),
        avgCurrent: (map['avg_current'] as num).toDouble(),
        avgTemperature: (map['avg_temperature'] as num).toDouble(),
        maxCurrent: map['max_current'] as int,
        minCurrent: map['min_current'] as int,
        efficiency: (map['efficiency'] as num).toDouble(),
        timeSlot: TimeSlot.values.firstWhere(
          (e) => e.name == map['time_slot'],
          orElse: () => TimeSlot.morning,
        ),
        sessionTitle: map['session_title'] as String,
        speedChanges: speedChanges,
        icon: map['icon'] as String,
        color: Color(map['color'] as int),
        batteryCapacity: map['battery_capacity'] as int?,
        batteryVoltage: map['battery_voltage'] as int?,
        isValid: (map['is_valid'] as int) == 1,
      );
    } catch (e, stackTrace) {
      debugPrint('ChargingSessionStorage: 세션 변환 실패 - $e');
      debugPrint('스택 트레이스: $stackTrace');
      return null;
    }
  }
  
  // ==================== 유틸리티 ====================
  
  /// 초기화 상태 확인
  bool get isInitialized => _isInitialized;
  
  /// 오늘 세션 개수
  int get todaySessionCount {
    final todayKey = _getDateKey(DateTime.now());
    return _dailySessions[todayKey]?.length ?? 0;
  }
  
  /// 메모리에 저장된 날짜 목록
  List<String> getStoredDateKeys() {
    return List.unmodifiable(_dailySessions.keys);
  }

  /// 저장소 상태 검증 (디버깅 및 통합 테스트용)
  Map<String, dynamic> getStorageStatus() {
    final todayKey = _getDateKey(DateTime.now());
    return {
      'isInitialized': _isInitialized,
      'isDisposed': _isDisposed,
      'storedDateCount': _dailySessions.length,
      'storedDateKeys': List.unmodifiable(_dailySessions.keys),
      'todaySessionCount': _dailySessions[todayKey]?.length ?? 0,
      'totalSessionsInMemory': _dailySessions.values.fold<int>(
        0,
        (sum, sessions) => sum + sessions.length,
      ),
    };
  }
}

