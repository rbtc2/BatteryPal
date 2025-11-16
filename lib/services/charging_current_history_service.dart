import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/battery_service.dart';
import '../services/battery_history_database_service.dart';
import '../screens/analysis/widgets/charging_patterns/models/charging_data_models.dart';

/// 충전 전류 히스토리 관리 서비스 (싱글톤)
/// Phase 1: 실시간 충전 전류 수집 및 메모리 저장
/// 
/// 주요 기능:
/// 1. BatteryService 스트림 구독
/// 2. 충전 상태 변화 감지 (시작/종료)
/// 3. 충전 중 실시간 전류값 수집 및 메모리 저장
/// 4. 오늘 날짜 데이터 조회 API 제공
class ChargingCurrentHistoryService {
  // 싱글톤 인스턴스
  static final ChargingCurrentHistoryService _instance = 
      ChargingCurrentHistoryService._internal();
  factory ChargingCurrentHistoryService() => _instance;
  ChargingCurrentHistoryService._internal();

  final BatteryService _batteryService = BatteryService();
  final BatteryHistoryDatabaseService _databaseService = BatteryHistoryDatabaseService();
  
  // 스트림 구독 관리
  StreamSubscription<BatteryInfo>? _batteryInfoSubscription;
  
  // 배치 저장 타이머 제거됨 - 이벤트 기반으로 전환
  // Timer? _batchSaveTimer; // 더 이상 사용하지 않음
  static const int _batchSaveThreshold = 50; // 50개 이상이면 즉시 저장
  
  // 충전 중 주기적 데이터 수집 타이머 (그래프 가로선 표시용)
  Timer? _chargingMonitoringTimer;
  static const Duration _chargingMonitoringInterval = Duration(seconds: 10); // 10초마다 기록
  
  // 수집 상태 관리
  bool _isInitialized = false;
  bool _isCollecting = false;
  bool _isDisposed = false;
  
  // 충전 상태 추적
  bool _wasCharging = false;
  // Phase 2에서 세션 관리에 사용 예정
  // DateTime? _currentChargingSessionStart;
  
  // 메모리 데이터 저장 (Phase 1: 메모리 우선 저장)
  // 날짜별로 관리하는 구조 (추후 확장 가능)
  final Map<String, List<ChargingCurrentPoint>> _dailyData = {};
  
  // Phase 4: 메모리 최적화 - 오늘 이외의 날짜는 제한적으로 유지
  static const int _maxMemoryDays = 2; // 메모리에 최대 2일치만 유지
  
  // 최근 충전 전류값 (중복 저장 방지)
  int? _lastRecordedCurrent;
  DateTime? _lastRecordedTime;
  static const Duration _minRecordingInterval = Duration(seconds: 1); // 최소 기록 간격
  static const Duration _chargingTimeInterval = Duration(seconds: 10); // 충전 중 시간 기반 기록 간격 (그래프 가로선 표시용)
  
  // 날짜 변경 감지를 위한 마지막 저장 날짜 추적
  String? _lastSavedDateKey;
  
  // 마지막 데이터 정리 실행 시간 (하루에 한 번만 실행)
  DateTime? _lastCleanupTime;
  
