import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:battery_plus/battery_plus.dart';
import '../models/models.dart';
import '../services/battery_service.dart';
import '../services/battery_history_database_service.dart';

/// 배터리 히스토리 관리 서비스
/// 배터리 데이터 수집, 저장, 분석을 담당하는 핵심 서비스
class BatteryHistoryService {
  static final BatteryHistoryService _instance = BatteryHistoryService._internal();
  factory BatteryHistoryService() => _instance;
  BatteryHistoryService._internal();

  final BatteryService _batteryService = BatteryService();
  final BatteryHistoryDatabaseService _databaseService = BatteryHistoryDatabaseService();
  
  StreamSubscription<BatteryInfo>? _batterySubscription;
  // 주기적 수집 타이머 제거됨 - 이벤트 기반으로 전환
  // Timer? _periodicCollectionTimer; // 더 이상 사용하지 않음
  
  bool _isCollecting = false;
  bool _isInitialized = false;
  
  // 데이터 수집 설정
  static const Duration _significantChangeThreshold = Duration(minutes: 2);
  
  // 마지막 수집된 데이터 포인트
  BatteryHistoryDataPoint? _lastDataPoint;
  DateTime? _lastCollectionTime;

  /// 서비스 초기화
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      debugPrint('배터리 히스토리 서비스 초기화 시작...');
      
      // 데이터베이스 서비스 초기화
      await _databaseService.initialize();
      
      // 배터리 서비스 초기화
      await _batteryService.startMonitoring();
      
