import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../models/battery_history_models.dart';
import 'database/database_manager.dart';
import 'database/repositories/battery_data_repository.dart';
import 'database/repositories/charging_current_repository.dart';
import 'database/repositories/charging_session_repository.dart';
import 'database/maintenance/data_cleanup_service.dart';
import 'database/maintenance/data_compression_service.dart';
import 'database/maintenance/backup_service.dart';

/// 배터리 히스토리 데이터베이스 서비스
/// 
/// Facade 패턴을 사용하여 데이터베이스 관련 모든 작업을 통합 관리하는 메인 서비스입니다.
/// 
/// 이 서비스는 다음과 같은 책임을 가집니다:
/// - 데이터베이스 초기화 및 생명주기 관리
/// - 배터리 데이터, 충전 전류 데이터, 충전 세션 데이터의 CRUD 작업 위임
/// - 데이터 정리, 압축, 백업/복원 작업 위임
/// 
/// 실제 구현은 각각의 Repository와 Maintenance 서비스에서 처리됩니다.
/// 
/// 사용 예시:
/// ```dart
/// final service = BatteryHistoryDatabaseService();
/// await service.initialize();
/// 
/// // 배터리 데이터 저장
/// final id = await service.insertBatteryDataPoint(dataPoint);
/// 
/// // 데이터 조회
/// final data = await service.getBatteryHistoryData(
///   startTime: DateTime.now().subtract(Duration(days: 7)),
/// );
/// ```
class BatteryHistoryDatabaseService {
  static final BatteryHistoryDatabaseService _instance = 
      BatteryHistoryDatabaseService._internal();
  factory BatteryHistoryDatabaseService() => _instance;
  BatteryHistoryDatabaseService._internal();

  // ==================== 의존성 주입 ====================
  final DatabaseManager _databaseManager = DatabaseManager();
  final BatteryDataRepository _batteryDataRepository = BatteryDataRepository();
  final ChargingCurrentRepository _chargingCurrentRepository = ChargingCurrentRepository();
  final ChargingSessionRepository _chargingSessionRepository = ChargingSessionRepository();
  final DataCleanupService _dataCleanupService = DataCleanupService();
  final DataCompressionService _dataCompressionService = DataCompressionService();
  final BackupService _backupService = BackupService();

  // ==================== 공개 속성 ====================
  
  /// 데이터베이스 인스턴스 반환
  Database? get database => _databaseManager.database;
  
  /// 초기화 완료 여부
  bool get isInitialized => _databaseManager.isInitialized;
  
  /// 초기화 완료 대기
  Future<void> get initialization => _databaseManager.initialization;

  // ==================== 초기화 및 생명주기 ====================

