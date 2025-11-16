import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../../models/battery_history_models.dart';

/// 데이터베이스 스키마 관리 클래스
/// 테이블 생성, 인덱스 생성, 마이그레이션을 담당합니다.
class SchemaManager {
  /// 싱글톤 인스턴스
  static final SchemaManager _instance = SchemaManager._internal();
  factory SchemaManager() => _instance;
  SchemaManager._internal();

  /// 데이터베이스 생성 시 실행되는 콜백
  /// 
  /// 모든 테이블과 인덱스를 생성합니다.
  /// 
  /// [db]: 데이터베이스 인스턴스
  /// [version]: 데이터베이스 버전
  Future<void> onCreate(Database db, int version) async {
    debugPrint('데이터베이스 테이블 생성 시작...');
    
    // 배터리 히스토리 테이블 생성
    await _createBatteryHistoryTable(db);
    
    // 충전 세션 테이블 생성
    await _createChargingSessionsTable(db);
    
    debugPrint('데이터베이스 테이블 생성 완료');
  }

  /// 배터리 히스토리 테이블 생성
  Future<void> _createBatteryHistoryTable(Database db) async {
    await db.execute('''
      CREATE TABLE ${BatteryHistoryDatabaseConfig.tableName} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp INTEGER NOT NULL,
        level REAL NOT NULL,
        state INTEGER NOT NULL,
        temperature REAL NOT NULL,
        voltage INTEGER NOT NULL,
        capacity INTEGER NOT NULL,
        health INTEGER NOT NULL,
        charging_type TEXT NOT NULL,
        charging_current INTEGER NOT NULL,
        is_charging INTEGER NOT NULL,
        is_app_in_foreground INTEGER NOT NULL,
        collection_method TEXT NOT NULL,
        data_quality REAL NOT NULL,
        created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now'))
      )
    ''');
    
    // 성능 최적화를 위한 인덱스 생성
    await _createBatteryHistoryIndexes(db);
  }

  /// 배터리 히스토리 테이블 인덱스 생성
  Future<void> _createBatteryHistoryIndexes(Database db) async {
    // 단일 컬럼 인덱스
    await db.execute('''
      CREATE INDEX idx_timestamp ON ${BatteryHistoryDatabaseConfig.tableName} (timestamp)
    ''');
    
    await db.execute('''
      CREATE INDEX idx_level ON ${BatteryHistoryDatabaseConfig.tableName} (level)
    ''');
    
    await db.execute('''
      CREATE INDEX idx_state ON ${BatteryHistoryDatabaseConfig.tableName} (state)
    ''');
    
    await db.execute('''
      CREATE INDEX idx_charging ON ${BatteryHistoryDatabaseConfig.tableName} (is_charging)
    ''');
    
    // 복합 인덱스 - 시간 범위 쿼리 최적화
    await db.execute('''
      CREATE INDEX idx_timestamp_range ON ${BatteryHistoryDatabaseConfig.tableName} (timestamp, level)
    ''');
    
    // 충전 상태별 시간 인덱스
    await db.execute('''
      CREATE INDEX idx_charging_timestamp ON ${BatteryHistoryDatabaseConfig.tableName} (is_charging, timestamp)
    ''');
    
    // 충전 전류 데이터 조회 최적화를 위한 날짜별 인덱스
    await db.execute('''
      CREATE INDEX idx_charging_current_date ON ${BatteryHistoryDatabaseConfig.tableName} (charging_current, timestamp)
    ''');
    
    // 데이터 품질 인덱스
    await db.execute('''
      CREATE INDEX idx_data_quality ON ${BatteryHistoryDatabaseConfig.tableName} (data_quality)
    ''');
    
    // Phase 5: 백그라운드 데이터 조회 최적화를 위한 인덱스
    await db.execute('''
      CREATE INDEX idx_collection_method ON ${BatteryHistoryDatabaseConfig.tableName} (collection_method)
    ''');
    
    // Phase 5: 백그라운드 데이터 복구 쿼리 최적화 (collection_method + timestamp)
    await db.execute('''
      CREATE INDEX idx_collection_method_timestamp ON ${BatteryHistoryDatabaseConfig.tableName} (collection_method, timestamp)
    ''');
  }

