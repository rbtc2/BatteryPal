import 'package:flutter/foundation.dart';
import 'native_battery_service.dart';
import 'battery_history_database_service.dart';
import 'charging_current_history_service.dart';
import '../screens/analysis/widgets/charging_patterns/services/charging_session_service.dart';

/// 백그라운드에서 수집된 데이터 복구 서비스
/// 
/// 앱이 꺼져 있는 동안 네이티브에서 수집한 충전 데이터를
/// Flutter 서비스들과 동기화합니다.
class BackgroundDataRecoveryService {
  static final BackgroundDataRecoveryService _instance = 
      BackgroundDataRecoveryService._internal();
  factory BackgroundDataRecoveryService() => _instance;
  BackgroundDataRecoveryService._internal();

  final BatteryHistoryDatabaseService _databaseService = BatteryHistoryDatabaseService();
  final ChargingCurrentHistoryService _chargingCurrentHistoryService = ChargingCurrentHistoryService();
  final ChargingSessionService _chargingSessionService = ChargingSessionService();
  
  bool _isRecovering = false;
  DateTime? _lastRecoveryTime;
  BackgroundDataRecoveryResult? _lastRecoveryResult;

  /// 백그라운드 데이터 복구 실행
  /// 
  /// 앱 시작 시 호출하여 네이티브에서 수집한 데이터를 확인하고
  /// Flutter 서비스들과 동기화합니다.
  /// 
  /// Returns: 복구 결과 정보
  Future<BackgroundDataRecoveryResult> recoverBackgroundData() async {
    if (_isRecovering) {
      debugPrint('BackgroundDataRecoveryService: 이미 복구 중입니다');
      return _lastRecoveryResult ?? BackgroundDataRecoveryResult(
        hasBackgroundData: false,
        dataCount: 0,
        sessionCount: 0,
      );
    }

    try {
      _isRecovering = true;
      debugPrint('BackgroundDataRecoveryService: 백그라운드 데이터 복구 시작...');

      // 1. 데이터베이스 초기화 확인
      if (!_databaseService.isInitialized) {
        await _databaseService.initialize();
      }

      // 2. 네이티브에서 충전 세션 정보 확인
      final sessionInfo = await NativeBatteryService.getChargingSessionInfo();
      
      int sessionCount = 0;
      int dataCount = 0;
      bool hasBackgroundData = false;
      
      if (sessionInfo != null) {
        debugPrint('BackgroundDataRecoveryService: 네이티브 세션 정보 발견 - $sessionInfo');
        
        // 3. 데이터베이스에서 최근 충전 데이터 확인
        final recentData = await _checkRecentBackgroundData(sessionInfo);
        
        if (recentData.hasBackgroundData) {
          debugPrint('BackgroundDataRecoveryService: 백그라운드 데이터 발견 - ${recentData.dataCount}개 포인트');
          
          hasBackgroundData = true;
          dataCount = recentData.dataCount;
          
          // 4. 충전 전류 히스토리 서비스에 데이터 동기화 알림
          await _syncChargingCurrentHistory(recentData);
          
          // 5. 충전 세션 서비스에 세션 복구 알림
          await _recoverChargingSession(sessionInfo, recentData);
          
          // 6. Phase 4: 복구된 세션 개수 확인
          sessionCount = await _countRecoveredSessions();
        } else {
          debugPrint('BackgroundDataRecoveryService: 백그라운드 데이터 없음');
        }
      } else {
        debugPrint('BackgroundDataRecoveryService: 네이티브 세션 정보 없음');
      }

      // Phase 4: 복구 결과 저장
      final result = BackgroundDataRecoveryResult(
        hasBackgroundData: hasBackgroundData,
        dataCount: dataCount,
        sessionCount: sessionCount,
      );
      _lastRecoveryResult = result;
      _lastRecoveryTime = DateTime.now();
      
      debugPrint('BackgroundDataRecoveryService: 백그라운드 데이터 복구 완료 - 데이터: $dataCount개, 세션: $sessionCount개');
      
      return result;
      
    } catch (e, stackTrace) {
      debugPrint('BackgroundDataRecoveryService: 복구 실패 - $e');
      debugPrint('스택 트레이스: $stackTrace');
      
      final errorResult = BackgroundDataRecoveryResult(
        hasBackgroundData: false,
        dataCount: 0,
        sessionCount: 0,
      );
      _lastRecoveryResult = errorResult;
      return errorResult;
    } finally {
      _isRecovering = false;
    }
  }
  
  /// Phase 4: 복구된 세션 개수 확인
  Future<int> _countRecoveredSessions() async {
    try {
      final db = _databaseService.database;
      if (db == null) return 0;
      
      // 최근 24시간 내의 백그라운드 데이터로부터 생성된 세션 개수 확인
      // (실제로는 ChargingSessionService가 세션을 분석하므로, 여기서는 대략적인 추정)
      final cutoffTime = DateTime.now().subtract(const Duration(hours: 24));
      final cutoffTimestamp = cutoffTime.millisecondsSinceEpoch;
      
      // 백그라운드 데이터 포인트 개수를 기반으로 세션 개수 추정
      // (충전 시작/종료 패턴을 분석하여 세션 개수 계산)
      final results = await db.query(
        'battery_history',
        columns: ['timestamp', 'is_charging'],
        where: 'timestamp >= ? AND collection_method = ?',
        whereArgs: [cutoffTimestamp, 'background_workmanager'],
        orderBy: 'timestamp ASC',
      );
      
      if (results.isEmpty) return 0;
      
      // 충전 시작/종료 패턴 분석
      int sessionCount = 0;
      bool wasCharging = false;
      
      for (final row in results) {
        final isCharging = (row['is_charging'] as int) == 1;
        
        if (isCharging && !wasCharging) {
          // 충전 시작
          sessionCount++;
        }
        
        wasCharging = isCharging;
      }
      
      return sessionCount;
    } catch (e) {
      debugPrint('BackgroundDataRecoveryService: 세션 개수 확인 실패 - $e');
      return 0;
    }
  }

