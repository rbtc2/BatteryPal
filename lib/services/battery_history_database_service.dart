import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:battery_plus/battery_plus.dart';
import '../models/battery_history_models.dart';

/// 배터리 히스토리 데이터베이스 서비스
/// SQLite를 사용한 로컬 데이터 저장 및 관리
class BatteryHistoryDatabaseService {
  static final BatteryHistoryDatabaseService _instance = 
      BatteryHistoryDatabaseService._internal();
  factory BatteryHistoryDatabaseService() => _instance;
  BatteryHistoryDatabaseService._internal();

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
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      debugPrint('배터리 히스토리 데이터베이스 초기화 시작...');
      
      // 데이터베이스 경로 설정
      final databasePath = await _getDatabasePath();
      debugPrint('데이터베이스 경로: $databasePath');
      
      // 데이터베이스 열기 또는 생성
      _database = await openDatabase(
        databasePath,
        version: BatteryHistoryDatabaseConfig.databaseVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onOpen: _onOpen,
      );
      
      _isInitialized = true;
      _initCompleter.complete();
      
      debugPrint('배터리 히스토리 데이터베이스 초기화 완료');
      
      // 초기화 후 자동 정리 실행
      _scheduleAutoCleanup();
      
    } catch (e, stackTrace) {
      debugPrint('데이터베이스 초기화 실패: $e');
      debugPrint('스택 트레이스: $stackTrace');
      _initCompleter.completeError(e);
      rethrow;
    }
  }

  /// 데이터베이스 경로 가져오기
  Future<String> _getDatabasePath() async {
    if (Platform.isAndroid || Platform.isIOS) {
      // 모바일 플랫폼
      final documentsDirectory = await getApplicationDocumentsDirectory();
      return join(documentsDirectory.path, BatteryHistoryDatabaseConfig.databaseName);
    } else {
      // 데스크톱 플랫폼
      final documentsDirectory = await getApplicationDocumentsDirectory();
      return join(documentsDirectory.path, BatteryHistoryDatabaseConfig.databaseName);
    }
  }

  /// 데이터베이스 생성 시 실행
  Future<void> _onCreate(Database db, int version) async {
    debugPrint('데이터베이스 테이블 생성 시작...');
    
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
    
    // 데이터 품질 인덱스
    await db.execute('''
      CREATE INDEX idx_data_quality ON ${BatteryHistoryDatabaseConfig.tableName} (data_quality)
    ''');
    
    debugPrint('데이터베이스 테이블 생성 완료');
  }

  /// 데이터베이스 업그레이드 시 실행
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    debugPrint('데이터베이스 업그레이드: $oldVersion -> $newVersion');
    
    // 향후 버전 업그레이드 로직 추가
    if (oldVersion < newVersion) {
      // 마이그레이션 로직 구현
    }
  }

  /// 데이터베이스 열기 시 실행
  Future<void> _onOpen(Database db) async {
    debugPrint('데이터베이스 열기 완료');
    
    // 데이터베이스 무결성 검사
    await _checkDatabaseIntegrity();
  }

  /// 데이터베이스 무결성 검사
  Future<void> _checkDatabaseIntegrity() async {
    if (_database == null) return;
    
    try {
      final result = await _database!.rawQuery('PRAGMA integrity_check');
      debugPrint('데이터베이스 무결성 검사 결과: $result');
    } catch (e) {
      debugPrint('데이터베이스 무결성 검사 실패: $e');
    }
  }

  /// 배터리 히스토리 데이터 포인트 저장
  Future<int> insertBatteryDataPoint(BatteryHistoryDataPoint dataPoint) async {
    await initialization;
    if (_database == null) throw Exception('데이터베이스가 초기화되지 않았습니다');
    
    try {
      final id = await _database!.insert(
        BatteryHistoryDatabaseConfig.tableName,
        _dataPointToMap(dataPoint),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      debugPrint('배터리 데이터 포인트 저장 완료: ID $id');
      
      // 데이터 포인트 수가 임계값을 초과하면 압축 실행
      await _checkAndCompressData();
      
      return id;
    } catch (e, stackTrace) {
      debugPrint('배터리 데이터 포인트 저장 실패: $e');
      debugPrint('스택 트레이스: $stackTrace');
      rethrow;
    }
  }

  /// 여러 배터리 히스토리 데이터 포인트 일괄 저장 (성능 최적화)
  Future<List<int>> insertBatteryDataPoints(List<BatteryHistoryDataPoint> dataPoints) async {
    await initialization;
    if (_database == null) throw Exception('데이터베이스가 초기화되지 않았습니다');
    
    if (dataPoints.isEmpty) return [];
    
    try {
      // 트랜잭션을 사용하여 성능 최적화
      return await _database!.transaction((txn) async {
        final batch = txn.batch();
        
        for (final dataPoint in dataPoints) {
          batch.insert(
            BatteryHistoryDatabaseConfig.tableName,
            _dataPointToMap(dataPoint),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        
        final results = await batch.commit();
        debugPrint('${dataPoints.length}개 배터리 데이터 포인트 일괄 저장 완료 (트랜잭션)');
        
        return results.cast<int>();
      });
    } catch (e, stackTrace) {
      debugPrint('배터리 데이터 포인트 일괄 저장 실패: $e');
      debugPrint('스택 트레이스: $stackTrace');
      rethrow;
    }
  }

  /// 충전 전류 데이터 포인트 일괄 저장
  /// timestamp와 currentMa만 포함된 Map 리스트를 받아서 저장
  /// 기존 데이터가 있으면 charging_current만 업데이트, 없으면 기본값으로 새 레코드 생성
  Future<List<int>> insertChargingCurrentPoints(List<Map<String, dynamic>> points) async {
    await initialization;
    if (_database == null) throw Exception('데이터베이스가 초기화되지 않았습니다');
    
    if (points.isEmpty) return [];
    
    try {
      // 트랜잭션을 사용하여 성능 최적화
      return await _database!.transaction((txn) async {
        final batch = txn.batch();
        
        for (final point in points) {
          final timestamp = point['timestamp'] as DateTime;
          final currentMa = point['currentMa'] as int;
          final timestampMs = timestamp.millisecondsSinceEpoch;
          
          // 해당 timestamp에 대한 기존 데이터 확인
          final existing = await txn.query(
            BatteryHistoryDatabaseConfig.tableName,
            where: 'timestamp = ?',
            whereArgs: [timestampMs],
            limit: 1,
          );
          
          if (existing.isNotEmpty) {
            // 기존 데이터가 있으면 charging_current만 업데이트
            batch.update(
              BatteryHistoryDatabaseConfig.tableName,
              {'charging_current': currentMa},
              where: 'timestamp = ?',
              whereArgs: [timestampMs],
            );
          } else {
            // 기존 데이터가 없으면 최근 배터리 데이터를 조회하여 기본값으로 사용
            final recentData = await txn.query(
              BatteryHistoryDatabaseConfig.tableName,
              orderBy: 'timestamp DESC',
              limit: 1,
            );
            
            Map<String, dynamic> dataMap;
            if (recentData.isNotEmpty) {
              // 최근 데이터를 복사하여 사용
              final recent = recentData.first;
              dataMap = Map<String, dynamic>.from(recent);
              dataMap['id'] = null; // 새 레코드이므로 ID는 null
              dataMap['timestamp'] = timestampMs;
              dataMap['charging_current'] = currentMa;
              dataMap['is_charging'] = currentMa > 0 ? 1 : 0;
              dataMap['created_at'] = DateTime.now().millisecondsSinceEpoch ~/ 1000;
            } else {
              // 최근 데이터도 없으면 기본값으로 생성
              dataMap = {
                'timestamp': timestampMs,
                'level': 0.0,
                'state': 0, // BatteryState.unknown
                'temperature': -1.0,
                'voltage': -1,
                'capacity': -1,
                'health': -1,
                'charging_type': 'Unknown',
                'charging_current': currentMa,
                'is_charging': currentMa > 0 ? 1 : 0,
                'is_app_in_foreground': 1,
                'collection_method': 'automatic',
                'data_quality': 0.5,
                'created_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
              };
            }
            
            batch.insert(
              BatteryHistoryDatabaseConfig.tableName,
              dataMap,
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        }
        
        final results = await batch.commit();
        debugPrint('${points.length}개 충전 전류 데이터 포인트 일괄 저장 완료 (트랜잭션)');
        
        return results.whereType<int>().toList();
      });
    } catch (e, stackTrace) {
      debugPrint('충전 전류 데이터 포인트 일괄 저장 실패: $e');
      debugPrint('스택 트레이스: $stackTrace');
      rethrow;
    }
  }

  /// 특정 기간의 배터리 히스토리 데이터 조회
  Future<List<BatteryHistoryDataPoint>> getBatteryHistoryData({
    DateTime? startTime,
    DateTime? endTime,
    int? limit,
    int? offset,
    bool orderByTimestampDesc = false,
  }) async {
    await initialization;
    if (_database == null) throw Exception('데이터베이스가 초기화되지 않았습니다');
    
    try {
      String whereClause = '';
      List<dynamic> whereArgs = [];
      
      if (startTime != null) {
        whereClause += 'timestamp >= ?';
        whereArgs.add(startTime.millisecondsSinceEpoch);
      }
      
      if (endTime != null) {
        if (whereClause.isNotEmpty) whereClause += ' AND ';
        whereClause += 'timestamp <= ?';
        whereArgs.add(endTime.millisecondsSinceEpoch);
      }
      
      String orderBy = orderByTimestampDesc ? 'timestamp DESC' : 'timestamp ASC';
      
      final results = await _database!.query(
        BatteryHistoryDatabaseConfig.tableName,
        where: whereClause.isNotEmpty ? whereClause : null,
        whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
        orderBy: orderBy,
        limit: limit,
        offset: offset,
      );
      
      final dataPoints = results.map((row) => _mapToDataPoint(row)).toList();
      debugPrint('${dataPoints.length}개 배터리 히스토리 데이터 조회 완료');
      
      return dataPoints;
    } catch (e, stackTrace) {
      debugPrint('배터리 히스토리 데이터 조회 실패: $e');
      debugPrint('스택 트레이스: $stackTrace');
      rethrow;
    }
  }

  /// 최근 N개의 배터리 히스토리 데이터 조회
  Future<List<BatteryHistoryDataPoint>> getRecentBatteryHistoryData(int count) async {
    return getBatteryHistoryData(
      limit: count,
      orderByTimestampDesc: true,
    );
  }

  /// 특정 날짜의 충전 전류 데이터 조회
  /// 날짜별로 그룹화하여 timestamp와 charging_current를 반환
  Future<List<Map<String, dynamic>>> getChargingCurrentDataByDate(DateTime date) async {
    await initialization;
    if (_database == null) throw Exception('데이터베이스가 초기화되지 않았습니다');
    
    try {
      // 해당 날짜의 시작 시간 (00:00:00)
      final startOfDay = DateTime(date.year, date.month, date.day);
      // 해당 날짜의 끝 시간 (23:59:59.999)
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
      
      final results = await _database!.query(
        BatteryHistoryDatabaseConfig.tableName,
        columns: ['timestamp', 'charging_current'],
        where: 'timestamp >= ? AND timestamp <= ?',
        whereArgs: [startOfDay.millisecondsSinceEpoch, endOfDay.millisecondsSinceEpoch],
        orderBy: 'timestamp ASC',
      );
      
      // 결과를 Map 형식으로 변환 (timestamp는 DateTime으로, charging_current는 currentMa로)
      final data = results.map((row) => <String, dynamic>{
        'timestamp': DateTime.fromMillisecondsSinceEpoch(row['timestamp'] as int),
        'currentMa': row['charging_current'] as int,
      }).toList();
      
      debugPrint('${data.length}개의 충전 전류 데이터 조회 완료 (날짜: ${date.toString().split(' ')[0]})');
      
      return data;
    } catch (e, stackTrace) {
      debugPrint('충전 전류 데이터 조회 실패: $e');
      debugPrint('스택 트레이스: $stackTrace');
      rethrow;
    }
  }

  /// 특정 기간의 배터리 통계 조회
  Future<Map<String, dynamic>> getBatteryStatistics({
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    await initialization;
    if (_database == null) throw Exception('데이터베이스가 초기화되지 않았습니다');
    
    try {
      String whereClause = '';
      List<dynamic> whereArgs = [];
      
      if (startTime != null) {
        whereClause += 'timestamp >= ?';
        whereArgs.add(startTime.millisecondsSinceEpoch);
      }
      
      if (endTime != null) {
        if (whereClause.isNotEmpty) whereClause += ' AND ';
        whereClause += 'timestamp <= ?';
        whereArgs.add(endTime.millisecondsSinceEpoch);
      }
      
      final result = await _database!.rawQuery('''
        SELECT 
          COUNT(*) as count,
          AVG(level) as avg_level,
          MIN(level) as min_level,
          MAX(level) as max_level,
          AVG(temperature) as avg_temperature,
          AVG(data_quality) as avg_quality,
          SUM(CASE WHEN is_charging = 1 THEN 1 ELSE 0 END) as charging_count
        FROM ${BatteryHistoryDatabaseConfig.tableName}
        ${whereClause.isNotEmpty ? 'WHERE $whereClause' : ''}
      ''', whereArgs);
      
      if (result.isEmpty) {
        return {
          'count': 0,
          'avg_level': 0.0,
          'min_level': 0.0,
          'max_level': 0.0,
          'avg_temperature': 0.0,
          'avg_quality': 0.0,
          'charging_count': 0,
        };
      }
      
      return result.first;
    } catch (e, stackTrace) {
      debugPrint('배터리 통계 조회 실패: $e');
      debugPrint('스택 트레이스: $stackTrace');
      rethrow;
    }
  }

  /// 데이터 포인트 수 조회
  Future<int> getDataPointCount() async {
    await initialization;
    if (_database == null) throw Exception('데이터베이스가 초기화되지 않았습니다');
    
    try {
      final result = await _database!.rawQuery(
        'SELECT COUNT(*) as count FROM ${BatteryHistoryDatabaseConfig.tableName}'
      );
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      debugPrint('데이터 포인트 수 조회 실패: $e');
      return 0;
    }
  }

  /// 오래된 데이터 정리
  Future<int> cleanupOldData({int? retentionDays}) async {
    await initialization;
    if (_database == null) throw Exception('데이터베이스가 초기화되지 않았습니다');
    
    final days = retentionDays ?? BatteryHistoryDatabaseConfig.dataRetentionDays;
    final cutoffTime = DateTime.now().subtract(Duration(days: days));
    
    try {
      final deletedCount = await _database!.delete(
        BatteryHistoryDatabaseConfig.tableName,
        where: 'timestamp < ?',
        whereArgs: [cutoffTime.millisecondsSinceEpoch],
      );
      
      debugPrint('$deletedCount개의 오래된 데이터 정리 완료');
      return deletedCount;
    } catch (e, stackTrace) {
      debugPrint('오래된 데이터 정리 실패: $e');
      debugPrint('스택 트레이스: $stackTrace');
      rethrow;
    }
  }

  /// 데이터 압축 (중복 데이터 제거)
  Future<int> compressData() async {
    await initialization;
    if (_database == null) throw Exception('데이터베이스가 초기화되지 않았습니다');
    
    try {
      // 시간순으로 정렬하여 중복 제거
      await _database!.rawQuery('''
        DELETE FROM ${BatteryHistoryDatabaseConfig.tableName}
        WHERE id NOT IN (
          SELECT MIN(id)
          FROM ${BatteryHistoryDatabaseConfig.tableName}
          GROUP BY timestamp, level, state
        )
      ''');
      
      debugPrint('데이터 압축 완료');
      return 0; // SQLite에서는 영향받은 행 수를 직접 반환하지 않음
    } catch (e, stackTrace) {
      debugPrint('데이터 압축 실패: $e');
      debugPrint('스택 트레이스: $stackTrace');
      rethrow;
    }
  }

  /// 데이터 압축 필요 여부 확인 및 실행
  Future<void> _checkAndCompressData() async {
    final count = await getDataPointCount();
    if (count > BatteryHistoryDatabaseConfig.compressionThreshold) {
      await compressData();
    }
  }

  /// 자동 정리 스케줄링
  void _scheduleAutoCleanup() {
    Timer.periodic(
      Duration(days: BatteryHistoryDatabaseConfig.autoCleanupIntervalDays),
      (timer) async {
        try {
          await cleanupOldData();
        } catch (e) {
          debugPrint('자동 정리 실패: $e');
        }
      },
    );
  }

  /// 데이터베이스 백업
  Future<String> backupDatabase() async {
    await initialization;
    if (_database == null) throw Exception('데이터베이스가 초기화되지 않았습니다');
    
    try {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final backupPath = join(
        documentsDirectory.path,
        'battery_history_backup_${DateTime.now().millisecondsSinceEpoch}.db'
      );
      
      final databasePath = await _getDatabasePath();
      await File(databasePath).copy(backupPath);
      
      debugPrint('데이터베이스 백업 완료: $backupPath');
      return backupPath;
    } catch (e, stackTrace) {
      debugPrint('데이터베이스 백업 실패: $e');
      debugPrint('스택 트레이스: $stackTrace');
      rethrow;
    }
  }

  /// 데이터베이스 복원
  Future<void> restoreDatabase(String backupPath) async {
    await initialization;
    if (_database == null) throw Exception('데이터베이스가 초기화되지 않았습니다');
    
    try {
      await _database!.close();
      
      final databasePath = await _getDatabasePath();
      await File(backupPath).copy(databasePath);
      
      await initialize();
      
      debugPrint('데이터베이스 복원 완료: $backupPath');
    } catch (e, stackTrace) {
      debugPrint('데이터베이스 복원 실패: $e');
      debugPrint('스택 트레이스: $stackTrace');
      rethrow;
    }
  }

  /// 데이터베이스 닫기
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
      _isInitialized = false;
      debugPrint('배터리 히스토리 데이터베이스 닫기 완료');
    }
  }

  /// 데이터 포인트를 Map으로 변환
  Map<String, dynamic> _dataPointToMap(BatteryHistoryDataPoint dataPoint) {
    return {
      'id': dataPoint.id,
      'timestamp': dataPoint.timestamp.millisecondsSinceEpoch,
      'level': dataPoint.level,
      'state': dataPoint.state.index,
      'temperature': dataPoint.temperature,
      'voltage': dataPoint.voltage,
      'capacity': dataPoint.capacity,
      'health': dataPoint.health,
      'charging_type': dataPoint.chargingType,
      'charging_current': dataPoint.chargingCurrent,
      'is_charging': dataPoint.isCharging ? 1 : 0,
      'is_app_in_foreground': dataPoint.isAppInForeground ? 1 : 0,
      'collection_method': dataPoint.collectionMethod,
      'data_quality': dataPoint.dataQuality,
    };
  }

  /// Map을 데이터 포인트로 변환
  BatteryHistoryDataPoint _mapToDataPoint(Map<String, dynamic> map) {
    return BatteryHistoryDataPoint(
      id: map['id'] as int?,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      level: map['level'] as double,
      state: BatteryState.values[map['state'] as int],
      temperature: map['temperature'] as double,
      voltage: map['voltage'] as int,
      capacity: map['capacity'] as int,
      health: map['health'] as int,
      chargingType: map['charging_type'] as String,
      chargingCurrent: map['charging_current'] as int,
      isCharging: (map['is_charging'] as int) == 1,
      isAppInForeground: (map['is_app_in_foreground'] as int) == 1,
      collectionMethod: map['collection_method'] as String,
      dataQuality: map['data_quality'] as double,
    );
  }
}