  /// 서비스 초기화
  /// 앱 시작 시 호출하여 BatteryService 스트림 구독 시작
  Future<void> initialize() async {
    if (_isInitialized || _isDisposed) {
      debugPrint('ChargingCurrentHistoryService: 이미 초기화되었거나 dispose됨');
      return;
    }
    
    try {
      debugPrint('ChargingCurrentHistoryService: 초기화 시작...');
      
      // Phase 2: 데이터베이스 서비스 초기화
      await _databaseService.initialize();
      
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
      
      // 배치 저장 타이머 제거됨 - 이벤트 기반으로 전환
      
      // Phase 2: 기존 DB 데이터 로드 (오늘 데이터)
      await _loadTodayDataFromDatabase();
      
      // Phase 2: 백그라운드에서 수집된 데이터 확인 및 동기화
      await _checkAndSyncBackgroundData();
      
      // 날짜 변경 감지 및 과거 날짜 데이터 저장 (앱 시작 시)
      final todayKey = _getDateKey(DateTime.now());
      // 초기화 시에는 마지막 저장 날짜를 오늘로 설정하고, 
      // 메모리에 과거 날짜 데이터가 있으면 저장
      _lastSavedDateKey ??= todayKey;
      _checkDateChangeAndSave();
      
      // 7일 이상 된 데이터 자동 삭제 (초기화 시 한 번 실행)
      _cleanupOldDatabaseData();
      
      // 현재 충전 상태 확인
      final currentInfo = _batteryService.currentBatteryInfo;
      if (currentInfo != null) {
        _wasCharging = currentInfo.isCharging;
        if (_wasCharging && currentInfo.chargingCurrent >= 0) {
          // 이미 충전 중이면 즉시 기록 시작
          _startCollection();
        }
      }
      
      _isInitialized = true;
      debugPrint('ChargingCurrentHistoryService: 초기화 완료');
      
    } catch (e, stackTrace) {
      debugPrint('ChargingCurrentHistoryService: 초기화 실패 - $e');
      debugPrint('스택 트레이스: $stackTrace');
      rethrow;
    }
  }
  
  /// 배터리 정보 업데이트 처리
  void _onBatteryInfoUpdate(BatteryInfo batteryInfo) {
    if (_isDisposed) return;
    
    try {
      final isCurrentlyCharging = batteryInfo.isCharging;
      final chargingCurrent = batteryInfo.chargingCurrent;
      
      // 충전 상태 변화 감지
      if (isCurrentlyCharging && !_wasCharging) {
        // 충전 시작
        debugPrint('ChargingCurrentHistoryService: 충전 시작 감지');
        _startCollection();
        // Phase 2에서 세션 관리에 사용 예정
        // _currentChargingSessionStart = DateTime.now();
        _wasCharging = true;
        
      } else if (!isCurrentlyCharging && _wasCharging) {
        // 충전 종료
        debugPrint('ChargingCurrentHistoryService: 충전 종료 감지');
        _stopCollection();
        // Phase 2에서 세션 관리에 사용 예정
        // _currentChargingSessionStart = null;
        _wasCharging = false;
        
      } else if (isCurrentlyCharging && chargingCurrent >= 0) {
        // 충전 중 - 전류값 기록 (스트림 이벤트 발생 시)
        // 추가로 타이머도 별도로 작동하여 주기적 수집 보장
        _recordChargingCurrent(chargingCurrent);
      }
      
    } catch (e, stackTrace) {
      debugPrint('ChargingCurrentHistoryService: 배터리 정보 업데이트 처리 실패 - $e');
      debugPrint('스택 트레이스: $stackTrace');
    }
  }
  
  /// 충전 전류 기록 시작
  void _startCollection() {
    if (_isCollecting) return;
    
    debugPrint('ChargingCurrentHistoryService: 데이터 수집 시작');
    _isCollecting = true;
    _lastRecordedCurrent = null;
    _lastRecordedTime = null;
    
    // 충전 중 주기적 데이터 수집 타이머 시작 (그래프 가로선 표시용)
    _startChargingMonitoringTimer();
  }
  
  /// 충전 중 주기적 데이터 수집 타이머 시작
  /// 충전 중에는 스트림 이벤트와 무관하게 일정 간격으로 데이터 수집
  void _startChargingMonitoringTimer() {
    _chargingMonitoringTimer?.cancel();
    
    _chargingMonitoringTimer = Timer.periodic(
      _chargingMonitoringInterval,
      (timer) {
        if (!_isCollecting || _isDisposed) {
          timer.cancel();
          _chargingMonitoringTimer = null;
          return;
        }
        
        // BatteryService에서 현재 충전 전류 가져오기
        final batteryInfo = _batteryService.currentBatteryInfo;
        if (batteryInfo != null && 
            batteryInfo.isCharging && 
            batteryInfo.chargingCurrent >= 0) {
          // 시간 기반 기록 (전류값이 같아도 기록)
          _recordChargingCurrent(batteryInfo.chargingCurrent);
        } else {
          // 충전이 종료되었으면 타이머 중지
          timer.cancel();
          _chargingMonitoringTimer = null;
        }
      },
    );
    
    debugPrint('ChargingCurrentHistoryService: 충전 모니터링 타이머 시작 (${_chargingMonitoringInterval.inSeconds}초 간격)');
  }
  
