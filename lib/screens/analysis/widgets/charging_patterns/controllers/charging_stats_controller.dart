import 'dart:async';
import 'package:flutter/material.dart';
import '../models/charging_session_models.dart';
import '../services/charging_session_service.dart';
import '../services/charging_session_storage.dart';
import '../utils/charging_stats_calculator.dart';
import 'date_selector_controller.dart';
import 'charging_session_data_loader.dart';
import '../../../../../services/battery_service.dart';

/// 충전 통계 카드의 상태 관리 및 타이머 관리를 담당하는 컨트롤러
/// 
/// 자동 새로고침, 진행 중인 세션 업데이트, 데이터 로딩 등을 관리합니다.
class ChargingStatsController extends ChangeNotifier {
  final ChargingSessionService _sessionService;
  final DateSelectorController _dateController;
  final ChargingSessionDataLoader _dataLoader;
  
  StreamSubscription<List<ChargingSessionRecord>>? _sessionsSubscription;
  
  // 자동 새로고침 타이머
  Timer? _refreshTimer;
  Timer? _activeSessionUpdateTimer; // 진행 중인 세션 업데이트 타이머
  
  // 현재 선택한 날짜의 세션 데이터
  List<ChargingSessionRecord> _currentSessions = [];
  bool _isLoading = true;
  
  // 통계 데이터 (현재 선택한 날짜 기준)
  ChargingStats _stats = ChargingStats.empty();
  
  // 위젯이 마운트되었는지 확인하는 콜백
  bool Function()? _isMounted;
  
  // 상태 업데이트 콜백
  Function()? _onStateChanged;
  
  // 이전 세션 활성 상태 (상태 변화 감지용)
  bool _previousIsSessionActive = false;
  
  ChargingStatsController({
    required ChargingSessionService sessionService,
    required ChargingSessionStorage storageService,
    required BatteryService batteryService,
    required DateSelectorController dateController,
    required ChargingSessionDataLoader dataLoader,
  })  : _sessionService = sessionService,
        _dateController = dateController,
        _dataLoader = dataLoader {
    _initialize();
  }
  
  /// 현재 세션 목록
  List<ChargingSessionRecord> get currentSessions => _currentSessions;
  
  /// 로딩 상태
  bool get isLoading => _isLoading;
  
  /// 통계 데이터
  ChargingStats get stats => _stats;
  
  /// 위젯 마운트 상태 확인 콜백 설정
  void setIsMounted(bool Function() isMounted) {
    _isMounted = isMounted;
  }
  
  /// 상태 변경 콜백 설정
  void setOnStateChanged(Function() onStateChanged) {
    _onStateChanged = onStateChanged;
  }
  
  /// 초기화
  void _initialize() {
    // 날짜 변경 콜백 설정
    _dateController.onDateChanged = (date) {
      _loadSessionsByDate(date);
      // 오늘 탭일 때만 자동 새로고침 시작
      if (_dateController.isToday) {
        startAutoRefresh();
      } else {
        stopAutoRefresh();
      }
    };
    
    // 데이터 로더 콜백 설정
    _dataLoader.onDataLoaded = (sessions, isLoading) {
      if (_isMounted?.call() ?? true) {
        _currentSessions = sessions;
        _calculateStats(sessions);
        _isLoading = isLoading;
        _notifyStateChanged();
      }
    };
    
    _dataLoader.onError = (error, stackTrace) {
      debugPrint('ChargingStatsController: 데이터 로드 에러: $error');
      if (_isMounted?.call() ?? true) {
        _currentSessions = [];
        _calculateStats([]);
        _isLoading = false;
        _notifyStateChanged();
      }
    };
  }
  
  /// 서비스 초기화 및 데이터 로드
  Future<void> initialize() async {
    try {
      // 데이터 로더 초기화
      await _dataLoader.initialize();
      
      // 초기 데이터 로드 (오늘 날짜로 초기화)
      await _loadSessionsByDate(_dateController.getCurrentDate());
      
      // 세션 스트림 구독 (오늘 탭일 때만 자동 업데이트)
      _sessionsSubscription = _sessionService.sessionsStream.listen(
        (sessions) {
          if ((_isMounted?.call() ?? true) && _dateController.isToday) {
            _currentSessions = sessions;
            _calculateStats(sessions);
            _isLoading = false;
            _notifyStateChanged();
          }
        },
        onError: (error, stackTrace) {
          debugPrint('ChargingStatsController: 세션 스트림 오류: $error');
          debugPrint('스택 트레이스: $stackTrace');
          if (_isMounted?.call() ?? true) {
            _isLoading = false;
            _notifyStateChanged();
          }
        },
        cancelOnError: false, // 에러 발생 시에도 스트림 유지
      );
      
      // 자동 새로고침 시작 (오늘 탭일 때만)
      startAutoRefresh();
      // 진행 중인 세션 업데이트 시작
      startActiveSessionUpdate();
      
    } catch (e, stackTrace) {
      debugPrint('ChargingStatsController 초기화 실패: $e');
      debugPrint('스택 트레이스: $stackTrace');
      if (_isMounted?.call() ?? true) {
        _isLoading = false;
        _notifyStateChanged();
      }
    }
  }
  
