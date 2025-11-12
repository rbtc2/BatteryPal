import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../../../models/battery_history_models.dart';

/// 데이터 정리 서비스
/// 오래된 데이터를 정리하고 자동 정리 스케줄을 관리합니다.
class DataCleanupService {
  /// 싱글톤 인스턴스
  static final DataCleanupService _instance = DataCleanupService._internal();
  factory DataCleanupService() => _instance;
  DataCleanupService._internal();


  /// 오래된 배터리 데이터 정리
  /// 
  /// [db]: 데이터베이스 인스턴스
  /// [retentionDays]: 보관 기간 (일), 기본값은 설정값 사용
  /// 
  /// Returns: 삭제된 데이터 개수
  Future<int> cleanupOldData(
    Database db, {
    int? retentionDays,
  }) async {
    final days = retentionDays ?? BatteryHistoryDatabaseConfig.dataRetentionDays;
    final cutoffTime = DateTime.now().subtract(Duration(days: days));
    
    try {
      final deletedCount = await db.delete(
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

  /// 충전 전류 데이터만 정리 (7일 이상 된 데이터 삭제)
  /// 
  /// 그래프용 충전 전류 데이터는 7일만 보관합니다.
  /// 
  /// [db]: 데이터베이스 인스턴스
  /// 
  /// Returns: 삭제된 데이터 개수
  Future<int> cleanupOldChargingCurrentData(Database db) async {
    final cutoffDays = BatteryHistoryDatabaseConfig.chargingCurrentRetentionDays;
    final cutoffTime = DateTime.now().subtract(Duration(days: cutoffDays));
    final cutoffTimestamp = cutoffTime.millisecondsSinceEpoch;
    
    try {
      // 삭제 전 행 수 확인
      final beforeCount = await db.rawQuery('''
        SELECT COUNT(*) as count FROM ${BatteryHistoryDatabaseConfig.tableName}
        WHERE charging_current > 0
      ''');
      
      // 충전 전류 데이터만 삭제 (charging_current가 0이 아닌 데이터 중에서 오래된 것)
      await db.delete(
        BatteryHistoryDatabaseConfig.tableName,
        where: 'timestamp < ? AND charging_current > 0',
        whereArgs: [cutoffTimestamp],
      );
      
      // 삭제 후 행 수 확인
      final afterCount = await db.rawQuery('''
        SELECT COUNT(*) as count FROM ${BatteryHistoryDatabaseConfig.tableName}
        WHERE charging_current > 0
      ''');
      
      final before = Sqflite.firstIntValue(beforeCount) ?? 0;
      final after = Sqflite.firstIntValue(afterCount) ?? 0;
      final deletedCount = before - after;
      
      debugPrint('$deletedCount개의 오래된 충전 전류 데이터 정리 완료 ($cutoffDays일 이상)');
      return deletedCount;
    } catch (e, stackTrace) {
      debugPrint('오래된 충전 전류 데이터 정리 실패: $e');
      debugPrint('스택 트레이스: $stackTrace');
      rethrow;
    }
  }


  /// 자동 정리 스케줄링 시작
  /// 
  /// [db]: 데이터베이스 인스턴스
  /// [cleanupOldDataCallback]: 전체 데이터 정리 콜백
  /// [cleanupChargingCurrentDataCallback]: 충전 전류 데이터 정리 콜백
  void scheduleAutoCleanup(
    Database db, {
    required Future<int> Function() cleanupOldDataCallback,
    required Future<int> Function() cleanupChargingCurrentDataCallback,
  }) {
    // 매일 자정에 충전 전류 데이터 정리 실행
    _scheduleDailyCleanup(cleanupChargingCurrentDataCallback);
    
    // 일주일마다 전체 데이터 정리 실행
    Timer.periodic(
      Duration(days: BatteryHistoryDatabaseConfig.autoCleanupIntervalDays),
      (timer) async {
        try {
          await cleanupOldDataCallback();
        } catch (e) {
          debugPrint('자동 정리 실패: $e');
        }
      },
    );
  }

  /// 매일 자정에 실행되는 충전 전류 데이터 정리 스케줄링
  /// 
  /// [cleanupCallback]: 충전 전류 데이터 정리 콜백
  void _scheduleDailyCleanup(Future<int> Function() cleanupCallback) {
    // 다음 자정 시간 계산
    final now = DateTime.now();
    final tomorrow = DateTime(
      now.year,
      now.month,
      now.day + 1,
      BatteryHistoryDatabaseConfig.dailyCleanupHour,
    );
    final durationUntilMidnight = tomorrow.difference(now);
    
    // 다음 자정까지 대기 후 실행
    Timer(durationUntilMidnight, () {
      // 매일 자정에 실행
      Timer.periodic(Duration(days: 1), (timer) async {
        try {
          debugPrint('일별 충전 전류 데이터 정리 실행 (${DateTime.now()})');
          await cleanupCallback();
        } catch (e) {
          debugPrint('일별 충전 전류 데이터 정리 실패: $e');
        }
      });
      
      // 첫 실행은 즉시
      Timer(Duration(seconds: 1), () async {
        try {
          debugPrint('초기 충전 전류 데이터 정리 실행');
          await cleanupCallback();
        } catch (e) {
          debugPrint('초기 충전 전류 데이터 정리 실패: $e');
        }
      });
    });
  }
}