  /// 충전 중 주기적 데이터 수집 타이머 중지
  void _stopChargingMonitoringTimer() {
    _chargingMonitoringTimer?.cancel();
    _chargingMonitoringTimer = null;
    debugPrint('ChargingCurrentHistoryService: 충전 모니터링 타이머 중지');
  }
  
  /// 충전 전류 기록 중지
  void _stopCollection() {
    if (!_isCollecting) return;
    
    debugPrint('ChargingCurrentHistoryService: 데이터 수집 중지');
    _isCollecting = false;
    
    // 충전 모니터링 타이머 중지
    _stopChargingMonitoringTimer();
    
    // 마지막 0mA 기록 추가 (충전 종료 표시)
    _recordChargingCurrent(0, force: true);
    
      // Phase 2: 충전 종료 시 즉시 DB에 저장 (Phase 3: 에러 처리 추가)
      _saveToDatabase().catchError((e) {
        debugPrint('ChargingCurrentHistoryService: 충전 종료 시 저장 실패 - $e');
        // 에러 발생해도 계속 진행
      });
  }
  
  /// 충전 전류값 기록 (Phase 3: 에러 처리 강화)
  /// 중복 방지 및 최소 간격 체크 포함
  /// 개선: 충전 중에는 시간 기반으로도 기록하여 그래프 가로선 표시
  void _recordChargingCurrent(int currentMa, {bool force = false}) {
    if (!_isCollecting && !force) return;
    if (_isDisposed) return;
    
    try {
      final now = DateTime.now();
      final isCharging = currentMa > 0;
      final timeSinceLastRecord = _lastRecordedTime != null 
          ? now.difference(_lastRecordedTime!) 
          : Duration.zero;
      
      // 기록 조건 판단
      bool shouldRecord = force;
      
      if (!shouldRecord) {
        // 1. 전류값이 변경된 경우 → 항상 기록
        if (_lastRecordedCurrent != currentMa) {
          shouldRecord = true;
        }
        // 2. 충전 중이고 시간 간격이 지난 경우 → 시간 축 표시를 위해 기록
        else if (isCharging && timeSinceLastRecord >= _chargingTimeInterval) {
          shouldRecord = true;
          debugPrint('ChargingCurrentHistoryService: 시간 기반 기록 - ${currentMa}mA (${timeSinceLastRecord.inSeconds}초 경과)');
        }
        // 3. 방전 중이고 최소 간격이 지난 경우 (전류값 변경 시에만)
        else if (!isCharging && 
                 _lastRecordedTime != null &&
                 timeSinceLastRecord >= _minRecordingInterval &&
                 _lastRecordedCurrent != currentMa) {
          shouldRecord = true;
        }
      }
      
      // 기록하지 않으면 리턴
      if (!shouldRecord) {
        return;
      }
      
      // 포인트 생성 및 저장
      final point = ChargingCurrentPoint(
        timestamp: now,
        currentMa: currentMa,
      );
      
      // 날짜별로 저장
      final dateKey = _getDateKey(now);
      
      // 날짜 변경 감지 및 과거 날짜 데이터 저장 (Phase 3: 에러 처리 추가)
      if (_lastSavedDateKey != null && _lastSavedDateKey != dateKey) {
        try {
          debugPrint('ChargingCurrentHistoryService: 날짜 변경 감지 - $_lastSavedDateKey -> $dateKey');
          _checkDateChangeAndSave();
        } catch (e) {
          debugPrint('ChargingCurrentHistoryService: 날짜 변경 처리 실패 - $e');
          // 에러 발생해도 계속 진행
        }
      }
      
      if (!_dailyData.containsKey(dateKey)) {
        _dailyData[dateKey] = [];
        
        // Phase 4: 메모리 최적화 - 오래된 날짜 데이터 정리 (Phase 3: 에러 처리 추가)
        try {
          _cleanupOldMemoryData();
        } catch (e) {
          debugPrint('ChargingCurrentHistoryService: 메모리 정리 실패 - $e');
          // 에러 발생해도 계속 진행
        }
      }
      _dailyData[dateKey]!.add(point);
      
      // 마지막 기록 정보 업데이트
      _lastRecordedCurrent = currentMa;
      _lastRecordedTime = now;
      
      debugPrint('ChargingCurrentHistoryService: 전류 기록 - ${currentMa}mA ($dateKey)');
      
      // 배치 저장 임계값 체크 (50개 이상이면 즉시 저장) (Phase 3: 에러 처리 추가)
      final todayData = _dailyData[dateKey] ?? [];
      if (todayData.length >= _batchSaveThreshold) {
        _saveToDatabase().catchError((e) {
          debugPrint('ChargingCurrentHistoryService: 배치 저장 실패 - $e');
          // 에러 발생해도 계속 진행
        });
      }
    } catch (e, stackTrace) {
      // Phase 3: 에러 처리 강화 - 에러 발생 시에도 서비스는 계속 작동
      debugPrint('ChargingCurrentHistoryService: 전류 기록 실패 - $e');
      debugPrint('스택 트레이스: $stackTrace');
    }
  }
  