  /// 최근 백그라운드 데이터 확인
  Future<BackgroundDataInfo> _checkRecentBackgroundData(
    ChargingSessionInfo sessionInfo,
  ) async {
    try {
      final db = _databaseService.database;
      if (db == null) {
        return BackgroundDataInfo(hasBackgroundData: false, dataCount: 0);
      }

      // 네이티브에서 수집한 데이터는 collection_method가 'background_workmanager'로 표시됨
      // 최근 24시간 내의 백그라운드 데이터 확인
      final cutoffTime = DateTime.now().subtract(const Duration(hours: 24));
      final cutoffTimestamp = cutoffTime.millisecondsSinceEpoch;

      final results = await db.query(
        'battery_history',
        columns: ['COUNT(*) as count'],
        where: 'timestamp >= ? AND collection_method = ?',
        whereArgs: [cutoffTimestamp, 'background_workmanager'],
      );

      final count = results.isNotEmpty ? (results.first['count'] as int? ?? 0) : 0;
      
      return BackgroundDataInfo(
        hasBackgroundData: count > 0,
        dataCount: count,
      );
    } catch (e) {
      debugPrint('BackgroundDataRecoveryService: 최근 데이터 확인 실패 - $e');
      return BackgroundDataInfo(hasBackgroundData: false, dataCount: 0);
    }
  }

  /// 충전 전류 히스토리 서비스에 데이터 동기화 (Phase 2 개선)
  Future<void> _syncChargingCurrentHistory(BackgroundDataInfo dataInfo) async {
    try {
      if (!dataInfo.hasBackgroundData) return;

      debugPrint('BackgroundDataRecoveryService: 충전 전류 히스토리 동기화 시작...');
      
      // 서비스가 초기화되지 않았다면 초기화
      if (!_chargingCurrentHistoryService.isInitialized) {
        await _chargingCurrentHistoryService.initialize();
      }
      
      // Phase 2: ChargingCurrentHistoryService의 _checkAndSyncBackgroundData()가 
      // 이미 initialize()에서 호출되므로, 여기서는 추가 동기화가 필요 없음
      // 다만, 명시적으로 동기화를 강제하려면 서비스에 동기화 메서드를 추가할 수 있음
      
      debugPrint('BackgroundDataRecoveryService: 충전 전류 히스토리 동기화 완료 (${dataInfo.dataCount}개 데이터)');
    } catch (e) {
      debugPrint('BackgroundDataRecoveryService: 충전 전류 히스토리 동기화 실패 - $e');
    }
  }

  /// 충전 세션 복구 (Phase 2 개선)
  Future<void> _recoverChargingSession(
    ChargingSessionInfo sessionInfo,
    BackgroundDataInfo dataInfo,
  ) async {
    try {
      if (!dataInfo.hasBackgroundData) {
        return;
      }

      debugPrint('BackgroundDataRecoveryService: 충전 세션 복구 시작...');
      
      // ChargingSessionService가 초기화되지 않았다면 초기화
      if (!_chargingSessionService.isInitialized) {
        await _chargingSessionService.initialize();
      }

      // Phase 2: ChargingSessionService의 _recoverBackgroundSession()이 
      // 이미 initialize()에서 호출되므로, 여기서는 추가 복구가 필요 없음
      // 다만, 명시적으로 복구를 강제하려면 서비스에 복구 메서드를 추가할 수 있음
      
      // 세션이 아직 진행 중인 경우, ChargingSessionService가 자동으로 감지할 수 있도록
      // BatteryService의 현재 상태를 확인
      // (ChargingSessionService는 BatteryService 스트림을 구독하므로 자동으로 처리됨)
      
      debugPrint('BackgroundDataRecoveryService: 충전 세션 복구 완료');
    } catch (e) {
      debugPrint('BackgroundDataRecoveryService: 충전 세션 복구 실패 - $e');
    }
  }

  /// 마지막 복구 시간 가져오기
  DateTime? get lastRecoveryTime => _lastRecoveryTime;

  /// 마지막 복구 결과 가져오기
  BackgroundDataRecoveryResult? get lastRecoveryResult => _lastRecoveryResult;

  /// 복구 중인지 확인
  bool get isRecovering => _isRecovering;
}

/// 백그라운드 데이터 정보
class BackgroundDataInfo {
  final bool hasBackgroundData;
  final int dataCount;

  BackgroundDataInfo({
    required this.hasBackgroundData,
    required this.dataCount,
  });
}

/// Phase 4: 백그라운드 데이터 복구 결과
class BackgroundDataRecoveryResult {
  final bool hasBackgroundData;
  final int dataCount;
  final int sessionCount;

  BackgroundDataRecoveryResult({
    required this.hasBackgroundData,
    required this.dataCount,
    required this.sessionCount,
  });
  
  /// 복구된 데이터가 있는지 확인
  bool get hasRecoveredData => hasBackgroundData && (dataCount > 0 || sessionCount > 0);
}

