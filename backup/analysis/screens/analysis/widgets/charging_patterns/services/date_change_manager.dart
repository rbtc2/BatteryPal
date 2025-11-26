// 날짜 변경 관리 서비스
// 날짜 변경 감지 및 과거 세션 데이터 저장/정리를 관리하는 서비스

import 'package:flutter/foundation.dart';
import '../../../../../services/battery_history_database_service.dart';
import 'charging_session_storage.dart';

/// 날짜 변경 관리자
/// 
/// 주요 기능:
/// 1. 날짜 변경 감지
/// 2. 과거 세션 데이터 저장
/// 3. 오래된 세션 데이터 정리
class DateChangeManager {
  final ChargingSessionStorage _storageService;
  final BatteryHistoryDatabaseService _databaseService;
  
  /// 마지막 저장 날짜 키
  String? _lastSavedDateKey;
  
  /// 생성자
  DateChangeManager({
    ChargingSessionStorage? storageService,
    BatteryHistoryDatabaseService? databaseService,
  })  : _storageService = storageService ?? ChargingSessionStorage(),
        _databaseService = databaseService ?? BatteryHistoryDatabaseService();
  
  // ==================== 날짜 키 관리 ====================
  
  /// 날짜 키 생성
  String getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
  
  /// 마지막 저장 날짜 키 가져오기
  String? get lastSavedDateKey => _lastSavedDateKey;
  
  /// 마지막 저장 날짜 키 설정
  void setLastSavedDateKey(String? dateKey) {
    _lastSavedDateKey = dateKey;
  }
  
  // ==================== 날짜 변경 감지 및 저장 ====================
  
  /// 날짜 변경 감지 및 과거 세션 저장
  /// 
  /// [isDisposed] 서비스가 dispose되었는지 확인하는 콜백
  /// [isInitialized] 서비스가 초기화되었는지 확인하는 콜백
  void checkDateChangeAndSave({
    required bool Function() isDisposed,
    required bool Function() isInitialized,
  }) {
    if (isDisposed() || !isInitialized()) return;
    
    try {
      final now = DateTime.now();
      final todayKey = getDateKey(now);
      
      // 마지막 저장 날짜가 없으면 오늘 날짜로 초기화
      if (_lastSavedDateKey == null) {
        _lastSavedDateKey = todayKey;
        return;
      }
      
      // 날짜가 바뀌었는지 확인
      if (_lastSavedDateKey != todayKey) {
        debugPrint('DateChangeManager: 날짜 변경 감지 - $_lastSavedDateKey -> $todayKey');
        
        // 어제 날짜의 세션을 DB에 저장
        final yesterday = now.subtract(const Duration(days: 1));
        _storageService.saveDateSessionsToDatabase(yesterday).then((count) {
          if (count > 0) {
            debugPrint('DateChangeManager: 어제 세션 $count개 DB 저장 완료');
          }
        }).catchError((e) {
          debugPrint('DateChangeManager: 어제 세션 저장 실패 - $e');
        });
        
        // 모든 과거 세션 저장 (7일 전까지)
        _storageService.saveAllPastSessionsToDatabase(todayKey).then((count) {
          if (count > 0) {
            debugPrint('DateChangeManager: 과거 세션 $count개 DB 저장 완료');
          }
        }).catchError((e) {
          debugPrint('DateChangeManager: 과거 세션 저장 실패 - $e');
        });
        
        // 오늘 날짜로 업데이트
        _lastSavedDateKey = todayKey;
      }
    } catch (e, stackTrace) {
      debugPrint('DateChangeManager: 날짜 변경 감지 실패 - $e');
      debugPrint('스택 트레이스: $stackTrace');
    }
  }
  
  // ==================== 오래된 세션 정리 ====================
  
  /// 7일 이상 된 충전 세션 데이터 정리
  /// 
  /// [isDisposed] 서비스가 dispose되었는지 확인하는 콜백
  /// [isInitialized] 서비스가 초기화되었는지 확인하는 콜백
  Future<void> cleanupOldSessions({
    required bool Function() isDisposed,
    required bool Function() isInitialized,
  }) async {
    if (isDisposed() || !isInitialized()) return;
    
    try {
      final deletedCount = await _databaseService.cleanupOldChargingSessions();
      if (deletedCount > 0) {
        debugPrint('DateChangeManager: 7일 이상 된 세션 $deletedCount개 자동 정리 완료');
      }
    } catch (e, stackTrace) {
      debugPrint('DateChangeManager: 오래된 세션 정리 실패 - $e');
      debugPrint('스택 트레이스: $stackTrace');
    }
  }
  
  // ==================== 상태 확인 ====================
  
  /// 현재 상태 확인 (디버깅용)
  Map<String, dynamic> getStatus() {
    return {
      'lastSavedDateKey': _lastSavedDateKey,
    };
  }
}