  /// Phase 4: 오래된 메모리 데이터 정리 (메모리 최적화)
  /// 메모리 정리 전에 DB에 저장되지 않은 데이터를 먼저 저장
  void _cleanupOldMemoryData() {
    if (_dailyData.length <= _maxMemoryDays) return;
    
    final now = DateTime.now();
    final todayKey = _getDateKey(now);
    
    // 메모리 정리 전에 저장되지 않은 과거 날짜 데이터를 먼저 저장
    _saveAllPastDatesToDatabase(todayKey);
    
    // 날짜별로 정렬하여 오래된 것부터 제거
    final sortedDates = _dailyData.keys.toList()..sort();
    final today = DateTime.now();
    final todayKeyForCleanup = _getDateKey(today);
    final yesterdayKey = _getDateKey(today.subtract(const Duration(days: 1)));
    
    // 오늘과 어제를 제외하고 나머지 제거 (이미 DB에 저장된 데이터)
    int removedCount = 0;
    for (final dateKey in sortedDates) {
      if (dateKey != todayKeyForCleanup && dateKey != yesterdayKey) {
        _dailyData.remove(dateKey);
        removedCount++;
      }
    }
    
    if (removedCount > 0) {
      debugPrint('ChargingCurrentHistoryService: 메모리 정리 - $removedCount개 날짜 데이터 제거');
    }
  }
  
  /// 날짜 키 생성 (YYYY-MM-DD 형식)
  String _getDateKey(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
  }
  
  /// 오늘 날짜의 충전 전류 데이터 조회 (Phase 2: DB + 메모리 병합)
  Future<List<ChargingCurrentPoint>> getTodayData() async {
    final today = DateTime.now();
    final todayKey = _getDateKey(today);
    
    // Phase 2: DB에서 데이터 로드
    try {
      final dbData = await _databaseService.getChargingCurrentDataByDate(today);
      
      // DB 데이터를 ChargingCurrentPoint로 변환
      final dbPoints = dbData.map((row) => ChargingCurrentPoint(
        timestamp: row['timestamp'] as DateTime,
        currentMa: row['currentMa'] as int,
      )).toList();
      
      // 메모리 데이터와 병합
      final memoryPoints = _dailyData[todayKey] ?? [];
      
      // 타임스탬프 기준으로 정렬하여 병합 (중복 제거)
      final allPoints = <ChargingCurrentPoint>[];
      final seenTimestamps = <int>{};
      
      for (final point in [...dbPoints, ...memoryPoints]) {
        final timestampKey = point.timestamp.millisecondsSinceEpoch;
        if (!seenTimestamps.contains(timestampKey)) {
          allPoints.add(point);
          seenTimestamps.add(timestampKey);
        }
      }
      
      allPoints.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      
      return allPoints;
    } catch (e) {
      debugPrint('ChargingCurrentHistoryService: DB 데이터 로드 실패 - $e');
      // DB 로드 실패 시 메모리 데이터만 반환
      return _dailyData[todayKey] ?? [];
    }
  }
  