      _isInitialized = true;
      debugPrint('배터리 히스토리 서비스 초기화 완료');
      
    } catch (e, stackTrace) {
      debugPrint('배터리 히스토리 서비스 초기화 실패: $e');
      debugPrint('스택 트레이스: $stackTrace');
      rethrow;
    }
  }

  /// 데이터 수집 시작
  Future<void> startDataCollection() async {
    if (_isCollecting) return;
    
    await initialize();
    
    try {
      debugPrint('배터리 데이터 수집 시작...');
      
      _isCollecting = true;
      
      // 배터리 상태 변화 감지 (이벤트 기반)
      _batterySubscription = _batteryService.batteryInfoStream.listen(
        _onBatteryStateChanged,
        onError: _onBatteryError,
      );
      
      // 주기적 데이터 수집 제거됨 - 이벤트 기반으로 전환
      
      // 초기 데이터 포인트 수집
      await _collectCurrentBatteryData();
      
      debugPrint('배터리 데이터 수집 시작 완료');
      
    } catch (e, stackTrace) {
      debugPrint('배터리 데이터 수집 시작 실패: $e');
      debugPrint('스택 트레이스: $stackTrace');
      _isCollecting = false;
      rethrow;
    }
  }

  /// 데이터 수집 중지
  Future<void> stopDataCollection() async {
    if (!_isCollecting) return;
    
    try {
      debugPrint('배터리 데이터 수집 중지...');
      
      _isCollecting = false;
      
      // 구독 해제
      await _batterySubscription?.cancel();
      _batterySubscription = null;
      
      // 주기적 수집 타이머 제거됨 (더 이상 사용하지 않음)
      
      debugPrint('배터리 데이터 수집 중지 완료');
      
    } catch (e, stackTrace) {
      debugPrint('배터리 데이터 수집 중지 실패: $e');
      debugPrint('스택 트레이스: $stackTrace');
    }
  }

  /// 배터리 상태 변화 감지 시 실행
  Future<void> _onBatteryStateChanged(BatteryInfo batteryInfo) async {
    if (!_isCollecting) return;
    
    try {
      // 의미있는 변화인지 확인
      if (_shouldCollectData(batteryInfo)) {
        await _collectBatteryDataPoint(batteryInfo, 'system_event');
      }
    } catch (e) {
      debugPrint('배터리 상태 변화 처리 실패: $e');
    }
  }

  /// 배터리 에러 처리
  void _onBatteryError(dynamic error) {
    debugPrint('배터리 서비스 에러: $error');
  }

  // 주기적 데이터 수집 제거됨 - batteryInfoStream 이벤트 기반으로 자동 수집됨

  /// 현재 배터리 데이터 수집
  Future<void> _collectCurrentBatteryData() async {
    try {
      final batteryInfo = _batteryService.currentBatteryInfo;
      if (batteryInfo != null) {
        await _collectBatteryDataPoint(batteryInfo, 'automatic');
      }
    } catch (e) {
      debugPrint('현재 배터리 데이터 수집 실패: $e');
    }
  }

  /// 배터리 데이터 포인트 수집
  Future<void> _collectBatteryDataPoint(
    BatteryInfo batteryInfo,
    String collectionMethod,
  ) async {
    try {
      final dataPoint = BatteryHistoryDataPoint.fromBatteryInfo(
        batteryInfo,
        isAppInForeground: true, // 앱이 포그라운드에 있다고 가정
        collectionMethod: collectionMethod,
      );
      
      // 데이터 품질 검증
      if (!_isValidDataPoint(dataPoint)) {
        debugPrint('유효하지 않은 데이터 포인트 무시: ${dataPoint.level}%');
        return;
      }
      
      // 데이터베이스에 저장
      await _databaseService.insertBatteryDataPoint(dataPoint);
      
      // 마지막 데이터 포인트 업데이트
      _lastDataPoint = dataPoint;
      _lastCollectionTime = DateTime.now();
      
      debugPrint('배터리 데이터 포인트 수집 완료: ${dataPoint.level.toStringAsFixed(1)}%');
      
    } catch (e, stackTrace) {
      debugPrint('배터리 데이터 포인트 수집 실패: $e');
      debugPrint('스택 트레이스: $stackTrace');
    }
  }

  /// 데이터 수집 필요 여부 판단
  bool _shouldCollectData(BatteryInfo batteryInfo) {
    if (_lastDataPoint == null) return true;
    
    final now = DateTime.now();
    final timeSinceLastCollection = _lastCollectionTime != null
        ? now.difference(_lastCollectionTime!)
        : Duration.zero;
    
    // 최소 수집 간격 확인
    if (timeSinceLastCollection < _significantChangeThreshold) {
      return false;
    }
    
    // 배터리 레벨 변화 확인
    final levelChange = (batteryInfo.level - _lastDataPoint!.level).abs();
    if (levelChange >= 1.0) return true; // 1% 이상 변화
    
    // 배터리 상태 변화 확인
    if (batteryInfo.state != _lastDataPoint!.state) return true;
    
    // 충전 상태 변화 확인
    if (batteryInfo.isCharging != _lastDataPoint!.isCharging) return true;
    
    return false;
  }

  /// 데이터 포인트 유효성 검증
  bool _isValidDataPoint(BatteryHistoryDataPoint dataPoint) {
    // 기본 유효성 검사
    if (!dataPoint.isValidLevel) return false;
    
    // 온도 유효성 검사 (측정 가능한 경우)
    if (dataPoint.hasTemperature && (dataPoint.temperature < -20 || dataPoint.temperature > 60)) {
      return false;
    }
    
    // 전압 유효성 검사 (측정 가능한 경우)
    if (dataPoint.hasVoltage && (dataPoint.voltage < 3000 || dataPoint.voltage > 5000)) {
      return false;
    }
    
    // 데이터 품질 검사
    if (!dataPoint.hasGoodQuality) return false;
    
    return true;
  }

  /// 특정 기간의 배터리 히스토리 데이터 조회
  Future<List<BatteryHistoryDataPoint>> getBatteryHistoryData({
    DateTime? startTime,
    DateTime? endTime,
    int? limit,
  }) async {
    await initialize();
    
    try {
      return await _databaseService.getBatteryHistoryData(
        startTime: startTime,
        endTime: endTime,
        limit: limit,
      );
    } catch (e, stackTrace) {
      debugPrint('배터리 히스토리 데이터 조회 실패: $e');
      debugPrint('스택 트레이스: $stackTrace');
      rethrow;
    }
  }

  /// 최근 N개의 배터리 히스토리 데이터 조회
  Future<List<BatteryHistoryDataPoint>> getRecentBatteryHistoryData(int count) async {
    await initialize();
    
    try {
      return await _databaseService.getRecentBatteryHistoryData(count);
    } catch (e, stackTrace) {
      debugPrint('최근 배터리 히스토리 데이터 조회 실패: $e');
      debugPrint('스택 트레이스: $stackTrace');
      rethrow;
    }
  }

  /// 배터리 통계 조회
  Future<Map<String, dynamic>> getBatteryStatistics({
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    await initialize();
    
    try {
      return await _databaseService.getBatteryStatistics(
        startTime: startTime,
        endTime: endTime,
      );
    } catch (e, stackTrace) {
      debugPrint('배터리 통계 조회 실패: $e');
      debugPrint('스택 트레이스: $stackTrace');
      rethrow;
    }
  }

  /// 배터리 히스토리 분석 수행
  Future<BatteryHistoryAnalysis> performBatteryAnalysis({
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    await initialize();
    
    try {
      // 분석 기간 설정 (기본값: 최근 24시간)
      final analysisEndTime = endTime ?? DateTime.now();
      final analysisStartTimeParam = startTime ?? analysisEndTime.subtract(const Duration(hours: 24));
      
      // 히스토리 데이터 조회
      final historyData = await getBatteryHistoryData(
        startTime: analysisStartTimeParam,
        endTime: analysisEndTime,
      );
      
      if (historyData.isEmpty) {
        throw Exception('분석할 데이터가 없습니다');
      }
      
      // 분석 수행
      final analysis = _performAnalysis(historyData, analysisStartTimeParam, analysisEndTime);
      
      debugPrint('배터리 히스토리 분석 완료: ${historyData.length}개 데이터 포인트');
      
      return analysis;
      
    } catch (e, stackTrace) {
      debugPrint('배터리 히스토리 분석 실패: $e');
      debugPrint('스택 트레이스: $stackTrace');
      rethrow;
    }
  }

  /// 실제 분석 로직 수행
  BatteryHistoryAnalysis _performAnalysis(
    List<BatteryHistoryDataPoint> historyData,
    DateTime startTime,
    DateTime endTime,
  ) {
    
    // 기본 통계 계산
    final levels = historyData.map((d) => d.level).toList();
    final avgLevel = levels.reduce((a, b) => a + b) / levels.length;
    final minLevel = levels.reduce((a, b) => a < b ? a : b);
    final maxLevel = levels.reduce((a, b) => a > b ? a : b);
    final batteryVariation = maxLevel - minLevel;
    
    // 방전/충전 속도 계산
    final dischargeRate = _calculateDischargeRate(historyData);
    final chargeRate = _calculateChargeRate(historyData);
    
    // 충전 세션 분석
    final chargingSessions = _analyzeChargingSessions(historyData);
    final avgChargingSessionMinutes = chargingSessions.isNotEmpty
        ? chargingSessions.map((s) => s['duration'].inMinutes).reduce((a, b) => a + b) / chargingSessions.length
        : 0.0;
    
    // 데이터 품질 계산
    final dataQualities = historyData.map((d) => d.dataQuality).toList();
    final overallDataQuality = dataQualities.reduce((a, b) => a + b) / dataQualities.length;
    
    // 인사이트 생성
    final insights = _generateInsights(historyData, avgLevel, minLevel, maxLevel, batteryVariation);
    
    // 최적화 제안 생성
    final recommendations = _generateRecommendations(historyData, avgLevel, minLevel, batteryVariation);
    
    // 패턴 분석
    final patternAnalysis = _analyzePatterns(historyData);
    
    // 충전 이벤트 생성
    final chargingEvents = _generateChargingEvents(historyData);
    
    // 방전 이벤트 생성
    final dischargingEvents = _generateDischargingEvents(historyData);
    
    // 패턴 요약 생성
    final patternSummary = _generatePatternSummary(patternAnalysis, avgLevel, batteryVariation);
    
    final analysisEndTime = DateTime.now();
    
    return BatteryHistoryAnalysis(
      analysisStartTime: analysisEndTime,
      analysisEndTime: analysisEndTime,
      dataPointCount: historyData.length,
      analysisDurationHours: endTime.difference(startTime).inHours.toDouble(),
      averageBatteryLevel: avgLevel,
      minBatteryLevel: minLevel,
      maxBatteryLevel: maxLevel,
      batteryVariation: batteryVariation,
      averageDischargeRate: dischargeRate,
      averageChargeRate: chargeRate,
      chargingSessions: chargingSessions.length,
      averageChargingSessionMinutes: avgChargingSessionMinutes,
      overallDataQuality: overallDataQuality,
      insights: insights,
      recommendations: recommendations,
      patternAnalysis: patternAnalysis,
      chargingEvents: chargingEvents,
      dischargingEvents: dischargingEvents,
      patternSummary: patternSummary,
    );
  }

  /// 방전 속도 계산 (%/시간)
  double _calculateDischargeRate(List<BatteryHistoryDataPoint> historyData) {
    final dischargingData = historyData.where((d) => d.state == BatteryState.discharging).toList();
    if (dischargingData.length < 2) return 0.0;
    
    double totalDischarge = 0.0;
    double totalTime = 0.0;
    
    for (int i = 1; i < dischargingData.length; i++) {
      final prev = dischargingData[i - 1];
      final curr = dischargingData[i];
      
      final levelChange = prev.level - curr.level;
      final timeChange = curr.timestamp.difference(prev.timestamp).inHours;
      
      if (levelChange > 0 && timeChange > 0) {
        totalDischarge += levelChange;
        totalTime += timeChange;
      }
    }
    
    return totalTime > 0 ? totalDischarge / totalTime : 0.0;
  }

  /// 충전 속도 계산 (%/시간)
  double _calculateChargeRate(List<BatteryHistoryDataPoint> historyData) {
    final chargingData = historyData.where((d) => d.state == BatteryState.charging).toList();
    if (chargingData.length < 2) return 0.0;
    
    double totalCharge = 0.0;
    double totalTime = 0.0;
    
    for (int i = 1; i < chargingData.length; i++) {
      final prev = chargingData[i - 1];
      final curr = chargingData[i];
      
      final levelChange = curr.level - prev.level;
      final timeChange = curr.timestamp.difference(prev.timestamp).inHours;
      
      if (levelChange > 0 && timeChange > 0) {
        totalCharge += levelChange;
        totalTime += timeChange;
      }
    }
    
    return totalTime > 0 ? totalCharge / totalTime : 0.0;
  }

  /// 충전 세션 분석
  List<Map<String, dynamic>> _analyzeChargingSessions(List<BatteryHistoryDataPoint> historyData) {
    final sessions = <Map<String, dynamic>>[];
    BatteryHistoryDataPoint? sessionStart;
    
    for (final dataPoint in historyData) {
      if (dataPoint.isCharging && sessionStart == null) {
        sessionStart = dataPoint;
      } else if (!dataPoint.isCharging && sessionStart != null) {
        sessions.add({
          'start': sessionStart.timestamp,
          'end': dataPoint.timestamp,
          'duration': dataPoint.timestamp.difference(sessionStart.timestamp),
          'startLevel': sessionStart.level,
          'endLevel': dataPoint.level,
          'chargeAmount': dataPoint.level - sessionStart.level,
        });
        sessionStart = null;
      }
    }
    
    return sessions;
  }

  /// 인사이트 생성
  List<String> _generateInsights(
    List<BatteryHistoryDataPoint> historyData,
    double avgLevel,
    double minLevel,
    double maxLevel,
    double batteryVariation,
  ) {
    final insights = <String>[];
    
    // 평균 배터리 레벨 인사이트
    if (avgLevel < 30) {
      insights.add('평균 배터리 레벨이 낮습니다 (${avgLevel.toStringAsFixed(1)}%). 충전 패턴을 개선해보세요.');
    } else if (avgLevel > 80) {
      insights.add('평균 배터리 레벨이 높습니다 (${avgLevel.toStringAsFixed(1)}%). 배터리 수명을 위해 80% 이하로 유지하는 것을 권장합니다.');
    }
    
    // 최소 배터리 레벨 인사이트
    if (minLevel < 20) {
      insights.add('배터리가 20% 이하로 떨어진 적이 있습니다. 저전력 모드 사용을 권장합니다.');
    }
    
    // 배터리 변동폭 인사이트
    if (batteryVariation > 80) {
      insights.add('배터리 변동폭이 큽니다 (${batteryVariation.toStringAsFixed(1)}%). 사용 패턴을 최적화하면 배터리 수명을 연장할 수 있습니다.');
    }
    
    // 데이터 품질 인사이트
    final goodQualityCount = historyData.where((d) => d.hasGoodQuality).length;
    final qualityPercentage = (goodQualityCount / historyData.length) * 100;
    if (qualityPercentage < 70) {
      insights.add('데이터 품질이 낮습니다 (${qualityPercentage.toStringAsFixed(1)}%). 앱을 더 자주 사용하면 더 정확한 분석이 가능합니다.');
    }
    
    return insights;
  }

  /// 최적화 제안 생성
  List<String> _generateRecommendations(
    List<BatteryHistoryDataPoint> historyData,
    double avgLevel,
    double minLevel,
    double batteryVariation,
  ) {
    final recommendations = <String>[];
    
    // 충전 패턴 분석
    final chargingSessions = _analyzeChargingSessions(historyData);
    if (chargingSessions.isNotEmpty) {
      final avgSessionDuration = chargingSessions.map((s) => s['duration'].inMinutes).reduce((a, b) => a + b) / chargingSessions.length;
      if (avgSessionDuration > 120) {
        recommendations.add('충전 세션이 길어 보입니다. 빠른 충전을 위해 고전력 충전기를 사용해보세요.');
      }
    }
    
    // 방전 속도 분석
    final dischargeRate = _calculateDischargeRate(historyData);
    if (dischargeRate > 3) {
      recommendations.add('배터리 방전 속도가 빠릅니다 (${dischargeRate.toStringAsFixed(1)}%/시간). 화면 밝기를 낮추고 백그라운드 앱을 정리해보세요.');
    }
    
    // 온도 분석
    final tempData = historyData.where((d) => d.hasTemperature).toList();
    if (tempData.isNotEmpty) {
      final avgTemp = tempData.map((d) => d.temperature).reduce((a, b) => a + b) / tempData.length;
      if (avgTemp > 35) {
        recommendations.add('배터리 온도가 높습니다 (${avgTemp.toStringAsFixed(1)}°C). 케이스를 제거하고 통풍이 잘 되는 곳에서 사용해보세요.');
      }
    }
    
    return recommendations;
  }

  /// 패턴 분석
  Map<String, dynamic> _analyzePatterns(List<BatteryHistoryDataPoint> historyData) {
    final patterns = <String, dynamic>{};
    
    // 시간대별 패턴 분석
    final hourlyPatterns = <int, List<double>>{};
    for (final dataPoint in historyData) {
      final hour = dataPoint.timestamp.hour;
      hourlyPatterns.putIfAbsent(hour, () => []).add(dataPoint.level);
    }
    
    patterns['hourlyPatterns'] = hourlyPatterns.map((hour, levels) => MapEntry(
      hour.toString(),
      {
        'avgLevel': levels.reduce((a, b) => a + b) / levels.length,
        'count': levels.length,
      },
    ));
    
    // 충전 패턴 분석
    final chargingPatterns = <String, int>{};
    for (final dataPoint in historyData.where((d) => d.isCharging)) {
      final hour = dataPoint.timestamp.hour;
      final timeSlot = hour < 6 ? 'night' : hour < 12 ? 'morning' : hour < 18 ? 'afternoon' : 'evening';
      chargingPatterns[timeSlot] = (chargingPatterns[timeSlot] ?? 0) + 1;
    }
    patterns['chargingPatterns'] = chargingPatterns;
    
    return patterns;
  }

  /// 데이터 정리
  Future<int> cleanupOldData({int? retentionDays}) async {
    await initialize();
    
    try {
      return await _databaseService.cleanupOldData(retentionDays: retentionDays);
    } catch (e, stackTrace) {
      debugPrint('데이터 정리 실패: $e');
      debugPrint('스택 트레이스: $stackTrace');
      rethrow;
    }
  }

  /// 데이터베이스 백업
  Future<String> backupDatabase() async {
    await initialize();
    
    try {
      return await _databaseService.backupDatabase();
    } catch (e, stackTrace) {
      debugPrint('데이터베이스 백업 실패: $e');
      debugPrint('스택 트레이스: $stackTrace');
      rethrow;
    }
  }

  /// 충전 이벤트 생성
  List<String> _generateChargingEvents(List<BatteryHistoryDataPoint> historyData) {
    final events = <String>[];
    final chargingData = historyData.where((d) => d.isCharging).toList();
    
    if (chargingData.isEmpty) {
      events.add('충전 이벤트가 없습니다');
      return events;
    }
    
    // 충전 시작 이벤트들
    for (int i = 0; i < chargingData.length - 1; i++) {
      final current = chargingData[i];
      final next = chargingData[i + 1];
      
      if (current.timestamp.difference(next.timestamp).inMinutes.abs() > 30) {
        events.add('${current.timestamp.hour}:${current.timestamp.minute.toString().padLeft(2, '0')} 충전 시작 (${current.level.toStringAsFixed(1)}%)');
      }
    }
    
    // 마지막 충전 이벤트
    final lastCharging = chargingData.last;
    events.add('${lastCharging.timestamp.hour}:${lastCharging.timestamp.minute.toString().padLeft(2, '0')} 충전 중 (${lastCharging.level.toStringAsFixed(1)}%)');
    
    return events.take(5).toList(); // 최대 5개 이벤트만 반환
  }

  /// 방전 이벤트 생성
  List<String> _generateDischargingEvents(List<BatteryHistoryDataPoint> historyData) {
    final events = <String>[];
    final dischargingData = historyData.where((d) => d.state == BatteryState.discharging).toList();
    
    if (dischargingData.isEmpty) {
      events.add('방전 이벤트가 없습니다');
      return events;
    }
    
    // 방전 속도가 빠른 구간들 찾기
    for (int i = 0; i < dischargingData.length - 1; i++) {
      final current = dischargingData[i];
      final next = dischargingData[i + 1];
      
      final timeDiff = next.timestamp.difference(current.timestamp).inMinutes;
      final levelDiff = current.level - next.level;
      
      if (timeDiff > 0 && levelDiff > 0) {
        final dischargeRate = levelDiff / (timeDiff / 60); // %/시간
        
        if (dischargeRate > 3.0) { // 시간당 3% 이상 방전
          events.add('${current.timestamp.hour}:${current.timestamp.minute.toString().padLeft(2, '0')} 빠른 방전 (${dischargeRate.toStringAsFixed(1)}%/시간)');
        }
      }
    }
    
    return events.take(5).toList(); // 최대 5개 이벤트만 반환
  }

  /// 패턴 요약 생성
  String _generatePatternSummary(Map<String, dynamic> patternAnalysis, double avgLevel, double batteryVariation) {
    final chargingPatterns = patternAnalysis['chargingPatterns'] as Map<String, int>?;
    
    String summary = '';
    
    // 평균 배터리 레벨 기반 요약
    if (avgLevel > 70) {
      summary += '배터리 사용 패턴이 양호합니다. ';
    } else if (avgLevel > 50) {
      summary += '배터리 사용 패턴이 보통입니다. ';
    } else {
      summary += '배터리 사용 패턴을 개선할 필요가 있습니다. ';
    }
    
    // 변동폭 기반 요약
    if (batteryVariation < 30) {
      summary += '배터리 레벨이 안정적입니다. ';
    } else if (batteryVariation < 50) {
      summary += '배터리 레벨 변동이 보통입니다. ';
    } else {
      summary += '배터리 레벨 변동이 큽니다. ';
    }
    
    // 충전 패턴 기반 요약
    if (chargingPatterns != null && chargingPatterns.isNotEmpty) {
      final maxChargingTime = chargingPatterns.entries.reduce((a, b) => a.value > b.value ? a : b);
      summary += '주로 ${maxChargingTime.key}에 충전하는 패턴을 보입니다.';
    }
    
    return summary.isEmpty ? '배터리 사용 패턴을 분석할 수 없습니다.' : summary;
  }

  /// 서비스 정리
  Future<void> dispose() async {
    await stopDataCollection();
    await _databaseService.close();
    debugPrint('배터리 히스토리 서비스 정리 완료');
  }
}
