import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

/// Phase 5: 데이터베이스 성능 최적화 서비스
/// 
/// 주기적으로 데이터베이스 성능을 최적화합니다:
/// - 인덱스 재구성
/// - 통계 정보 업데이트
/// - VACUUM 실행 (공간 회수)
class PerformanceOptimizer {
  /// 싱글톤 인스턴스
  static final PerformanceOptimizer _instance = PerformanceOptimizer._internal();
  factory PerformanceOptimizer() => _instance;
  PerformanceOptimizer._internal();

  DateTime? _lastOptimizationTime;
  static const Duration _optimizationInterval = Duration(days: 7); // 7일마다 최적화

  /// 데이터베이스 성능 최적화 실행
  /// 
  /// [db]: 데이터베이스 인스턴스
  /// [force]: 강제 실행 여부 (기본값: false)
  /// 
  /// Returns: 최적화 성공 여부
  Future<bool> optimizeDatabase(Database db, {bool force = false}) async {
    try {
      // 마지막 최적화 시간 확인
      if (!force && _lastOptimizationTime != null) {
        final timeSinceLastOptimization = DateTime.now().difference(_lastOptimizationTime!);
        if (timeSinceLastOptimization < _optimizationInterval) {
          debugPrint('PerformanceOptimizer: 최적화 간격이 충족되지 않음 (${timeSinceLastOptimization.inDays}일 경과)');
          return false;
        }
      }

      debugPrint('PerformanceOptimizer: 데이터베이스 성능 최적화 시작...');

      // 1. 통계 정보 업데이트 (쿼리 최적화를 위해)
      await db.execute('ANALYZE');
      debugPrint('PerformanceOptimizer: 통계 정보 업데이트 완료');

      // 2. 인덱스 재구성 (REINDEX)
      await db.execute('REINDEX');
      debugPrint('PerformanceOptimizer: 인덱스 재구성 완료');

      // 3. VACUUM 실행 (공간 회수 및 조각 모음)
      // 주의: VACUUM은 시간이 오래 걸릴 수 있으므로 백그라운드에서 실행 권장
      try {
        await db.execute('VACUUM');
        debugPrint('PerformanceOptimizer: VACUUM 완료');
      } catch (e) {
        // VACUUM 실패해도 계속 진행 (일부 환경에서 실패할 수 있음)
        debugPrint('PerformanceOptimizer: VACUUM 실패 (계속 진행): $e');
      }

      _lastOptimizationTime = DateTime.now();
      debugPrint('PerformanceOptimizer: 데이터베이스 성능 최적화 완료');
      
      return true;
    } catch (e, stackTrace) {
      debugPrint('PerformanceOptimizer: 최적화 실패 - $e');
      debugPrint('스택 트레이스: $stackTrace');
      return false;
    }
  }

  /// 빠른 최적화 (통계 정보만 업데이트)
  /// 
  /// VACUUM 없이 통계 정보만 업데이트하여 빠르게 실행합니다.
  /// 
  /// [db]: 데이터베이스 인스턴스
  Future<void> quickOptimize(Database db) async {
    try {
      await db.execute('ANALYZE');
      debugPrint('PerformanceOptimizer: 빠른 최적화 완료 (통계 정보 업데이트)');
    } catch (e) {
      debugPrint('PerformanceOptimizer: 빠른 최적화 실패: $e');
    }
  }

  /// 마지막 최적화 시간 가져오기
  DateTime? get lastOptimizationTime => _lastOptimizationTime;
}

