import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'database_path_manager.dart';
import 'schema_manager.dart';
import '../../models/battery_history_models.dart';

/// 데이터베이스 연결 및 초기화 관리 클래스
/// 데이터베이스의 생명주기를 관리하고 초기화 상태를 추적합니다.
class DatabaseManager {
  /// 싱글톤 인스턴스
  static final DatabaseManager _instance = DatabaseManager._internal();
  factory DatabaseManager() => _instance;
  DatabaseManager._internal();

  final DatabasePathManager _pathManager = DatabasePathManager();
  final SchemaManager _schemaManager = SchemaManager();

  Database? _database;
  bool _isInitialized = false;
  final Completer<void> _initCompleter = Completer<void>();

  /// 데이터베이스 인스턴스 반환
  Database? get database => _database;
  
  /// 초기화 완료 여부
  bool get isInitialized => _isInitialized;
  
  /// 초기화 완료 대기
  Future<void> get initialization => _initCompleter.future;

  /// 데이터베이스 초기화
  /// 
  /// 데이터베이스를 열거나 생성하고, 스키마를 설정합니다.
  /// 이미 초기화된 경우 즉시 반환합니다.
  /// 
  /// Throws: 데이터베이스 초기화 실패 시 예외 발생
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      debugPrint('배터리 히스토리 데이터베이스 초기화 시작...');
      
      // 데이터베이스 경로 설정
      final databasePath = await _pathManager.getDatabasePath();
      debugPrint('데이터베이스 경로: $databasePath');
      
      // 데이터베이스 열기 또는 생성
      _database = await openDatabase(
        databasePath,
        version: BatteryHistoryDatabaseConfig.databaseVersion,
        onCreate: _schemaManager.onCreate,
        onUpgrade: _schemaManager.onUpgrade,
        onOpen: _onOpen,
      );
      
      _isInitialized = true;
      _initCompleter.complete();
      
      debugPrint('배터리 히스토리 데이터베이스 초기화 완료');
      
    } catch (e, stackTrace) {
      debugPrint('데이터베이스 초기화 실패: $e');
      debugPrint('스택 트레이스: $stackTrace');
      _initCompleter.completeError(e);
      rethrow;
    }
  }

  /// 데이터베이스 열기 시 실행되는 콜백
  /// 
  /// 데이터베이스 무결성을 검사합니다.
  /// 
  /// [db]: 데이터베이스 인스턴스
  Future<void> _onOpen(Database db) async {
    debugPrint('데이터베이스 열기 완료');
    
    // 데이터베이스 무결성 검사
    await _schemaManager.checkDatabaseIntegrity(db);
  }

  /// 데이터베이스 닫기
  /// 
  /// 데이터베이스 연결을 종료하고 상태를 초기화합니다.
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
      _isInitialized = false;
      debugPrint('배터리 히스토리 데이터베이스 닫기 완료');
    }
  }

  /// 데이터베이스 재초기화
  /// 
  /// 기존 연결을 닫고 새로 초기화합니다.
  /// 주의: 이 메서드는 기존 Completer를 재사용하지 않으므로,
  /// 완전히 새로운 초기화를 수행합니다.
  Future<void> reinitialize() async {
    await close();
    _initCompleter.complete(); // 기존 완료 상태 해제를 위해
    // 새로운 Completer 생성은 initialize에서 처리
    await initialize();
  }
}

