import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../database_manager.dart';
import '../database_path_manager.dart';

/// 데이터베이스 백업 및 복원 서비스
/// 데이터베이스 파일의 백업과 복원을 담당합니다.
class BackupService {
  /// 싱글톤 인스턴스
  static final BackupService _instance = BackupService._internal();
  factory BackupService() => _instance;
  BackupService._internal();

  final DatabasePathManager _pathManager = DatabasePathManager();

  /// 데이터베이스 백업
  /// 
  /// 현재 데이터베이스 파일을 백업 파일로 복사합니다.
  /// 
  /// [db]: 데이터베이스 인스턴스 (검증용)
  /// 
  /// Returns: 백업 파일 경로
  Future<String> backupDatabase(Database db) async {
    try {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final backupPath = join(
        documentsDirectory.path,
        'battery_history_backup_${DateTime.now().millisecondsSinceEpoch}.db'
      );
      
      final databasePath = await _pathManager.getDatabasePath();
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
  /// 
  /// 백업 파일로부터 데이터베이스를 복원합니다.
  /// 
  /// [backupPath]: 복원할 백업 파일 경로
  /// [databaseManager]: 데이터베이스 매니저 (연결 종료 및 재초기화용)
  /// 
  /// 주의: 복원 후 데이터베이스가 재초기화됩니다.
  Future<void> restoreDatabase(
    String backupPath,
    DatabaseManager databaseManager,
  ) async {
    try {
      // 기존 데이터베이스 연결 종료
      await databaseManager.close();
      
      // 백업 파일을 데이터베이스 경로로 복사
      final databasePath = await _pathManager.getDatabasePath();
      await File(backupPath).copy(databasePath);
      
      // 데이터베이스 재초기화
      await databaseManager.initialize();
      
      debugPrint('데이터베이스 복원 완료: $backupPath');
    } catch (e, stackTrace) {
      debugPrint('데이터베이스 복원 실패: $e');
      debugPrint('스택 트레이스: $stackTrace');
      rethrow;
    }
  }
}