  /// 데이터베이스 초기화
  /// 
  /// 데이터베이스를 초기화하고 자동 정리 스케줄을 시작합니다.
  /// 
  /// Throws: 데이터베이스 초기화 실패 시 예외 발생
  Future<void> initialize() async {
    try {
      await _databaseManager.initialize();
      
      // 초기화 후 자동 정리 스케줄 시작
      final db = database;
      if (db != null) {
        _dataCleanupService.scheduleAutoCleanup(
          db,
          cleanupOldDataCallback: () => cleanupOldData(),
          cleanupChargingCurrentDataCallback: () => cleanupOldChargingCurrentData(),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('데이터베이스 초기화 실패: $e');
      debugPrint('스택 트레이스: $stackTrace');
      rethrow;
    }
  }

  /// 데이터베이스 닫기
  /// 
  /// 데이터베이스 연결을 종료합니다.
  Future<void> close() async {
    await _databaseManager.close();
  }

  // ==================== 배터리 데이터 관리 ====================

  /// 배터리 히스토리 데이터 포인트 저장
  /// 
  /// [dataPoint]: 저장할 배터리 데이터 포인트
  /// 
  /// Returns: 저장된 데이터의 ID
  /// 
  /// Throws: 데이터베이스가 초기화되지 않았거나 저장 실패 시 예외 발생
  Future<int> insertBatteryDataPoint(BatteryHistoryDataPoint dataPoint) async {
    final db = await _ensureInitialized();
    
    try {
      final id = await _batteryDataRepository.insertBatteryDataPoint(db, dataPoint);
      
      // 데이터 포인트 수가 임계값을 초과하면 자동 압축 실행
      await _dataCompressionService.checkAndCompressData(db);
      
      return id;
    } catch (e, stackTrace) {
      debugPrint('배터리 데이터 포인트 저장 실패: $e');
      debugPrint('스택 트레이스: $stackTrace');
      rethrow;
    }
  }

  /// 여러 배터리 히스토리 데이터 포인트 일괄 저장 (성능 최적화)
  /// 
  /// 트랜잭션을 사용하여 성능을 최적화합니다.
  /// 
  /// [dataPoints]: 저장할 배터리 데이터 포인트 리스트
  /// 
  /// Returns: 저장된 데이터의 ID 리스트
  /// 
  /// Throws: 데이터베이스가 초기화되지 않았거나 저장 실패 시 예외 발생
  Future<List<int>> insertBatteryDataPoints(List<BatteryHistoryDataPoint> dataPoints) async {
    final db = await _ensureInitialized();
    
    try {
      return await _batteryDataRepository.insertBatteryDataPoints(db, dataPoints);
    } catch (e, stackTrace) {
      debugPrint('배터리 데이터 포인트 일괄 저장 실패: $e');
      debugPrint('스택 트레이스: $stackTrace');
      rethrow;
    }
  }

  /// 특정 기간의 배터리 히스토리 데이터 조회
  /// 
  /// [startTime]: 시작 시간 (옵션)
  /// [endTime]: 종료 시간 (옵션)
  /// [limit]: 조회할 최대 개수 (옵션)
  /// [offset]: 오프셋 (옵션)
  /// [orderByTimestampDesc]: 타임스탬프 내림차순 정렬 여부
  /// 
  /// Returns: 배터리 히스토리 데이터 포인트 리스트
  /// 
  /// Throws: 데이터베이스가 초기화되지 않았거나 조회 실패 시 예외 발생
  Future<List<BatteryHistoryDataPoint>> getBatteryHistoryData({
    DateTime? startTime,
    DateTime? endTime,
    int? limit,
    int? offset,
    bool orderByTimestampDesc = false,
  }) async {
    final db = await _ensureInitialized();
    
    try {
      return await _batteryDataRepository.getBatteryHistoryData(
        db,
        startTime: startTime,
        endTime: endTime,
        limit: limit,
        offset: offset,
        orderByTimestampDesc: orderByTimestampDesc,
      );
    } catch (e, stackTrace) {
      debugPrint('배터리 히스토리 데이터 조회 실패: $e');
      debugPrint('스택 트레이스: $stackTrace');
      rethrow;
    }
  }

  /// 최근 N개의 배터리 히스토리 데이터 조회
  /// 
  /// [count]: 조회할 개수
  /// 
  /// Returns: 배터리 히스토리 데이터 포인트 리스트 (최신순)
  /// 
  /// Throws: 데이터베이스가 초기화되지 않았거나 조회 실패 시 예외 발생
  Future<List<BatteryHistoryDataPoint>> getRecentBatteryHistoryData(int count) async {
    final db = await _ensureInitialized();
    
    try {
      return await _batteryDataRepository.getRecentBatteryHistoryData(db, count);
    } catch (e, stackTrace) {
      debugPrint('최근 배터리 히스토리 데이터 조회 실패: $e');
      debugPrint('스택 트레이스: $stackTrace');
      rethrow;
    }
  }

  /// 특정 기간의 배터리 통계 조회
  /// 
  /// [startTime]: 시작 시간 (옵션)
  /// [endTime]: 종료 시간 (옵션)
  /// 
  /// Returns: 배터리 통계 맵 (count, avg_level, min_level, max_level, avg_temperature, avg_quality, charging_count)
  /// 
  /// Throws: 데이터베이스가 초기화되지 않았거나 조회 실패 시 예외 발생
  Future<Map<String, dynamic>> getBatteryStatistics({
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    final db = await _ensureInitialized();
    
    try {
      return await _batteryDataRepository.getBatteryStatistics(
        db,
        startTime: startTime,
        endTime: endTime,
      );
    } catch (e, stackTrace) {
      debugPrint('배터리 통계 조회 실패: $e');
      debugPrint('스택 트레이스: $stackTrace');
      rethrow;
    }
  }

  /// 데이터 포인트 수 조회
  /// 
  /// Returns: 데이터 포인트 개수
  /// 
  /// Throws: 데이터베이스가 초기화되지 않았거나 조회 실패 시 예외 발생
  Future<int> getDataPointCount() async {
    final db = await _ensureInitialized();
    
    try {
      return await _batteryDataRepository.getDataPointCount(db);
    } catch (e) {
      debugPrint('데이터 포인트 수 조회 실패: $e');
      return 0;
    }
  }

  // ==================== 충전 전류 데이터 관리 ====================

  /// 충전 전류 데이터 포인트 일괄 저장
  /// 
  /// timestamp와 currentMa만 포함된 Map 리스트를 받아서 저장합니다.
  /// 기존 데이터가 있으면 charging_current만 업데이트하고,
  /// 없으면 기본값으로 새 레코드를 생성합니다.
  /// 
  /// [points]: timestamp와 currentMa를 포함한 Map 리스트
  /// 
  /// Returns: 저장된 데이터의 ID 리스트
  /// 
  /// Throws: 데이터베이스가 초기화되지 않았거나 저장 실패 시 예외 발생
  Future<List<int>> insertChargingCurrentPoints(List<Map<String, dynamic>> points) async {
    final db = await _ensureInitialized();
    
    try {
      return await _chargingCurrentRepository.insertChargingCurrentPoints(db, points);
    } catch (e, stackTrace) {
      debugPrint('충전 전류 데이터 포인트 일괄 저장 실패: $e');
      debugPrint('스택 트레이스: $stackTrace');
      rethrow;
    }
  }

  /// 특정 날짜의 충전 전류 데이터 조회
  /// 
  /// 날짜별로 그룹화하여 timestamp와 charging_current를 반환합니다.
  /// 같은 시간(분 단위)의 포인트는 더 높은 전류 값을 가진 것으로 선택합니다.
  /// 
  /// [date]: 조회할 날짜
  /// 
  /// Returns: timestamp와 currentMa를 포함한 Map 리스트
  /// 
  /// Throws: 데이터베이스가 초기화되지 않았거나 조회 실패 시 예외 발생
  Future<List<Map<String, dynamic>>> getChargingCurrentDataByDate(DateTime date) async {
    final db = await _ensureInitialized();
    
    try {
      return await _chargingCurrentRepository.getChargingCurrentDataByDate(db, date);
    } catch (e, stackTrace) {
      debugPrint('충전 전류 데이터 조회 실패: $e');
      debugPrint('스택 트레이스: $stackTrace');
      rethrow;
    }
  }

  // ==================== 충전 세션 관리 ====================

  /// 충전 세션 저장
  /// 
  /// [sessionMap]: 저장할 충전 세션 데이터 (Map 형식)
  /// 
  /// Throws: 데이터베이스가 초기화되지 않았거나 저장 실패 시 예외 발생
  Future<void> insertChargingSession(Map<String, dynamic> sessionMap) async {
    final db = await _ensureInitialized();
    
    try {
      await _chargingSessionRepository.insertChargingSession(db, sessionMap);
    } catch (e, stackTrace) {
      debugPrint('충전 세션 저장 실패: $e');
      debugPrint('스택 트레이스: $stackTrace');
      rethrow;
    }
  }
  
  /// 여러 충전 세션 일괄 저장
  /// 
  /// 트랜잭션을 사용하여 성능을 최적화합니다.
  /// 
  /// [sessionMaps]: 저장할 충전 세션 데이터 리스트 (Map 형식)
  /// 
  /// Throws: 데이터베이스가 초기화되지 않았거나 저장 실패 시 예외 발생
  Future<void> insertChargingSessions(List<Map<String, dynamic>> sessionMaps) async {
    final db = await _ensureInitialized();
    
    try {
      await _chargingSessionRepository.insertChargingSessions(db, sessionMaps);
    } catch (e, stackTrace) {
      debugPrint('충전 세션 일괄 저장 실패: $e');
      debugPrint('스택 트레이스: $stackTrace');
      rethrow;
    }
  }
  
  /// 특정 날짜의 충전 세션 조회
  /// 
  /// [date]: 조회할 날짜
  /// 
  /// Returns: 충전 세션 데이터 리스트 (speed_changes는 자동으로 파싱됨)
  /// 
  /// Throws: 데이터베이스가 초기화되지 않았거나 조회 실패 시 예외 발생
  Future<List<Map<String, dynamic>>> getChargingSessionsByDate(DateTime date) async {
    final db = await _ensureInitialized();
    
    try {
      return await _chargingSessionRepository.getChargingSessionsByDate(db, date);
    } catch (e, stackTrace) {
      debugPrint('충전 세션 조회 실패: $e');
      debugPrint('스택 트레이스: $stackTrace');
      rethrow;
    }
  }
  
  /// 세션 ID로 충전 세션 조회
  /// 
  /// [sessionId]: 조회할 세션 ID
  /// 
  /// Returns: 충전 세션 데이터 (없으면 null, speed_changes는 자동으로 파싱됨)
  /// 
  /// Throws: 데이터베이스가 초기화되지 않았거나 조회 실패 시 예외 발생
  Future<Map<String, dynamic>?> getChargingSessionById(String sessionId) async {
    final db = await _ensureInitialized();
    
    try {
      return await _chargingSessionRepository.getChargingSessionById(db, sessionId);
    } catch (e, stackTrace) {
      debugPrint('충전 세션 ID로 조회 실패: $e');
      debugPrint('스택 트레이스: $stackTrace');
      rethrow;
    }
  }
  
  /// 7일 이상 된 충전 세션 데이터 삭제
  /// 
  /// Returns: 삭제된 세션 개수
  /// 
  /// Throws: 데이터베이스가 초기화되지 않았거나 삭제 실패 시 예외 발생
  Future<int> cleanupOldChargingSessions() async {
    final db = await _ensureInitialized();
    
    try {
      return await _chargingSessionRepository.cleanupOldChargingSessions(db, cutoffDays: 7);
    } catch (e, stackTrace) {
      debugPrint('오래된 충전 세션 데이터 정리 실패: $e');
      debugPrint('스택 트레이스: $stackTrace');
      rethrow;
    }
  }

  // ==================== 데이터 유지보수 ====================

  /// 오래된 데이터 정리
  /// 
  /// 지정된 보관 기간을 초과한 배터리 데이터를 삭제합니다.
  /// 
  /// [retentionDays]: 보관 기간 (일), 기본값은 설정값 사용
  /// 
  /// Returns: 삭제된 데이터 개수
  /// 
  /// Throws: 데이터베이스가 초기화되지 않았거나 정리 실패 시 예외 발생
  Future<int> cleanupOldData({int? retentionDays}) async {
    final db = await _ensureInitialized();
    
    try {
      return await _dataCleanupService.cleanupOldData(
        db,
        retentionDays: retentionDays,
      );
    } catch (e, stackTrace) {
      debugPrint('오래된 데이터 정리 실패: $e');
      debugPrint('스택 트레이스: $stackTrace');
      rethrow;
    }
  }
  
  /// 충전 전류 데이터만 정리 (7일 이상 된 데이터 삭제)
  /// 
  /// 그래프용 충전 전류 데이터는 7일만 보관합니다.
  /// 
  /// Returns: 삭제된 데이터 개수
  /// 
  /// Throws: 데이터베이스가 초기화되지 않았거나 정리 실패 시 예외 발생
  Future<int> cleanupOldChargingCurrentData() async {
    final db = await _ensureInitialized();
    
    try {
      return await _dataCleanupService.cleanupOldChargingCurrentData(db);
    } catch (e, stackTrace) {
      debugPrint('오래된 충전 전류 데이터 정리 실패: $e');
      debugPrint('스택 트레이스: $stackTrace');
      rethrow;
    }
  }

  /// 데이터 압축 (중복 데이터 제거)
  /// 
  /// timestamp, level, state가 동일한 데이터 중에서 가장 오래된 것만 남기고 나머지를 삭제합니다.
  /// 
  /// Returns: 압축 완료 (SQLite에서는 영향받은 행 수를 직접 반환하지 않음)
  /// 
  /// Throws: 데이터베이스가 초기화되지 않았거나 압축 실패 시 예외 발생
  Future<int> compressData() async {
    final db = await _ensureInitialized();
    
    try {
      return await _dataCompressionService.compressData(db);
    } catch (e, stackTrace) {
      debugPrint('데이터 압축 실패: $e');
      debugPrint('스택 트레이스: $stackTrace');
      rethrow;
    }
  }

  /// 데이터베이스 백업
  /// 
  /// 현재 데이터베이스 파일을 백업 파일로 복사합니다.
  /// 
  /// Returns: 백업 파일 경로
  /// 
  /// Throws: 데이터베이스가 초기화되지 않았거나 백업 실패 시 예외 발생
  Future<String> backupDatabase() async {
    final db = await _ensureInitialized();
    
    try {
      return await _backupService.backupDatabase(db);
    } catch (e, stackTrace) {
      debugPrint('데이터베이스 백업 실패: $e');
      debugPrint('스택 트레이스: $stackTrace');
      rethrow;
    }
  }

  /// 데이터베이스 복원
  /// 
  /// 백업 파일로부터 데이터베이스를 복원합니다.
  /// 
  /// 주의: 복원 후 데이터베이스가 재초기화됩니다.
  /// 
  /// [backupPath]: 복원할 백업 파일 경로
  /// 
  /// Throws: 데이터베이스가 초기화되지 않았거나 복원 실패 시 예외 발생
  Future<void> restoreDatabase(String backupPath) async {
    await initialization;
    
    try {
      await _backupService.restoreDatabase(backupPath, _databaseManager);
    } catch (e, stackTrace) {
      debugPrint('데이터베이스 복원 실패: $e');
      debugPrint('스택 트레이스: $stackTrace');
      rethrow;
    }
  }

  // ==================== 데이터 삭제 ====================

  /// 모든 배터리 히스토리 데이터 삭제
  /// 
  /// Returns: 삭제된 데이터 개수
  /// 
  /// Throws: 데이터베이스가 초기화되지 않았거나 삭제 실패 시 예외 발생
  Future<int> deleteAllBatteryData() async {
    final db = await _ensureInitialized();
    
    try {
      return await _batteryDataRepository.deleteAllBatteryData(db);
    } catch (e, stackTrace) {
      debugPrint('모든 배터리 히스토리 데이터 삭제 실패: $e');
      debugPrint('스택 트레이스: $stackTrace');
      rethrow;
    }
  }

  /// 모든 충전 전류 데이터 삭제
  /// 
  /// Returns: 삭제된 데이터 개수
  /// 
  /// Throws: 데이터베이스가 초기화되지 않았거나 삭제 실패 시 예외 발생
  Future<int> deleteAllChargingCurrentData() async {
    final db = await _ensureInitialized();
    
    try {
      return await _batteryDataRepository.deleteAllChargingCurrentData(db);
    } catch (e, stackTrace) {
      debugPrint('모든 충전 전류 데이터 삭제 실패: $e');
      debugPrint('스택 트레이스: $stackTrace');
      rethrow;
    }
  }

  /// 모든 충전 세션 데이터 삭제
  /// 
  /// Returns: 삭제된 세션 개수
  /// 
  /// Throws: 데이터베이스가 초기화되지 않았거나 삭제 실패 시 예외 발생
  Future<int> deleteAllChargingSessions() async {
    final db = await _ensureInitialized();
    
    try {
      return await _chargingSessionRepository.deleteAllChargingSessions(db);
    } catch (e, stackTrace) {
      debugPrint('모든 충전 세션 데이터 삭제 실패: $e');
      debugPrint('스택 트레이스: $stackTrace');
      rethrow;
    }
  }

  // ==================== 내부 헬퍼 메서드 ====================

  /// 데이터베이스 초기화 확인 및 인스턴스 반환
  /// 
  /// 데이터베이스가 초기화되지 않았으면 예외를 발생시킵니다.
  /// 
  /// Returns: 초기화된 데이터베이스 인스턴스
  /// 
  /// Throws: 데이터베이스가 초기화되지 않았을 때 예외 발생
  Future<Database> _ensureInitialized() async {
    await initialization;
    final db = database;
    if (db == null) {
      throw Exception('데이터베이스가 초기화되지 않았습니다');
    }
    return db;
  }
}
