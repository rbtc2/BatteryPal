import 'dart:async';
import 'package:flutter/material.dart';
import '../models/charging_session_models.dart';
import '../services/charging_session_service.dart';
import '../services/charging_session_storage.dart';
import '../utils/time_slot_utils.dart';
import 'charging_session_list_item.dart';
import 'charging_session_detail_dialog.dart';
import '../../../../../services/battery_service.dart';

/// 섹션 3: 통계 + 세션 기록 카드
/// 
/// 실제 충전 세션 데이터를 표시하는 카드
/// - 날짜별 통계 (평균 속도, 충전 횟수, 주 시간대)
/// - 날짜별 충전 세션 목록
class ChargingStatsCard extends StatefulWidget {
  const ChargingStatsCard({super.key});

  @override
  State<ChargingStatsCard> createState() => _ChargingStatsCardState();
}

class _ChargingStatsCardState extends State<ChargingStatsCard> {
  bool _isSessionsExpanded = false;
  
  final ChargingSessionService _sessionService = ChargingSessionService();
  final ChargingSessionStorage _storageService = ChargingSessionStorage();
  final BatteryService _batteryService = BatteryService();
  StreamSubscription<List<ChargingSessionRecord>>? _sessionsSubscription;
  
  // 자동 새로고침 타이머
  Timer? _refreshTimer;
  Timer? _activeSessionUpdateTimer; // 진행 중인 세션 업데이트 타이머
  
  // 날짜 선택 관련 상태 변수
  String _selectedTab = '오늘'; // '오늘', '어제', '2일 전', '선택'
  DateTime? _selectedDate; // 수동 선택한 날짜
  
  // 현재 선택한 날짜의 세션 데이터
  List<ChargingSessionRecord> _currentSessions = [];
  bool _isLoading = true;
  
  // 통계 데이터 (현재 선택한 날짜 기준)
  double _avgCurrent = 0.0;
  int _sessionCount = 0;
  String _mainTimeSlot = '-';
  
  // 성능 최적화: 날짜별 데이터 캐싱 (최근 7일만)
  final Map<String, List<ChargingSessionRecord>> _dateCache = {};
  static const int _maxCacheDays = 7;
  
  @override
  void initState() {
    super.initState();
    _initializeService();
    // 자동 새로고침 시작 (오늘 탭일 때만)
    _startAutoRefresh();
    // 진행 중인 세션 업데이트 시작
    _startActiveSessionUpdate();
  }
  
