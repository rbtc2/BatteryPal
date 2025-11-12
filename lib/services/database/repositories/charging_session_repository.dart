import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

/// 충전 세션 Repository
/// 충전 세션 데이터의 CRUD 작업을 담당합니다.
class ChargingSessionRepository {
  /// 싱글톤 인스턴스
  static final ChargingSessionRepository _instance = ChargingSessionRepository._internal();
  factory ChargingSessionRepository() => _instance;
  ChargingSessionRepository._internal();

  /// 충전 세션 저장
  /// 
  /// [db]: 데이터베이스 인스턴스
  /// [sessionMap]: 저장할 충전 세션 데이터 (Map 형식)
  Future<void> insertChargingSession(
    Database db,
    Map<String, dynamic> sessionMap,
  ) async {
    try {
      // speed_changes를 JSON 문자열로 변환
      final speedChangesJson = sessionMap['speed_changes'];
      if (speedChangesJson is List) {
        sessionMap['speed_changes'] = jsonEncode(speedChangesJson);
      }
      
      await db.insert(
        'charging_sessions',
        sessionMap,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      debugPrint('충전 세션 저장 완료: ${sessionMap['id']}');
    } catch (e, stackTrace) {
      debugPrint('충전 세션 저장 실패: $e');
      debugPrint('스택 트레이스: $stackTrace');
      rethrow;
    }
  }

  /// 여러 충전 세션 일괄 저장
  /// 
  /// [db]: 데이터베이스 인스턴스
  /// [sessionMaps]: 저장할 충전 세션 데이터 리스트 (Map 형식)
  Future<void> insertChargingSessions(
    Database db,
    List<Map<String, dynamic>> sessionMaps,
  ) async {
    if (sessionMaps.isEmpty) return;
    
    try {
      // 트랜잭션을 사용하여 성능 최적화
      await db.transaction((txn) async {
        final batch = txn.batch();
        
        for (final sessionMap in sessionMaps) {
          // speed_changes를 JSON 문자열로 변환
          final speedChangesJson = sessionMap['speed_changes'];
          if (speedChangesJson is List) {
            sessionMap['speed_changes'] = jsonEncode(speedChangesJson);
          }
          
          batch.insert(
            'charging_sessions',
            sessionMap,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        
        await batch.commit();
        debugPrint('${sessionMaps.length}개 충전 세션 일괄 저장 완료 (트랜잭션)');
      });
    } catch (e, stackTrace) {
      debugPrint('충전 세션 일괄 저장 실패: $e');
      debugPrint('스택 트레이스: $stackTrace');
      rethrow;
    }
  }

  /// 특정 날짜의 충전 세션 조회
  /// 
  /// [db]: 데이터베이스 인스턴스
  /// [date]: 조회할 날짜
  /// 
  /// Returns: 충전 세션 데이터 리스트 (speed_changes는 자동으로 파싱됨)
  Future<List<Map<String, dynamic>>> getChargingSessionsByDate(
    Database db,
    DateTime date,
  ) async {
    try {
      // 해당 날짜의 시작 시간 (00:00:00)
      final startOfDay = DateTime(date.year, date.month, date.day);
      // 해당 날짜의 끝 시간 (23:59:59.999)
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
      
      final results = await db.query(
        'charging_sessions',
        where: 'start_time >= ? AND start_time <= ?',
        whereArgs: [startOfDay.millisecondsSinceEpoch, endOfDay.millisecondsSinceEpoch],
        orderBy: 'start_time ASC',
      );
      
      // speed_changes를 JSON에서 파싱
      for (final result in results) {
        if (result['speed_changes'] is String) {
          try {
            result['speed_changes'] = jsonDecode(result['speed_changes'] as String);
          } catch (e) {
            debugPrint('speed_changes JSON 파싱 실패: $e');
            result['speed_changes'] = [];
          }
        }
      }
      
      debugPrint('${results.length}개의 충전 세션 조회 완료 (날짜: ${date.toString().split(' ')[0]})');
      
      return results;
    } catch (e, stackTrace) {
      debugPrint('충전 세션 조회 실패: $e');
      debugPrint('스택 트레이스: $stackTrace');
      rethrow;
    }
  }

  /// 세션 ID로 충전 세션 조회
  /// 
  /// [db]: 데이터베이스 인스턴스
  /// [sessionId]: 조회할 세션 ID
  /// 
  /// Returns: 충전 세션 데이터 (없으면 null, speed_changes는 자동으로 파싱됨)
  Future<Map<String, dynamic>?> getChargingSessionById(
    Database db,
    String sessionId,
  ) async {
    try {
      final results = await db.query(
        'charging_sessions',
        where: 'id = ?',
        whereArgs: [sessionId],
        limit: 1,
      );
      
      if (results.isEmpty) {
        return null;
      }
      
      final result = results.first;
      
      // speed_changes를 JSON에서 파싱
      if (result['speed_changes'] is String) {
        try {
          result['speed_changes'] = jsonDecode(result['speed_changes'] as String);
        } catch (e) {
          debugPrint('speed_changes JSON 파싱 실패: $e');
          result['speed_changes'] = [];
        }
      }
      
      return result;
    } catch (e, stackTrace) {
      debugPrint('충전 세션 ID로 조회 실패: $e');
      debugPrint('스택 트레이스: $stackTrace');
      rethrow;
    }
  }

  /// 오래된 충전 세션 데이터 정리
  /// 
  /// 7일 이상 된 충전 세션 데이터를 삭제합니다.
  /// 
  /// [db]: 데이터베이스 인스턴스
  /// [cutoffDays]: 보관 기간 (일), 기본값 7일
  /// 
  /// Returns: 삭제된 세션 개수
  Future<int> cleanupOldChargingSessions(
    Database db, {
    int cutoffDays = 7,
  }) async {
    final cutoffTime = DateTime.now().subtract(Duration(days: cutoffDays));
    final cutoffTimestamp = cutoffTime.millisecondsSinceEpoch;
    
    try {
      // 삭제 전 행 수 확인
      final beforeCount = await db.rawQuery('''
        SELECT COUNT(*) as count FROM charging_sessions
      ''');
      
      // 7일 이상 된 세션 데이터 삭제
      await db.delete(
        'charging_sessions',
        where: 'start_time < ?',
        whereArgs: [cutoffTimestamp],
      );
      
      // 삭제 후 행 수 확인
      final afterCount = await db.rawQuery('''
        SELECT COUNT(*) as count FROM charging_sessions
      ''');
      
      final before = Sqflite.firstIntValue(beforeCount) ?? 0;
      final after = Sqflite.firstIntValue(afterCount) ?? 0;
      final deletedCount = before - after;
      
      debugPrint('$deletedCount개의 오래된 충전 세션 데이터 정리 완료 ($cutoffDays일 이상)');
      return deletedCount;
    } catch (e, stackTrace) {
      debugPrint('오래된 충전 세션 데이터 정리 실패: $e');
      debugPrint('스택 트레이스: $stackTrace');
      rethrow;
    }
  }
}

