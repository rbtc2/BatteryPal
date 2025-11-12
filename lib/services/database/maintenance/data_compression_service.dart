import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../../../models/battery_history_models.dart';
import '../repositories/battery_data_repository.dart';

/// 데이터 압축 서비스
/// 중복 데이터를 제거하여 데이터베이스 크기를 최적화합니다.
class DataCompressionService {
  /// 싱글톤 인스턴스
  static final DataCompressionService _instance = DataCompressionService._internal();
  factory DataCompressionService() => _instance;
  DataCompressionService._internal();

  final BatteryDataRepository _batteryDataRepository = BatteryDataRepository();

  /// 데이터 압축 (중복 데이터 제거)
  /// 
  /// timestamp, level, state가 동일한 데이터 중에서 가장 오래된 것만 남기고 나머지를 삭제합니다.
  /// 
  /// [db]: 데이터베이스 인스턴스
  /// 
  /// Returns: 압축 완료 (SQLite에서는 영향받은 행 수를 직접 반환하지 않음)
  Future<int> compressData(Database db) async {
    try {
      // 시간순으로 정렬하여 중복 제거
      await db.rawQuery('''
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
  /// 
  /// 데이터 포인트 수가 임계값을 초과하면 자동으로 압축을 실행합니다.
  /// 
  /// [db]: 데이터베이스 인스턴스
  Future<void> checkAndCompressData(Database db) async {
    try {
      final count = await _batteryDataRepository.getDataPointCount(db);
      if (count > BatteryHistoryDatabaseConfig.compressionThreshold) {
        await compressData(db);
      }
    } catch (e) {
      debugPrint('데이터 압축 확인 실패: $e');
    }
  }
}

