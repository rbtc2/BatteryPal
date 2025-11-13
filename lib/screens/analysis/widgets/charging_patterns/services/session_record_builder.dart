// 세션 기록 생성 서비스
// 수집된 데이터를 기반으로 충전 세션 기록을 생성하는 서비스

import 'package:flutter/foundation.dart';
import '../../../../../models/models.dart';
import '../models/charging_session_models.dart';
import '../config/charging_session_config.dart';
import '../utils/time_slot_utils.dart';
import 'charging_session_analyzer.dart' as charging_session_analyzer;
import 'session_data_collector.dart';
import 'charging_session_storage.dart';

/// 세션 기록 빌더
/// 
/// 주요 기능:
/// 1. 세션 데이터 분석
/// 2. 세션 기록 생성
/// 3. 세션 유효성 검증
/// 4. 시간대 분류 및 제목 생성
class SessionRecordBuilder {
  final ChargingSessionStorage _storageService;
  
  /// 생성자
  SessionRecordBuilder({
    ChargingSessionStorage? storageService,
  }) : _storageService = storageService ?? ChargingSessionStorage();
  
  // ==================== 세션 기록 생성 ====================
  
  /// 세션 기록 생성
  /// 
  /// [dataCollector] 데이터 수집기
  /// [startTime] 세션 시작 시간
  /// [startBatteryInfo] 세션 시작 시 배터리 정보
  /// [endBatteryInfo] 세션 종료 시 배터리 정보
  /// 
  /// 반환: 생성된 세션 기록, 유효하지 않으면 null
  Future<ChargingSessionRecord?> buildSessionRecord({
    required SessionDataCollector dataCollector,
    required DateTime startTime,
    required BatteryInfo startBatteryInfo,
    required BatteryInfo endBatteryInfo,
  }) async {
    if (dataCollector.isEmpty) {
      debugPrint('SessionRecordBuilder: 수집된 데이터가 없습니다');
      return null;
    }
    
    final endTime = DateTime.now();
    final duration = endTime.difference(startTime);
    
    // 데이터 분석
    final analysis = _analyzeSessionData(
      dataCollector: dataCollector,
      startTime: startTime,
      startBatteryInfo: startBatteryInfo,
      endBatteryInfo: endBatteryInfo,
    );
    
    // 배터리 변화량 계산
    final batteryChange = endBatteryInfo.level - startBatteryInfo.level;
    
    // 유효성 검증
    if (!ChargingSessionConfig.isValidSession(
      duration: duration,
      avgCurrent: analysis.avgCurrent,
      batteryChange: batteryChange,
    )) {
      debugPrint('SessionRecordBuilder: 세션이 유효하지 않습니다');
      return null;
    }
    
    // 시간대 분류
    final timeSlot = TimeSlotUtils.getTimeSlot(startTime);
    
    // 세션 제목 생성 (오늘 세션 목록에서 가져오기)
    final todaySessions = await _storageService.getTodaySessions();
    final existingTitles = todaySessions
        .where((s) => TimeSlotUtils.getTimeSlot(s.startTime) == timeSlot)
        .map((s) => s.sessionTitle)
        .toList();
    final sessionTitle = TimeSlotUtils.generateSessionTitle(timeSlot, existingTitles);
    
    // 전류 변화 이력 분석 (PHASE 3의 ChargingSessionAnalyzer 사용)
    final collectedDataPoints = dataCollector.getDataPoints();
    final speedChanges = charging_session_analyzer.ChargingSessionAnalyzer.analyzeCurrentChanges(
      collectedDataPoints.map((p) => charging_session_analyzer.SessionDataPoint(
        timestamp: p.timestamp,
        currentMa: p.currentMa,
        batteryLevel: p.batteryLevel,
        temperature: p.temperature,
      )).toList(),
    );
    
    // 세션 ID 생성
    final sessionId = _generateSessionId(startTime);
    
    // 세션 기록 생성
    final sessionRecord = ChargingSessionRecord(
      id: sessionId,
      startTime: startTime,
      endTime: endTime,
      startBatteryLevel: startBatteryInfo.level,
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
      speedChanges: speedChanges.isNotEmpty ? speedChanges : List.unmodifiable(dataCollector.getChangeEvents()),
      icon: TimeSlotUtils.getTimeSlotIcon(timeSlot),
      color: TimeSlotUtils.getTimeSlotColor(timeSlot),
      batteryCapacity: endBatteryInfo.capacity > 0 ? endBatteryInfo.capacity : null,
      batteryVoltage: endBatteryInfo.voltage > 0 ? endBatteryInfo.voltage : null,
      isValid: true,
    );
    
    return sessionRecord;
  }
  
  // ==================== 세션 데이터 분석 ====================
  
  /// 세션 데이터 분석
  /// PHASE 3의 ChargingSessionAnalyzer 사용
  charging_session_analyzer.SessionAnalysisResult _analyzeSessionData({
    required SessionDataCollector dataCollector,
    required DateTime startTime,
    required BatteryInfo startBatteryInfo,
    required BatteryInfo endBatteryInfo,
  }) {
    if (dataCollector.isEmpty) {
      return charging_session_analyzer.SessionAnalysisResult(
        avgCurrent: 0.0,
        avgTemperature: 0.0,
        maxCurrent: 0,
        minCurrent: 0,
        medianCurrent: 0,
        currentStdDev: 0.0,
        startBatteryLevel: startBatteryInfo.level,
        endBatteryLevel: startBatteryInfo.level,
        batteryChange: 0.0,
        duration: Duration.zero,
        efficiency: 0.0,
        efficiencyGrade: '낮음',
        currentStabilityScore: 0.0,
      );
    }
    
    // SessionDataPoint를 ChargingSessionAnalyzer의 SessionDataPoint로 변환
    final dataPoints = dataCollector.getDataPoints();
    final analyzerDataPoints = dataPoints.map((p) => charging_session_analyzer.SessionDataPoint(
      timestamp: p.timestamp,
      currentMa: p.currentMa,
      batteryLevel: p.batteryLevel,
      temperature: p.temperature,
    )).toList();
    
    // ChargingSessionAnalyzer 사용
    final duration = DateTime.now().difference(startTime);
    
    return charging_session_analyzer.ChargingSessionAnalyzer.analyzeSession(
      dataPoints: analyzerDataPoints,
      startBatteryInfo: startBatteryInfo,
      endBatteryInfo: endBatteryInfo,
      duration: duration,
      batteryCapacity: endBatteryInfo.capacity > 0 ? endBatteryInfo.capacity : null,
      batteryVoltage: endBatteryInfo.voltage > 0 ? endBatteryInfo.voltage : null,
    );
  }
  
  // ==================== 유틸리티 ====================
  
  /// 세션 ID 생성
  String _generateSessionId(DateTime startTime) {
    return 'session_${startTime.millisecondsSinceEpoch}';
  }
}