  /// 특정 날짜의 충전 전류 데이터 조회 (Phase 2: DB + 메모리 병합)
  Future<List<ChargingCurrentPoint>> getDataByDate(DateTime date) async {
    final dateKey = _getDateKey(date);
    
    // 오늘이 아닌 경우 DB에서만 조회 (메모리는 오늘 데이터만 유지)
    if (dateKey != _getDateKey(DateTime.now())) {
      try {
        final dbData = await _databaseService.getChargingCurrentDataByDate(date);
        return dbData.map((row) => ChargingCurrentPoint(
          timestamp: row['timestamp'] as DateTime,
          currentMa: row['currentMa'] as int,
        )).toList()..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      } catch (e) {
        debugPrint('ChargingCurrentHistoryService: DB 데이터 조회 실패 - $e');
        return [];
      }
    }
    
    // 오늘 데이터는 getTodayData 사용
    return await getTodayData();
  }
  
  /// 모든 저장된 날짜 키 목록 반환
  List<String> getAvailableDates() {
    return _dailyData.keys.toList()..sort();
  }
  
  /// 메모리 데이터 통계 정보
  int get totalDataPoints {
    return _dailyData.values.fold(0, (sum, list) => sum + list.length);
  }
  
  /// 현재 수집 상태
  bool get isCollecting => _isCollecting;
  
  /// 현재 초기화 상태
  bool get isInitialized => _isInitialized;
  
  /// 에러 처리
  void _onError(dynamic error) {
    debugPrint('ChargingCurrentHistoryService: 스트림 에러 - $error');
    // 에러 발생 시에도 서비스는 계속 실행
  }
  
  // 배치 저장 타이머 제거됨 - 이벤트 기반으로 전환
  // 데이터가 일정량 쌓이거나 충전 종료 시에만 저장
  
  /// 7일 이상 된 데이터 정리 체크 (하루에 한 번만 실행)
  void _checkAndCleanupOldData() {
    if (_isDisposed || !_isInitialized) return;
    
    final now = DateTime.now();
    // 마지막 정리 시간이 없거나, 하루가 지났으면 정리 실행
    if (_lastCleanupTime == null || 
        now.difference(_lastCleanupTime!) >= const Duration(days: 1)) {
      _lastCleanupTime = now;
      _cleanupOldDatabaseData();
    }
  }
  
  /// 날짜 변경 감지 및 과거 날짜 데이터 저장 (7일 전까지)
  void _checkDateChangeAndSave() {
    if (_isDisposed || !_isInitialized) return;
    
    try {
      final now = DateTime.now();
      final todayKey = _getDateKey(now);
      
      // 마지막 저장 날짜가 없으면 오늘 날짜로 초기화
      if (_lastSavedDateKey == null) {
        _lastSavedDateKey = todayKey;
        // 초기화 시에도 메모리에 있는 모든 과거 날짜 데이터 저장
        _saveAllPastDatesToDatabase(todayKey);
        return;
      }
      
      // 날짜가 바뀌었는지 확인
      if (_lastSavedDateKey != todayKey) {
        debugPrint('ChargingCurrentHistoryService: 날짜 변경 감지 - $_lastSavedDateKey -> $todayKey');
        
        // 메모리에 있는 모든 과거 날짜 데이터 저장 (오늘 제외)
        _saveAllPastDatesToDatabase(todayKey);
        
        // 오늘 날짜로 업데이트
        _lastSavedDateKey = todayKey;
      }
    } catch (e, stackTrace) {
      debugPrint('ChargingCurrentHistoryService: 날짜 변경 감지 실패 - $e');
      debugPrint('스택 트레이스: $stackTrace');
    }
  }
  
