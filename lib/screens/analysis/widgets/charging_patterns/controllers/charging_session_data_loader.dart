import 'package:flutter/material.dart';
import '../models/charging_session_models.dart';
import '../services/charging_session_service.dart';
import '../services/charging_session_storage.dart';

/// 충전 세션 데이터 로딩 및 캐싱을 담당하는 클래스
/// 
/// 날짜별 세션 데이터를 로드하고, 캐싱을 통해 성능을 최적화합니다.
/// 오늘 날짜는 실시간 업데이트를 위해 ChargingSessionService를 사용하고,
/// 과거 날짜는 ChargingSessionStorage를 사용합니다.
class ChargingSessionDataLoader {
  final ChargingSessionService _sessionService;
  final ChargingSessionStorage _storageService;
  
  /// 날짜별 데이터 캐싱 (최근 7일만)
  final Map<String, List<ChargingSessionRecord>> _dateCache = {};
  static const int _maxCacheDays = 7;
  
  /// 데이터 로딩 콜백
  /// [sessions]: 로드된 세션 목록
  /// [isLoading]: 로딩 중 여부
  Function(List<ChargingSessionRecord> sessions, bool isLoading)? onDataLoaded;
  
  /// 에러 콜백
  /// [error]: 에러 메시지
  /// [stackTrace]: 스택 트레이스
  Function(String error, StackTrace stackTrace)? onError;
  
  ChargingSessionDataLoader({
    required ChargingSessionService sessionService,
    required ChargingSessionStorage storageService,
  })  : _sessionService = sessionService,
        _storageService = storageService;
  
  /// 서비스 초기화
  Future<void> initialize() async {
    await _sessionService.initialize();
    await _storageService.initialize();
  }
  
  /// 날짜별 세션 데이터 로드
  /// 
  /// [date]: 로드할 날짜
  /// [forceRefresh]: 캐시를 무시하고 강제로 새로고침할지 여부
  /// [isToday]: 오늘 날짜인지 여부 (실시간 업데이트 여부 결정)
  Future<void> loadSessionsByDate(
    DateTime date, {
    bool forceRefresh = false,
    bool isToday = false,
  }) async {
    // 날짜를 날짜만으로 정규화 (시간 제거)
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final dateKey = _getDateKey(normalizedDate);
    
    // 캐시 확인 (오늘이 아니고 강제 새로고침이 아닐 때만)
    if (!forceRefresh && !isToday && _dateCache.containsKey(dateKey)) {
      // 캐시된 데이터 사용
      final cachedSessions = _dateCache[dateKey]!;
      onDataLoaded?.call(cachedSessions, false);
      return;
    }
    
    // 로딩 시작
    onDataLoaded?.call([], true);
    
    try {
      List<ChargingSessionRecord> sessions = [];
      
      // 오늘 날짜인 경우 ChargingSessionService 사용 (실시간 업데이트)
      if (isToday) {
        // 동기 버전으로 빠르게 표시
        sessions = _sessionService.getTodaySessions();
        
        // 먼저 동기 데이터로 UI 업데이트
        onDataLoaded?.call(sessions, false);
        
        // 비동기로 최신 데이터도 로드 (백그라운드)
        _sessionService.getTodaySessionsAsync().then((latestSessions) {
          // 오늘 데이터는 캐시하지 않음 (항상 최신 데이터 필요)
          onDataLoaded?.call(latestSessions, false);
        }).catchError((e) {
          debugPrint('ChargingSessionDataLoader: 최신 세션 로드 실패: $e');
          // 에러 발생해도 기존 데이터는 유지
        });
      } else {
        // 오늘이 아닌 경우 ChargingSessionStorage에서 직접 조회
        sessions = await _storageService.getSessionsByDate(normalizedDate);
        
        // 캐시에 저장 (최근 7일만)
        _dateCache[dateKey] = sessions;
        _cleanupOldCache();
        
        // UI 업데이트
        onDataLoaded?.call(sessions, false);
      }
      
    } catch (e, stackTrace) {
      debugPrint('ChargingSessionDataLoader: 날짜별 세션 로드 실패: $e');
      debugPrint('스택 트레이스: $stackTrace');
      onError?.call(e.toString(), stackTrace);
      onDataLoaded?.call([], false);
    }
  }
  
  /// 날짜 키 생성 (캐싱용)
  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
  
  /// 오래된 캐시 정리 (7일 이전 데이터 제거)
  void _cleanupOldCache() {
    final now = DateTime.now();
    final cutoffDate = now.subtract(const Duration(days: _maxCacheDays));
    final cutoffKey = _getDateKey(cutoffDate);
    
    final keysToRemove = <String>[];
    for (final key in _dateCache.keys) {
      if (key.compareTo(cutoffKey) < 0) {
        keysToRemove.add(key);
      }
    }
    
    for (final key in keysToRemove) {
      _dateCache.remove(key);
    }
    
    if (keysToRemove.isNotEmpty) {
      debugPrint('ChargingSessionDataLoader: 오래된 캐시 ${keysToRemove.length}개 정리 완료');
    }
  }
  
  /// 특정 날짜의 캐시 무효화
  void invalidateCache(DateTime date) {
    final dateKey = _getDateKey(DateTime(date.year, date.month, date.day));
    _dateCache.remove(dateKey);
  }
  
  /// 모든 캐시 무효화
  void clearCache() {
    _dateCache.clear();
  }
  
  /// 캐시된 날짜 목록 가져오기
  List<String> getCachedDates() {
    return _dateCache.keys.toList();
  }
  
  /// 캐시 크기 가져오기
  int get cacheSize => _dateCache.length;
}