  Future<void> _initializeService() async {
    try {
      // 서비스 초기화
      await _sessionService.initialize();
      await _storageService.initialize();
      
      // 초기 데이터 로드 (오늘 날짜로 초기화)
      _selectedDate = DateTime.now();
      await _loadSessionsByDate(_getCurrentDate());
      
      // 세션 스트림 구독 (오늘 탭일 때만 자동 업데이트)
      _sessionsSubscription = _sessionService.sessionsStream.listen(
        (sessions) {
          if (mounted && _selectedTab == '오늘') {
            setState(() {
              _currentSessions = sessions;
              _calculateStats(sessions);
              _isLoading = false;
            });
          }
        },
        onError: (error, stackTrace) {
          debugPrint('세션 스트림 오류: $error');
          debugPrint('스택 트레이스: $stackTrace');
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        },
        cancelOnError: false, // 에러 발생 시에도 스트림 유지
      );
      
    } catch (e, stackTrace) {
      debugPrint('서비스 초기화 실패: $e');
      debugPrint('스택 트레이스: $stackTrace');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  /// 날짜별 세션 데이터 로드
  Future<void> _loadSessionsByDate(DateTime date, {bool forceRefresh = false}) async {
    if (!mounted) return;
    
    // 날짜를 날짜만으로 정규화 (시간 제거)
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final dateKey = _getDateKey(normalizedDate);
    
    // 캐시 확인 (오늘이 아니고 강제 새로고침이 아닐 때만)
    final today = DateTime.now();
    final todayNormalized = DateTime(today.year, today.month, today.day);
    final isToday = normalizedDate.isAtSameMomentAs(todayNormalized);
    
    if (!forceRefresh && !isToday && _dateCache.containsKey(dateKey)) {
      // 캐시된 데이터 사용
      final cachedSessions = _dateCache[dateKey]!;
      if (mounted) {
        setState(() {
          _currentSessions = cachedSessions;
          _calculateStats(cachedSessions);
          _isLoading = false;
        });
      }
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      List<ChargingSessionRecord> sessions = [];
      
      // 오늘 날짜인 경우 ChargingSessionService 사용 (실시간 업데이트)
      if (isToday) {
        // 동기 버전으로 빠르게 표시
        sessions = _sessionService.getTodaySessions();
        
        // 먼저 동기 데이터로 UI 업데이트
        if (mounted) {
          setState(() {
            _currentSessions = sessions;
            _calculateStats(sessions);
            _isLoading = false;
          });
        }
        
        // 비동기로 최신 데이터도 로드 (백그라운드)
        _sessionService.getTodaySessionsAsync().then((latestSessions) {
          if (mounted && _selectedTab == '오늘' && _getCurrentDate().isAtSameMomentAs(todayNormalized)) {
            // 오늘 데이터는 캐시하지 않음 (항상 최신 데이터 필요)
            // 날짜가 변경되지 않았을 때만 업데이트
            setState(() {
              _currentSessions = latestSessions;
              _calculateStats(latestSessions);
              _isLoading = false;
            });
          }
        }).catchError((e) {
          debugPrint('최신 세션 로드 실패: $e');
          // 에러 발생해도 기존 데이터는 유지
        });
      } else {
        // 오늘이 아닌 경우 ChargingSessionStorage에서 직접 조회
        sessions = await _storageService.getSessionsByDate(normalizedDate);
        
        // 캐시에 저장 (최근 7일만)
        _dateCache[dateKey] = sessions;
        _cleanupOldCache();
        
        // UI 업데이트
        if (mounted) {
          setState(() {
            _currentSessions = sessions;
            _calculateStats(sessions);
            _isLoading = false;
          });
        }
      }
      
    } catch (e, stackTrace) {
      debugPrint('날짜별 세션 로드 실패: $e');
      debugPrint('스택 트레이스: $stackTrace');
      if (mounted) {
        setState(() {
          _currentSessions = [];
          _calculateStats([]);
          _isLoading = false;
        });
      }
    }
  }
  
  /// 날짜 키 생성 (캐싱용)
  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
  
  /// 오래된 캐시 정리 (7일 이전 데이터 제거)
  void _cleanupOldCache() {
    final now = DateTime.now();
    final cutoffDate = now.subtract(Duration(days: _maxCacheDays));
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
      debugPrint('ChargingStatsCard: 오래된 캐시 ${keysToRemove.length}개 정리 완료');
    }
  }
  
  /// 자동 새로고침 시작
  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    
    // 오늘 탭일 때만 자동 새로고침
    if (_selectedTab == '오늘') {
      _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
        if (!mounted) {
          timer.cancel();
          _refreshTimer = null;
          return;
        }
        
        // 오늘 탭일 때만 자동 새로고침 (수동 선택한 날짜는 자동 새로고침 안 함)
        if (_selectedTab == '오늘') {
          _loadSessionsByDate(_getCurrentDate(), forceRefresh: true);
        } else {
          // 탭이 변경되었으면 타이머 중지
          timer.cancel();
          _refreshTimer = null;
        }
      });
    }
  }
  
  /// 자동 새로고침 중지
  void _stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }
  
  /// Pull-to-Refresh를 위한 public 메서드
  /// 현재 선택된 날짜의 세션 데이터를 강제로 새로고침합니다.
  Future<void> refresh() async {
    await _loadSessionsByDate(_getCurrentDate(), forceRefresh: true);
  }
  
  void _calculateStats(List<ChargingSessionRecord> sessions) {
    if (sessions.isEmpty) {
      _avgCurrent = 0.0;
      _sessionCount = 0;
      _mainTimeSlot = '-';
      return;
    }
    
    // 유효한 세션만 필터링 (5분 이상 충전된 세션만 포함)
    // validate() 메서드를 호출하여 실제로 5분 이상인 세션만 필터링
    final validSessions = sessions.where((s) => s.validate()).toList();
    
    if (validSessions.isEmpty) {
      _avgCurrent = 0.0;
      _sessionCount = 0;
      _mainTimeSlot = '-';
      return;
    }
    
    // 평균 전류 계산 (유효한 세션만)
    final totalCurrent = validSessions.fold<double>(
      0.0,
      (sum, session) => sum + (session.avgCurrent.isFinite ? session.avgCurrent : 0.0),
    );
    _avgCurrent = totalCurrent > 0 ? (totalCurrent / validSessions.length) : 0.0;
    
    // 세션 개수 (유효한 세션만)
    _sessionCount = validSessions.length;
    
    // 주 시간대 계산 (가장 많은 세션이 있는 시간대)
    final timeSlotCounts = <TimeSlot, int>{};
    for (final session in validSessions) {
      timeSlotCounts[session.timeSlot] = 
          (timeSlotCounts[session.timeSlot] ?? 0) + 1;
    }
    
    if (timeSlotCounts.isNotEmpty) {
      final mainSlot = timeSlotCounts.entries.reduce(
        (a, b) => a.value > b.value ? a : b,
      ).key;
      _mainTimeSlot = TimeSlotUtils.getTimeSlotName(mainSlot);
    } else {
      _mainTimeSlot = '-';
    }
  }
  
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
    
    // 캐시 정리
    _dateCache.clear();
    
    // 주의: ChargingSessionService는 싱글톤이므로 여기서 dispose하지 않음
    // 서비스는 앱 전체에서 사용되므로 위젯이 dispose되어도 유지됨
    super.dispose();
  }
  
  /// 진행 중인 세션 업데이트 시작 (1초마다)
  void _startActiveSessionUpdate() {
    _activeSessionUpdateTimer?.cancel();
    _activeSessionUpdateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      // 오늘 탭이고 진행 중인 세션이 있으면 UI 업데이트
      if (_selectedTab == '오늘' && _sessionService.isSessionActive) {
        setState(() {
          // 상태만 업데이트 (진행 중인 세션 카드 리빌드)
        });
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  '충전 분석',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          
          // 날짜 선택 영역
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildTabButton(context, '오늘'),
                SizedBox(width: 8),
                _buildTabButton(context, '어제'),
                SizedBox(width: 8),
                _buildTabButton(context, '2일 전'),
                Spacer(),
                InkWell(
                  onTap: _showDatePicker,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.calendar_today, size: 14),
                        SizedBox(width: 6),
                        Text(
                          _selectedDate != null
                              ? '${_selectedDate!.year}.${_selectedDate!.month.toString().padLeft(2, '0')}.${_selectedDate!.day.toString().padLeft(2, '0')}'
                              : DateTime.now().toString().split(' ')[0].replaceAll('-', '.'),
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 16),
          
          // 통계 카드 3개 (가로 배치)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildEnhancedStatCard(
                    context,
                    title: '평균속도',
                    mainValue: _isLoading ? '...' : (_avgCurrent > 0 ? _avgCurrent.toStringAsFixed(0) : '0'),
                    unit: 'mA',
                    subValue: _avgCurrent > 0 ? _getCurrentSpeedType(_avgCurrent) : '데이터 없음',
                    trend: '', // 추후 주간 비교 데이터 추가 시 사용
                    trendColor: Colors.green,
                    icon: Icons.speed,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _buildEnhancedStatCard(
                    context,
                    title: '충전횟수',
                    mainValue: _isLoading ? '...' : '$_sessionCount회',
                    unit: _getDateUnitText(),
                    subValue: _sessionCount > 0 ? '${_getDateDisplayText()} 기준' : '없음',
                    trend: '', // 추후 주간 비교 데이터 추가 시 사용
                    trendColor: Colors.blue,
                    icon: Icons.battery_charging_full,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _buildEnhancedStatCard(
                    context,
                    title: '주시간대',
                    mainValue: _isLoading ? '...' : _mainTimeSlot,
                    unit: '',
                    subValue: _mainTimeSlot != '-' ? TimeSlotUtils.getTimeSlotRange(_getMainTimeSlot()) : '없음',
                    trend: '안정',
                    trendColor: Colors.blue,
                    icon: Icons.access_time,
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 16),
          
          // 세션 기록 펼치기 버튼
          InkWell(
            onTap: () {
              setState(() {
                _isSessionsExpanded = !_isSessionsExpanded;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isSessionsExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '충전 세션 기록 (${_getDateDisplayText()}) ${_isSessionsExpanded ? '' : '보기'}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  if (!_isSessionsExpanded)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_currentSessions.where((s) => s.validate()).length}건',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          // 세션 기록 리스트 (펼쳤을 때만 표시)
          if (_isSessionsExpanded) ...[
            // 진행 중인 충전 카드 (오늘 탭이고 진행 중인 세션이 있을 때만)
            if (_selectedTab == '오늘' && _sessionService.isSessionActive) ...[
              _buildActiveChargingCard(),
              SizedBox(height: 12),
            ],
            if (_isLoading)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        '${_getDateDisplayText()} 데이터 로딩 중...',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (_currentSessions.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.battery_charging_full,
                        size: 48,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                      ),
                      SizedBox(height: 16),
                      Text(
                        _selectedTab == '오늘' && _sessionService.isSessionActive
                            ? '충전 중입니다'
                            : '${_getDateDisplayText()} 충전 세션이 없습니다',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8),
                      Text(
                        _selectedTab == '오늘' && _sessionService.isSessionActive
                            ? '3분 이상 충전 시 여기에 기록됩니다'
                            : '해당 날짜에 기록된 충전 세션이 없습니다',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 날짜 헤더 (선택 사항)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          SizedBox(width: 6),
                          Text(
                            '${_getDateDisplayText()} - ${_currentSessions.where((s) => s.validate()).length}개 세션',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // 세션 목록 (5분 이상인 세션만 표시)
                    ..._currentSessions.where((s) => s.validate()).map((session) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: ChargingSessionListItem(
                          session: session,
                          onTap: () {
                            // 세션 상세 정보 다이얼로그 표시
                            ChargingSessionDetailDialog.show(context, session);
                          },
                        ),
                      );
                    }),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildEnhancedStatCard(
    BuildContext context, {
    required String title,
    required String mainValue,
    required String unit,
    required String subValue,
    required String trend,
    required Color trendColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.surfaceContainerHighest,
            Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더: 아이콘 + 제목
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: trendColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  icon,
                  size: 14,
                  color: trendColor,
                ),
              ),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          
          SizedBox(height: 8),
          
          // 메인 값 + 단위 (가로로 배치, 줄바꿈 방지)
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  mainValue,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (unit.isNotEmpty) ...[
                SizedBox(width: 4),
                Text(
                  unit,
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  maxLines: 1,
                ),
              ],
            ],
          ),
          
          SizedBox(height: 4),
          
          // 서브 값과 트렌드
          Row(
            children: [
              Expanded(
                child: Text(
                  subValue,
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: trendColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getTrendIcon(trend),
                      size: 8,
                      color: trendColor,
                    ),
                    SizedBox(width: 2),
                    Text(
                      trend,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: trendColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getTrendIcon(String trend) {
    if (trend.startsWith('+')) return Icons.trending_up;
    if (trend.startsWith('-')) return Icons.trending_down;
    return Icons.trending_flat;
  }
  
  /// 전류 속도 타입 반환
  String _getCurrentSpeedType(double current) {
    if (current >= 3000) return '⚡ 초고속';
    if (current >= 1500) return '⚡ 급속';
    if (current >= 500) return '🟧 일반';
    return '🔵 저속';
  }
  
  /// 주 시간대 TimeSlot 반환
  TimeSlot _getMainTimeSlot() {
    final validSessions = _currentSessions.where((s) => s.validate()).toList();
    if (validSessions.isEmpty) return TimeSlot.morning;
    
    final timeSlotCounts = <TimeSlot, int>{};
    for (final session in validSessions) {
      timeSlotCounts[session.timeSlot] = 
          (timeSlotCounts[session.timeSlot] ?? 0) + 1;
    }
    
    if (timeSlotCounts.isNotEmpty) {
      return timeSlotCounts.entries.reduce(
        (a, b) => a.value > b.value ? a : b,
      ).key;
    }
    
    return TimeSlot.morning;
  }
  
  /// 현재 선택한 날짜 가져오기
  DateTime _getCurrentDate() {
    switch (_selectedTab) {
      case '어제':
        return DateTime.now().subtract(const Duration(days: 1));
      case '2일 전':
        return DateTime.now().subtract(const Duration(days: 2));
      case '선택':
        return _selectedDate ?? DateTime.now();
      case '오늘':
      default:
        return DateTime.now();
    }
  }
  
  /// 선택한 날짜의 표시 텍스트 가져오기
  String _getDateDisplayText() {
    switch (_selectedTab) {
      case '오늘':
        return '오늘';
      case '어제':
        return '어제';
      case '2일 전':
        return '2일 전';
      case '선택':
        if (_selectedDate != null) {
          return '${_selectedDate!.year}.${_selectedDate!.month.toString().padLeft(2, '0')}.${_selectedDate!.day.toString().padLeft(2, '0')}';
        }
        return '선택';
      default:
        return '오늘';
    }
  }
  
  /// 통계 카드의 날짜 단위 텍스트 가져오기
  String _getDateUnitText() {
    switch (_selectedTab) {
      case '오늘':
        return '(오늘)';
      case '어제':
        return '(어제)';
      case '2일 전':
        return '(2일 전)';
      case '선택':
        if (_selectedDate != null) {
          return '(${_selectedDate!.month.toString().padLeft(2, '0')}.${_selectedDate!.day.toString().padLeft(2, '0')})';
        }
        return '(선택)';
      default:
        return '(오늘)';
    }
  }
  
  /// 탭 버튼 빌드 (ChargingCurrentChart와 동일한 스타일)
  Widget _buildTabButton(BuildContext context, String label) {
    final isSelected = _selectedTab == label;
    return InkWell(
      onTap: () {
        if (!mounted) return;
        
        setState(() {
          _selectedTab = label;
          // 탭 변경 시 날짜 업데이트
          if (label != '선택') {
            switch (label) {
              case '어제':
                _selectedDate = DateTime.now().subtract(const Duration(days: 1));
                break;
              case '2일 전':
                _selectedDate = DateTime.now().subtract(const Duration(days: 2));
                break;
              case '오늘':
              default:
                _selectedDate = DateTime.now();
                break;
            }
          }
        });
        // 날짜별 데이터 로드
        _loadSessionsByDate(_getCurrentDate());
        // 자동 새로고침 재시작 (오늘 탭일 때만)
        _startAutoRefresh();
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? Theme.of(context).colorScheme.primaryContainer
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
  
  /// 날짜 선택 다이얼로그 표시
  /// 오늘로부터 7일 전까지의 날짜만 선택 가능
  Future<void> _showDatePicker() async {
    if (!mounted) return;
    
    final now = DateTime.now();
    // 날짜만 비교하기 위해 시간 제거
    final today = DateTime(now.year, now.month, now.day);
    final firstDate = today.subtract(const Duration(days: 7)); // 7일 전
    final lastDate = today; // 오늘
    
    // 초기 날짜 설정 (선택된 날짜가 없으면 오늘)
    final initialDate = _selectedDate ?? today;
    
    // 날짜가 범위를 벗어나면 today로 설정
    final safeInitialDate = initialDate.isBefore(firstDate) || initialDate.isAfter(lastDate)
        ? today
        : initialDate;
    
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: safeInitialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: '날짜 선택 (최근 7일)',
      cancelText: '취소',
      confirmText: '확인',
      selectableDayPredicate: (date) {
        // 선택 가능한 날짜 범위 체크 (7일 전 ~ 오늘)
        final dateOnly = DateTime(date.year, date.month, date.day);
        final daysDiff = today.difference(dateOnly).inDays;
        return daysDiff >= 0 && daysDiff <= 7;
      },
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
              onPrimary: Theme.of(context).colorScheme.onPrimary,
              surface: Theme.of(context).colorScheme.surface,
              onSurface: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (!mounted) return;
    
    if (selectedDate != null) {
      // 날짜만 사용 (시간 제거)
      final selectedDateOnly = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
      
      // 선택한 날짜가 범위를 벗어나지 않는지 확인
      final daysDiff = today.difference(selectedDateOnly).inDays;
      if (daysDiff < 0 || daysDiff > 7) {
        debugPrint('ChargingStatsCard: 선택한 날짜가 범위를 벗어남 - $selectedDateOnly');
        return;
      }
      
      setState(() {
        _selectedDate = selectedDateOnly;
        _selectedTab = '선택'; // 탭을 '선택'으로 변경하여 수동 선택임을 표시
      });
      
      // 날짜별 데이터 로드
      _loadSessionsByDate(selectedDateOnly);
      // 수동 선택한 날짜는 자동 새로고침 중지
      _stopAutoRefresh();
    }
  }

  // 기존 _buildEnhancedSessionItem 메서드는 제거됨 (ChargingSessionListItem 사용)
  
  /// 진행 중인 충전 카드 빌드
  Widget _buildActiveChargingCard() {
    final batteryInfo = _batteryService.currentBatteryInfo;
    final sessionStartTime = _sessionService.sessionStartTime;
    
    if (batteryInfo == null || sessionStartTime == null) {
      return const SizedBox.shrink();
    }
    
    final elapsed = DateTime.now().difference(sessionStartTime);
    final minutes = elapsed.inMinutes;
    final seconds = elapsed.inSeconds % 60;
    
    // 유의미한 세션이 되기까지 남은 시간 계산 (3분 = 180초)
    const minSessionDuration = Duration(minutes: 3);
    final remainingTime = minSessionDuration - elapsed;
    final remainingMinutes = remainingTime.inMinutes.clamp(0, 999);
    final remainingSeconds = remainingTime.inSeconds.clamp(0, 59) % 60;
    
    final currentLevel = batteryInfo.level;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.withValues(alpha: 0.15),
            Colors.blue.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더: 진행 중 배지
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _PulsingDot(color: Colors.blue),
                    const SizedBox(width: 6),
                    Text(
                      '진행 중',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                batteryInfo.chargingTypeText,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // 정보 그리드
          Row(
            children: [
              Expanded(
                child: _buildActiveInfoItem(
                  icon: Icons.access_time,
                  label: '경과 시간',
                  value: '$minutes분 $seconds초',
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.blue.withValues(alpha: 0.2),
              ),
              Expanded(
                child: _buildActiveInfoItem(
                  icon: Icons.battery_std,
                  label: '배터리',
                  value: '${currentLevel.toInt()}%',
                ),
              ),
            ],
          ),
          
          // 유의미한 세션이 되기까지 남은 시간
          if (remainingTime.inSeconds > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Colors.blue[700],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      remainingMinutes > 0
                          ? '$remainingMinutes분 $remainingSeconds초 후 기록됩니다'
                          : '$remainingSeconds초 후 기록됩니다',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 16,
                    color: Colors.green[700],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '충전 세션 기록 조건을 만족했습니다',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  /// 진행 중인 충전 정보 항목 빌드
  Widget _buildActiveInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 20,
          color: Colors.blue[700],
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}

/// 깜빡이는 점 (진행 중 표시)
class _PulsingDot extends StatefulWidget {
  final Color color;
  
  const _PulsingDot({required this.color});
  
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
  }
  
  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