  /// 날짜별 세션 데이터 로드
  /// 
  /// [date]: 로드할 날짜
  /// [forceRefresh]: 캐시를 무시하고 강제로 새로고침할지 여부
  Future<void> _loadSessionsByDate(DateTime date, {bool forceRefresh = false}) async {
    if (_isMounted?.call() == false) return;
    
    // 날짜를 날짜만으로 정규화 (시간 제거)
    final normalizedDate = DateTime(date.year, date.month, date.day);
    
    // 오늘 날짜인지 확인
    final today = DateTime.now();
    final todayNormalized = DateTime(today.year, today.month, today.day);
    final isToday = normalizedDate.isAtSameMomentAs(todayNormalized);
    
    // 데이터 로더를 통해 로드
    await _dataLoader.loadSessionsByDate(
      normalizedDate,
      forceRefresh: forceRefresh,
      isToday: isToday,
    );
  }
  
  /// Pull-to-Refresh를 위한 public 메서드
  /// 현재 선택된 날짜의 세션 데이터를 강제로 새로고침합니다.
  Future<void> refresh() async {
    await _loadSessionsByDate(_dateController.getCurrentDate(), forceRefresh: true);
  }
  
  /// 통계 계산
  void _calculateStats(List<ChargingSessionRecord> sessions) {
    _stats = ChargingStatsCalculator.calculate(sessions);
  }
  
  /// 자동 새로고침 시작
  void startAutoRefresh() {
    _refreshTimer?.cancel();
    
    // 오늘 탭일 때만 자동 새로고침
    if (_dateController.isToday) {
      _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
        if (_isMounted?.call() == false) {
          timer.cancel();
          _refreshTimer = null;
          return;
        }
        
        // 오늘 탭일 때만 자동 새로고침 (수동 선택한 날짜는 자동 새로고침 안 함)
        if (_dateController.isToday) {
          _loadSessionsByDate(_dateController.getCurrentDate(), forceRefresh: true);
        } else {
          // 탭이 변경되었으면 타이머 중지
          timer.cancel();
          _refreshTimer = null;
        }
      });
    }
  }
  
  /// 자동 새로고침 중지
  void stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }
  
  /// 진행 중인 세션 업데이트 시작 (1초마다)
  /// 
  /// 세션 상태 변화를 감지하여 UI를 업데이트합니다.
  /// - 세션이 활성화되면 UI 업데이트
  /// - 세션이 비활성화되면 즉시 UI 업데이트 (카드 숨김)
  void startActiveSessionUpdate() {
    _activeSessionUpdateTimer?.cancel();
    
    // 초기 상태 저장
    _previousIsSessionActive = _sessionService.isSessionActive;
    
    _activeSessionUpdateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isMounted?.call() == false) {
        timer.cancel();
        return;
      }
      
      // 오늘 탭일 때만 처리
      if (!_dateController.isToday) {
        return;
      }
      
      final currentIsSessionActive = _sessionService.isSessionActive;
      
      // 세션 상태가 변경되었거나, 세션이 활성화되어 있으면 UI 업데이트
      // 상태가 false로 변경되었을 때도 즉시 업데이트하여 카드를 숨김
      if (currentIsSessionActive != _previousIsSessionActive || currentIsSessionActive) {
        _previousIsSessionActive = currentIsSessionActive;
        _notifyStateChanged();
      }
    });
  }
  
  /// 진행 중인 세션 업데이트 중지
  void stopActiveSessionUpdate() {
    _activeSessionUpdateTimer?.cancel();
    _activeSessionUpdateTimer = null;
  }
  
  /// 상태 변경 알림
  void _notifyStateChanged() {
    notifyListeners();
    _onStateChanged?.call();
  }
  
  /// 리소스 정리
  @override
  void dispose() {
    // 타이머 정리
    _refreshTimer?.cancel();
    _refreshTimer = null;
    _activeSessionUpdateTimer?.cancel();
    _activeSessionUpdateTimer = null;
    
    // 스트림 구독 해제
    _sessionsSubscription?.cancel();
    _sessionsSubscription = null;
    
    super.dispose();
  }
}