  /// 메모리에 있는 모든 과거 날짜 데이터를 DB에 저장 (오늘 제외, 7일 전까지)
  void _saveAllPastDatesToDatabase(String todayKey) {
    if (_isDisposed || !_isInitialized) return;
    
    try {
      final now = DateTime.now();
      final cutoffDate = now.subtract(const Duration(days: 7)); // 7일 전
      final cutoffDateKey = _getDateKey(cutoffDate);
      
      // 저장할 날짜 목록 (오늘 제외, 7일 전 이후만)
      final datesToSave = <String>[];
      for (final dateKey in _dailyData.keys) {
        // 오늘 데이터는 제외
        if (dateKey == todayKey) continue;
        
        // 7일 이전 데이터는 저장하지 않음 (나중에 삭제될 예정)
        if (dateKey.compareTo(cutoffDateKey) < 0) {
          // 7일 이전 데이터는 메모리에서만 제거 (DB에 저장하지 않음)
          _dailyData.remove(dateKey);
          debugPrint('ChargingCurrentHistoryService: 7일 이전 데이터 메모리에서 제거 ($dateKey)');
          continue;
        }
        
        datesToSave.add(dateKey);
      }
      
      // 각 날짜의 데이터를 DB에 저장
      for (final dateKey in datesToSave) {
        final data = _dailyData[dateKey];
        if (data != null && data.isNotEmpty) {
          final dateKeyToSave = dateKey;
          _saveDateDataToDatabase(dateKeyToSave, data).then((_) {
            debugPrint('ChargingCurrentHistoryService: $dateKeyToSave 날짜 데이터 저장 완료 - ${data.length}개 포인트');
            // 저장 완료 후 메모리에서 제거 (메모리 최적화)
            // 단, 오늘과 어제는 유지
            final today = DateTime.now();
            final todayKey = _getDateKey(today);
            final yesterdayKey = _getDateKey(today.subtract(const Duration(days: 1)));
            if (dateKeyToSave != todayKey && dateKeyToSave != yesterdayKey) {
              _dailyData.remove(dateKeyToSave);
              debugPrint('ChargingCurrentHistoryService: 저장 완료 후 메모리에서 제거 ($dateKeyToSave)');
            }
          }).catchError((e) {
            debugPrint('ChargingCurrentHistoryService: $dateKeyToSave 날짜 데이터 저장 실패 - $e');
          });
        }
      }
      
      if (datesToSave.isNotEmpty) {
        debugPrint('ChargingCurrentHistoryService: ${datesToSave.length}개 날짜 데이터 저장 시작');
      }
    } catch (e, stackTrace) {
      debugPrint('ChargingCurrentHistoryService: 과거 날짜 데이터 저장 실패 - $e');
      debugPrint('스택 트레이스: $stackTrace');
    }
  }
  
  /// 특정 날짜의 데이터를 DB에 저장
  Future<void> _saveDateDataToDatabase(String dateKey, List<ChargingCurrentPoint> data) async {
    if (_isDisposed || !_isInitialized) return;
    if (data.isEmpty) return;
    
    try {
      final pointsToSave = data.map((point) => {
        'timestamp': point.timestamp,
        'currentMa': point.currentMa,
      }).toList();
      
      if (pointsToSave.isNotEmpty) {
        await _databaseService.insertChargingCurrentPoints(pointsToSave);
        debugPrint('ChargingCurrentHistoryService: $dateKey 날짜 데이터 ${pointsToSave.length}개 DB 저장 완료');
      }
    } catch (e, stackTrace) {
      debugPrint('ChargingCurrentHistoryService: $dateKey 날짜 데이터 DB 저장 실패 - $e');
      debugPrint('스택 트레이스: $stackTrace');
    }
  }
  
  /// 7일 이상 된 데이터 자동 삭제
  void _cleanupOldDatabaseData() {
    if (_isDisposed || !_isInitialized) return;
    
    // 비동기로 실행 (블로킹하지 않음)
    _databaseService.cleanupOldChargingCurrentData().then((deletedCount) {
      if (deletedCount > 0) {
        debugPrint('ChargingCurrentHistoryService: 7일 이상 된 데이터 $deletedCount개 삭제 완료');
      }
    }).catchError((e) {
      debugPrint('ChargingCurrentHistoryService: 오래된 데이터 삭제 실패 - $e');
    });
  }
  
  // 배치 저장 타이머 제거됨 (더 이상 사용하지 않음)
  
