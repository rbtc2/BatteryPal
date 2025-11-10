import 'dart:async';
import 'package:flutter/material.dart';
import '../models/charging_session_models.dart';
import '../services/charging_session_service.dart';
import '../utils/time_slot_utils.dart';
import 'charging_session_list_item.dart';
import 'charging_session_detail_dialog.dart';

/// 섹션 3: 통계 + 세션 기록 카드
/// 
/// 실제 충전 세션 데이터를 표시하는 카드
/// - 주간 통계 (평균 속도, 충전 횟수, 주 시간대)
/// - 오늘의 충전 세션 목록
class ChargingStatsCard extends StatefulWidget {
  const ChargingStatsCard({super.key});

  @override
  State<ChargingStatsCard> createState() => _ChargingStatsCardState();
}

class _ChargingStatsCardState extends State<ChargingStatsCard> {
  bool _isSessionsExpanded = false;
  
  final ChargingSessionService _sessionService = ChargingSessionService();
  StreamSubscription<List<ChargingSessionRecord>>? _sessionsSubscription;
  
  List<ChargingSessionRecord> _todaySessions = [];
  bool _isLoading = true;
  
  // 통계 데이터
  double _avgCurrent = 0.0;
  int _sessionCount = 0;
  String _mainTimeSlot = '-';
  
  @override
  void initState() {
    super.initState();
    _initializeService();
  }
  
  Future<void> _initializeService() async {
    try {
      // 서비스 초기화
      await _sessionService.initialize();
      
      // 초기 데이터 로드 (동기 버전으로 빠르게 표시)
      final initialSessions = _sessionService.getTodaySessions();
      if (mounted) {
        setState(() {
          _todaySessions = initialSessions;
          _calculateStats(initialSessions);
          _isLoading = false;
        });
      }
      
      // 세션 스트림 구독
      _sessionsSubscription = _sessionService.sessionsStream.listen(
        (sessions) {
          if (mounted) {
            setState(() {
              _todaySessions = sessions;
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
      
      // 비동기로 최신 데이터도 로드 (백그라운드)
      _sessionService.getTodaySessionsAsync().then((latestSessions) {
        if (mounted) {
          setState(() {
            _todaySessions = latestSessions;
            _calculateStats(latestSessions);
            _isLoading = false;
          });
        }
      }).catchError((e) {
        debugPrint('최신 세션 로드 실패: $e');
        // 에러 발생해도 기존 데이터는 유지
      });
      
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
  
  void _calculateStats(List<ChargingSessionRecord> sessions) {
    if (sessions.isEmpty) {
      _avgCurrent = 0.0;
      _sessionCount = 0;
      _mainTimeSlot = '-';
      return;
    }
    
    // 평균 전류 계산
    final totalCurrent = sessions.fold<double>(
      0.0,
      (sum, session) => sum + session.avgCurrent,
    );
    _avgCurrent = totalCurrent / sessions.length;
    
    // 세션 개수
    _sessionCount = sessions.length;
    
    // 주 시간대 계산 (가장 많은 세션이 있는 시간대)
    final timeSlotCounts = <TimeSlot, int>{};
    for (final session in sessions) {
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
    _sessionsSubscription?.cancel();
    // 주의: ChargingSessionService는 싱글톤이므로 여기서 dispose하지 않음
    // 서비스는 앱 전체에서 사용되므로 위젯이 dispose되어도 유지됨
    super.dispose();
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
                Text('📈', style: TextStyle(fontSize: 24)),
                SizedBox(width: 12),
                Text(
                  '주간 충전 분석',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          
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
                    mainValue: _isLoading ? '...' : _avgCurrent.toStringAsFixed(0),
                    unit: 'mA',
                    subValue: _getCurrentSpeedType(_avgCurrent),
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
                    unit: '(오늘)',
                    subValue: _sessionCount > 0 ? '일 평균 ${(_sessionCount / 1).toStringAsFixed(1)}회' : '없음',
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
                      '충전 세션 기록 (오늘) ${_isSessionsExpanded ? '' : '보기'}',
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
                        '${_todaySessions.length}건',
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
            if (_isLoading)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_todaySessions.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.battery_charging_full,
                        size: 48,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                      ),
                      SizedBox(height: 16),
                      Text(
                        '오늘 충전 세션이 없습니다',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: _todaySessions.map((session) {
                    return ChargingSessionListItem(
                      session: session,
                      onTap: () {
                        // 세션 상세 정보 다이얼로그 표시
                        ChargingSessionDetailDialog.show(context, session);
                      },
                    );
                  }).toList(),
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
    if (current >= 1500) return '⚡ 급속';
    if (current >= 500) return '🟧 일반';
    return '🔵 저속';
  }
  
  /// 주 시간대 TimeSlot 반환
  TimeSlot _getMainTimeSlot() {
    if (_todaySessions.isEmpty) return TimeSlot.morning;
    
    final timeSlotCounts = <TimeSlot, int>{};
    for (final session in _todaySessions) {
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

  // 기존 _buildEnhancedSessionItem 메서드는 제거됨 (ChargingSessionListItem 사용)
}
