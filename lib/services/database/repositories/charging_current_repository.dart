import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../../../models/battery_history_models.dart';

/// 충전 전류 데이터 Repository
/// 충전 전류 데이터의 저장 및 조회를 담당합니다.
class ChargingCurrentRepository {
  /// 싱글톤 인스턴스
  static final ChargingCurrentRepository _instance = ChargingCurrentRepository._internal();
  factory ChargingCurrentRepository() => _instance;
  ChargingCurrentRepository._internal();

  /// 충전 전류 데이터 포인트 일괄 저장
  /// 
  /// timestamp와 currentMa만 포함된 Map 리스트를 받아서 저장합니다.
  /// 기존 데이터가 있으면 charging_current만 업데이트하고,
  /// 없으면 기본값으로 새 레코드를 생성합니다.
  /// 
  /// [db]: 데이터베이스 인스턴스
  /// [points]: timestamp와 currentMa를 포함한 Map 리스트
  /// 
  /// Returns: 저장된 데이터의 ID 리스트
  Future<List<int>> insertChargingCurrentPoints(
    Database db,
    List<Map<String, dynamic>> points,
  ) async {
    if (points.isEmpty) return [];
    
    try {
      // 트랜잭션을 사용하여 성능 최적화
      return await db.transaction((txn) async {
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

  /// 특정 날짜의 충전 전류 데이터 조회
  /// 
  /// 날짜별로 그룹화하여 timestamp와 charging_current를 반환합니다.
  /// 같은 시간(분 단위)의 포인트는 더 높은 전류 값을 가진 것으로 선택합니다.
  /// 
  /// [db]: 데이터베이스 인스턴스
  /// [date]: 조회할 날짜
  /// 
  /// Returns: timestamp와 currentMa를 포함한 Map 리스트
  Future<List<Map<String, dynamic>>> getChargingCurrentDataByDate(
    Database db,
    DateTime date,
  ) async {
    try {
      // 해당 날짜의 시작 시간 (00:00:00)
      final startOfDay = DateTime(date.year, date.month, date.day);
      // 해당 날짜의 끝 시간 (23:59:59.999)
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
      
      final results = await db.query(
        BatteryHistoryDatabaseConfig.tableName,
        columns: ['timestamp', 'charging_current'],
        where: 'timestamp >= ? AND timestamp <= ?',
        whereArgs: [startOfDay.millisecondsSinceEpoch, endOfDay.millisecondsSinceEpoch],
        orderBy: 'timestamp ASC',
      );
      
      // 결과를 Map 형식으로 변환하고, 같은 시간(분 단위)의 포인트는 하나만 사용
      final timeMap = <String, Map<String, dynamic>>{}; // "YYYY-MM-DD HH:MM" -> data
      
      for (final row in results) {
        final timestamp = DateTime.fromMillisecondsSinceEpoch(row['timestamp'] as int);
        final timeKey = '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
        
        // 같은 분 단위의 데이터가 있으면, 더 높은 전류 값을 가진 것으로 교체
        if (!timeMap.containsKey(timeKey) || 
            (row['charging_current'] as int) > timeMap[timeKey]!['currentMa']) {
          timeMap[timeKey] = {
            'timestamp': timestamp,
            'currentMa': row['charging_current'] as int,
          };
        }
      }
      
      final data = timeMap.values.toList()
        ..sort((a, b) => (a['timestamp'] as DateTime).compareTo(b['timestamp'] as DateTime));
      
      debugPrint('${data.length}개의 충전 전류 데이터 조회 완료 (날짜: ${date.toString().split(' ')[0]})');
      
      return data;
    } catch (e, stackTrace) {
      debugPrint('충전 전류 데이터 조회 실패: $e');
      debugPrint('스택 트레이스: $stackTrace');
      rethrow;
    }
  }
}