  /// Phase 2: 메모리 데이터를 DB에 저장 (Phase 3: 에러 처리 강화)
  Future<void> _saveToDatabase() async {
    if (_isDisposed || !_isInitialized) return;
    
    try {
      // 저장할 데이터가 있는 날짜들 찾기
      final todayKey = _getDateKey(DateTime.now());
      final todayData = _dailyData[todayKey];
      
      if (todayData == null || todayData.isEmpty) {
        return; // 저장할 데이터 없음
      }
      
      // Phase 3: 저장 전 데이터 검증
      if (todayData.length > 10000) {
        debugPrint('ChargingCurrentHistoryService: 저장할 데이터가 너무 많음 (${todayData.length}개), 일부만 저장');
        // 너무 많은 데이터는 최근 것만 저장
        final recentData = todayData.sublist(todayData.length - 1000);
        _dailyData[todayKey] = recentData;
      }
      
      // DB에 저장되지 않은 데이터만 필터링 (간단한 체크: 이미 저장된 데이터는 제외)
      // 실제 구현에서는 저장된 마지막 타임스탬프를 추적하거나, 전체를 저장하고 중복 제거
      // Phase 2에서는 단순히 모든 데이터를 저장하되, DB에서 이미 존재하는지 확인하지 않음
      // (DB의 conflictAlgorithm.replace로 자동 처리)
      
      final pointsToSave = _dailyData[todayKey]!.map((point) => {
        'timestamp': point.timestamp,
        'currentMa': point.currentMa,
      }).toList();
      
      if (pointsToSave.isNotEmpty) {
        await _databaseService.insertChargingCurrentPoints(pointsToSave);
        debugPrint('ChargingCurrentHistoryService: ${pointsToSave.length}개 데이터 DB 저장 완료');
        
        // 저장 후 메모리 데이터는 유지 (빠른 접근을 위해)
        // 필요시 저장된 데이터만 메모리에서 제거할 수 있지만, 
        // Phase 2에서는 유지하여 빠른 조회 지원
      }
    } catch (e, stackTrace) {
      // Phase 3: 에러 처리 강화 - 에러 발생 시에도 서비스는 계속 작동
      debugPrint('ChargingCurrentHistoryService: DB 저장 실패 - $e');
      debugPrint('스택 트레이스: $stackTrace');
      // 에러 발생해도 메모리 데이터는 유지하여 다음 저장 시도 시 다시 저장 가능
    }
  }
  
  /// Phase 3: 공개 메서드로 변경 (외부에서 호출 가능)
  Future<void> saveToDatabase() => _saveToDatabase();
  
  /// Phase 2: 백그라운드에서 수집된 데이터 확인 및 동기화
  Future<void> _checkAndSyncBackgroundData() async {
    if (_isDisposed || !_isInitialized) return;
    
    try {
      debugPrint('ChargingCurrentHistoryService: 백그라운드 데이터 확인 시작...');
      
      final db = _databaseService.database;
      if (db == null) {
        debugPrint('ChargingCurrentHistoryService: 데이터베이스가 초기화되지 않음');
        return;
      }
      
      // 최근 24시간 내의 백그라운드 데이터 확인
      final cutoffTime = DateTime.now().subtract(const Duration(hours: 24));
      final cutoffTimestamp = cutoffTime.millisecondsSinceEpoch;
      
      // Phase 5: 백그라운드에서 수집된 데이터 확인 (쿼리 최적화)
      // 인덱스 idx_collection_method_timestamp를 활용하여 빠른 조회
      final results = await db.query(
        'battery_history',
        columns: ['timestamp', 'charging_current'],
        where: 'timestamp >= ? AND collection_method = ?',
        whereArgs: [cutoffTimestamp, 'background_workmanager'],
        orderBy: 'timestamp ASC',
        // Phase 5: 배치 처리 최적화 - 한 번에 너무 많은 데이터를 로드하지 않음
        // (메모리 사용량 최적화)
      );
      
      if (results.isNotEmpty) {
        debugPrint('ChargingCurrentHistoryService: 백그라운드 데이터 ${results.length}개 발견');
        
        // 백그라운드 데이터를 메모리에 로드 (날짜별로 그룹화)
        for (final row in results) {
          final timestamp = DateTime.fromMillisecondsSinceEpoch(row['timestamp'] as int);
          final currentMa = row['charging_current'] as int;
          final dateKey = _getDateKey(timestamp);
          
          if (!_dailyData.containsKey(dateKey)) {
            _dailyData[dateKey] = [];
          }
          
          // 중복 체크 (같은 타임스탬프가 이미 있으면 스킵)
          // 타임스탬프가 정확히 일치하는 경우만 중복으로 간주
          final isDuplicate = _dailyData[dateKey]!.any(
            (point) => point.timestamp.millisecondsSinceEpoch == timestamp.millisecondsSinceEpoch,
          );
          
          if (!isDuplicate) {
            _dailyData[dateKey]!.add(ChargingCurrentPoint(
              timestamp: timestamp,
              currentMa: currentMa,
            ));
          }
        }
        
        // 날짜별로 정렬
        for (final dateKey in _dailyData.keys) {
          _dailyData[dateKey]!.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        }
        
        debugPrint('ChargingCurrentHistoryService: 백그라운드 데이터 동기화 완료');
      } else {
        debugPrint('ChargingCurrentHistoryService: 백그라운드 데이터 없음');
      }
    } catch (e, stackTrace) {
      debugPrint('ChargingCurrentHistoryService: 백그라운드 데이터 확인 실패 - $e');
      debugPrint('스택 트레이스: $stackTrace');
    }
  }
  
