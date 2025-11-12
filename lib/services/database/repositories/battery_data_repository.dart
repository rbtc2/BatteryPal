import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:battery_plus/battery_plus.dart';
import '../../../models/battery_history_models.dart';

/// 배터리 데이터 Repository
/// 배터리 히스토리 데이터 포인트의 CRUD 작업을 담당합니다.
class BatteryDataRepository {
  /// 싱글톤 인스턴스
  static final BatteryDataRepository _instance = BatteryDataRepository._internal();
  factory BatteryDataRepository() => _instance;
  BatteryDataRepository._internal();

  /// 배터리 히스토리 데이터 포인트 저장
  /// 
  /// [db]: 데이터베이스 인스턴스
  /// [dataPoint]: 저장할 배터리 데이터 포인트
  /// 
  /// Returns: 저장된 데이터의 ID
  Future<int> insertBatteryDataPoint(
    Database db,
    BatteryHistoryDataPoint dataPoint,
  ) async {
    try {
      final id = await db.insert(
        BatteryHistoryDatabaseConfig.tableName,
        _dataPointToMap(dataPoint),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      debugPrint('배터리 데이터 포인트 저장 완료: ID $id');
      return id;
    } catch (e, stackTrace) {
      debugPrint('배터리 데이터 포인트 저장 실패: $e');
      debugPrint('스택 트레이스: $stackTrace');
      rethrow;
    }
  }

  /// 여러 배터리 히스토리 데이터 포인트 일괄 저장 (성능 최적화)
  /// 
  /// [db]: 데이터베이스 인스턴스
  /// [dataPoints]: 저장할 배터리 데이터 포인트 리스트
  /// 
  /// Returns: 저장된 데이터의 ID 리스트
  Future<List<int>> insertBatteryDataPoints(
    Database db,
    List<BatteryHistoryDataPoint> dataPoints,
  ) async {
    if (dataPoints.isEmpty) return [];
    
    try {
      // 트랜잭션을 사용하여 성능 최적화
      return await db.transaction((txn) async {
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

  /// 특정 기간의 배터리 히스토리 데이터 조회
  /// 
  /// [db]: 데이터베이스 인스턴스
  /// [startTime]: 시작 시간 (옵션)
  /// [endTime]: 종료 시간 (옵션)
  /// [limit]: 조회할 최대 개수 (옵션)
  /// [offset]: 오프셋 (옵션)
  /// [orderByTimestampDesc]: 타임스탬프 내림차순 정렬 여부
  /// 
  /// Returns: 배터리 히스토리 데이터 포인트 리스트
  Future<List<BatteryHistoryDataPoint>> getBatteryHistoryData(
    Database db, {
    DateTime? startTime,
    DateTime? endTime,
    int? limit,
    int? offset,
    bool orderByTimestampDesc = false,
  }) async {
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
      
      final results = await db.query(
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
  /// 
  /// [db]: 데이터베이스 인스턴스
  /// [count]: 조회할 개수
  /// 
  /// Returns: 배터리 히스토리 데이터 포인트 리스트
  Future<List<BatteryHistoryDataPoint>> getRecentBatteryHistoryData(
    Database db,
    int count,
  ) async {
    return getBatteryHistoryData(
      db,
      limit: count,
      orderByTimestampDesc: true,
    );
  }

  /// 특정 기간의 배터리 통계 조회
  /// 
  /// [db]: 데이터베이스 인스턴스
  /// [startTime]: 시작 시간 (옵션)
  /// [endTime]: 종료 시간 (옵션)
  /// 
  /// Returns: 배터리 통계 맵
  Future<Map<String, dynamic>> getBatteryStatistics(
    Database db, {
    DateTime? startTime,
    DateTime? endTime,
  }) async {
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
      
      final result = await db.rawQuery('''
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
  /// 
  /// [db]: 데이터베이스 인스턴스
  /// 
  /// Returns: 데이터 포인트 개수
  Future<int> getDataPointCount(Database db) async {
    try {
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM ${BatteryHistoryDatabaseConfig.tableName}'
      );
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      debugPrint('데이터 포인트 수 조회 실패: $e');
      return 0;
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