  /// 충전 세션 테이블 생성
  Future<void> _createChargingSessionsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS charging_sessions (
        id TEXT PRIMARY KEY,
        start_time INTEGER NOT NULL,
        end_time INTEGER NOT NULL,
        start_battery_level REAL NOT NULL,
        end_battery_level REAL NOT NULL,
        battery_change REAL NOT NULL,
        duration_ms INTEGER NOT NULL,
        avg_current REAL NOT NULL,
        avg_temperature REAL NOT NULL,
        max_current INTEGER NOT NULL,
        min_current INTEGER NOT NULL,
        efficiency REAL NOT NULL,
        time_slot TEXT NOT NULL,
        session_title TEXT NOT NULL,
        speed_changes TEXT NOT NULL,
        icon TEXT NOT NULL,
        color INTEGER NOT NULL,
        battery_capacity INTEGER,
        battery_voltage INTEGER,
        is_valid INTEGER NOT NULL DEFAULT 1,
        created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now'))
      )
    ''');
    
    // 충전 세션 테이블 인덱스 생성
    await _createChargingSessionIndexes(db);
    
    debugPrint('충전 세션 테이블 생성 완료');
  }

  /// 충전 세션 테이블 인덱스 생성
  Future<void> _createChargingSessionIndexes(Database db) async {
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_session_start_time ON charging_sessions (start_time)
    ''');
    
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_session_date ON charging_sessions (start_time, time_slot)
    ''');
    
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_session_time_slot ON charging_sessions (time_slot)
    ''');
  }

  /// 데이터베이스 업그레이드 시 실행되는 콜백
  /// 
  /// 버전별 마이그레이션 로직을 실행합니다.
  /// 
  /// [db]: 데이터베이스 인스턴스
  /// [oldVersion]: 이전 버전
  /// [newVersion]: 새 버전
  Future<void> onUpgrade(Database db, int oldVersion, int newVersion) async {
    debugPrint('데이터베이스 업그레이드: $oldVersion -> $newVersion');
    
    // 버전별 마이그레이션
    if (oldVersion < 2) {
      // 버전 2: charging_sessions 테이블 추가
      debugPrint('데이터베이스 업그레이드: 버전 2 - charging_sessions 테이블 추가');
      await _createChargingSessionsTable(db);
    }
    
    // Phase 5: 버전 3 - 성능 최적화 인덱스 추가
    if (oldVersion < 3) {
      debugPrint('데이터베이스 업그레이드: 버전 3 - 성능 최적화 인덱스 추가');
      await _addPerformanceIndexes(db);
    }
    
    // 향후 버전 업그레이드 로직 추가
    if (oldVersion < newVersion && oldVersion >= 3) {
      // 추가 마이그레이션 로직
      debugPrint('추가 마이그레이션 로직 실행 (버전 $oldVersion -> $newVersion)');
    }
  }
  
  /// Phase 5: 성능 최적화 인덱스 추가
  /// 
  /// 기존 데이터베이스에 성능 최적화 인덱스를 추가합니다.
  /// 
  /// [db]: 데이터베이스 인스턴스
  Future<void> _addPerformanceIndexes(Database db) async {
    try {
      // collection_method 인덱스 추가
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_collection_method 
        ON ${BatteryHistoryDatabaseConfig.tableName} (collection_method)
      ''');
      
      // collection_method + timestamp 복합 인덱스 추가
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_collection_method_timestamp 
        ON ${BatteryHistoryDatabaseConfig.tableName} (collection_method, timestamp)
      ''');
      
      debugPrint('성능 최적화 인덱스 추가 완료');
    } catch (e) {
      debugPrint('성능 최적화 인덱스 추가 실패: $e');
      // 인덱스 추가 실패해도 계속 진행 (이미 존재할 수 있음)
    }
  }

  /// 데이터베이스 무결성 검사
  /// 
  /// [db]: 데이터베이스 인스턴스
  Future<void> checkDatabaseIntegrity(Database db) async {
    try {
      final result = await db.rawQuery('PRAGMA integrity_check');
      debugPrint('데이터베이스 무결성 검사 결과: $result');
    } catch (e) {
      debugPrint('데이터베이스 무결성 검사 실패: $e');
    }
  }
}