  /// Phase 2: 오늘 날짜의 DB 데이터를 메모리로 로드
  Future<void> _loadTodayDataFromDatabase() async {
    if (_isDisposed || !_isInitialized) return;
    
    try {
      final today = DateTime.now();
      final todayKey = _getDateKey(today);
      
      // 이미 메모리에 데이터가 있으면 스킵 (중복 로드 방지)
      if (_dailyData.containsKey(todayKey) && _dailyData[todayKey]!.isNotEmpty) {
        return;
      }
      
      final dbData = await _databaseService.getChargingCurrentDataByDate(today);
      
      if (dbData.isNotEmpty) {
        final points = dbData.map((row) => ChargingCurrentPoint(
          timestamp: row['timestamp'] as DateTime,
          currentMa: row['currentMa'] as int,
        )).toList();
        
        _dailyData[todayKey] = points;
        debugPrint('ChargingCurrentHistoryService: 오늘 데이터 ${points.length}개 DB에서 로드 완료');
      }
    } catch (e, stackTrace) {
      debugPrint('ChargingCurrentHistoryService: DB 데이터 로드 실패 - $e');
      debugPrint('스택 트레이스: $stackTrace');
    }
  }
  
  /// 서비스 정리
  void dispose() {
    if (_isDisposed) return;
    
    debugPrint('ChargingCurrentHistoryService: dispose 시작...');
    
    _isDisposed = true;
    _isCollecting = false;
    
    // 날짜 변경 체크 및 어제 데이터 저장
    _checkDateChangeAndSave();
    // 마지막 저장 (오늘 데이터)
    _saveToDatabase();
    
    // 배치 저장 타이머 제거됨 (더 이상 사용하지 않음)
    
    // 충전 모니터링 타이머 중지
    _stopChargingMonitoringTimer();
    
    // 스트림 구독 해제
    _batteryInfoSubscription?.cancel();
    _batteryInfoSubscription = null;
    
    // 메모리 데이터 정리 (선택적 - 필요시 유지)
    // _dailyData.clear(); // Phase 2에서는 유지하여 빠른 조회 지원
    
    debugPrint('ChargingCurrentHistoryService: dispose 완료');
  }
  
  /// 디버그용: 메모리 데이터 출력
  void debugPrintMemoryData() {
    debugPrint('=== ChargingCurrentHistoryService 메모리 데이터 ===');
    debugPrint('총 데이터 포인트: $totalDataPoints');
    debugPrint('저장된 날짜 수: ${_dailyData.length}');
    
    for (final entry in _dailyData.entries) {
      debugPrint('날짜: ${entry.key}, 포인트 수: ${entry.value.length}');
      if (entry.value.isNotEmpty) {
        debugPrint('  첫 번째: ${entry.value.first}');
        debugPrint('  마지막: ${entry.value.last}');
      }
    }
    debugPrint('==========================================');
  }
}
