import 'package:flutter/material.dart';
import '../../../models/app_usage_models.dart';
import '../../../models/battery_insight_model.dart';
import '../../../services/daily_usage_stats_service.dart';
import '../../../services/battery_insight_service.dart';

/// 주간 달력 카드 위젯
/// 최근 7일간의 스크린타임을 달력 형태로 표시
/// 주간 통계 및 배터리 관점 인사이트 포함
class WeeklyCalendarCard extends StatefulWidget {
  final VoidCallback? onRefresh;
  
  const WeeklyCalendarCard({
    super.key,
    this.onRefresh,
  });

  @override
  State<WeeklyCalendarCard> createState() => _WeeklyCalendarCardState();
}

class _WeeklyCalendarCardState extends State<WeeklyCalendarCard> {
  final AppUsageManager _appUsageManager = AppUsageManager();
  List<DailyUsageStats> _weeklyStats = [];
  ScreenTimeSummary? _todaySummary;
  List<BatteryInsight> _insights = [];
  bool _isLoading = true;
  
  // 캐시 관리
  DateTime? _lastLoadTime;
  static const Duration _cacheValidityDuration = Duration(minutes: 5);

  @override
  void initState() {
    super.initState();
    _loadWeeklyData();
  }

  Future<void> _loadWeeklyData({bool clearCache = false}) async {
    // 캐시 확인 (새로고침이 아닌 경우)
    if (!clearCache && 
        _lastLoadTime != null && 
        _todaySummary != null &&
        DateTime.now().difference(_lastLoadTime!) < _cacheValidityDuration) {
      return; // 캐시된 데이터 사용
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 새로고침 시에만 캐시 클리어
      if (clearCache) {
        _appUsageManager.clearCache();
      }
      
      // 오늘 데이터 가져오기
      final todaySummary = await _appUsageManager.getScreenTimeSummary();
      
      // 주간 데이터 가져오기 (오늘 데이터 포함)
      final weeklyStats = await DailyUsageStatsService.getWeeklyStats(
        todaySummary: todaySummary,
      );
      
      // 배터리 인사이트 생성
      final insights = BatteryInsightService.generateWeeklyInsights(
        todaySummary: todaySummary,
        weeklyStats: weeklyStats,
      );
      
      setState(() {
        _todaySummary = todaySummary;
        _weeklyStats = weeklyStats;
        _insights = insights;
        _isLoading = false;
        _lastLoadTime = DateTime.now();
      });
    } catch (e) {
      debugPrint('주간 데이터 로드 실패: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 외부에서 새로고침 호출 가능
  Future<void> refresh() async {
    await _loadWeeklyData(clearCache: true);
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text('📅', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '주간 스크린타임 달력',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '최근 7일',
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // 새로고침 버튼
                IconButton(
                  icon: _isLoading 
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        )
                      : const Icon(Icons.refresh),
                  onPressed: _isLoading ? null : () async {
                    await refresh();
                    widget.onRefresh?.call();
                  },
                  tooltip: '새로고침',
                  iconSize: 20,
                ),
              ],
            ),
          ),
          
          // 달력 내용
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else if (_todaySummary == null || !_todaySummary!.hasPermission)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 48,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '사용 통계 권한이 필요합니다',
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
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // 요일 헤더
                  _buildWeekdayHeader(context),
                  const SizedBox(height: 8),
                  // 날짜 그리드
                  _buildCalendarGrid(context),
                  const SizedBox(height: 16),
                  // 구분선
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
                  ),
                  const SizedBox(height: 16),
                  // 주간 통계
                  _buildWeeklyStats(context),
                  // 인사이트 섹션
                  if (_insights.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
                    ),
                    const SizedBox(height: 16),
                    _buildInsightsSection(context),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// 요일 헤더 위젯 (월~일)
  Widget _buildWeekdayHeader(BuildContext context) {
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    
    return Row(
      children: weekdays.map((day) {
        return Expanded(
          child: Center(
            child: Text(
              day,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// 달력 그리드 위젯 (7일)
  Widget _buildCalendarGrid(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // 최근 7일 날짜 리스트 생성 (오래된 날짜부터)
    final List<DateTime> weekDates = [];
    for (int i = 6; i >= 0; i--) {
      weekDates.add(today.subtract(Duration(days: i)));
    }
    
    return Row(
      children: weekDates.map((date) {
        return Expanded(
          child: _buildDateCell(context, date, today),
        );
      }).toList(),
    );
  }

  /// 날짜 셀 위젯
  Widget _buildDateCell(BuildContext context, DateTime date, DateTime today) {
    final isToday = date.isAtSameMomentAs(today);
    
    // 해당 날짜의 데이터 찾기
    final dateKey = _getDateKey(date);
    final stats = _weeklyStats.firstWhere(
      (stat) => _getDateKey(stat.date) == dateKey,
      orElse: () => DailyUsageStats(
        date: date,
        screenTime: Duration.zero,
        backgroundTime: Duration.zero,
        totalUsageTime: Duration.zero,
        backgroundConsumptionPercent: 0.0,
        topAppName: '없음',
        topAppPercent: 0.0,
      ),
    );
    
    final hasData = stats.screenTime.inMilliseconds > 0;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        onTap: () => _showDateDetailBottomSheet(context, date, stats, isToday),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          decoration: BoxDecoration(
            color: isToday 
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isToday
                ? Border.all(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                    width: 1.5,
                  )
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 날짜 (일)
              Text(
                '${date.day}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                  color: isToday
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 4),
              // 스크린타임 표시
              if (hasData)
                Text(
                  _formatDuration(stats.screenTime),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                )
              else
                Text(
                  '-',
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// 날짜를 키 형식으로 변환 (YYYY-MM-DD)
  String _getDateKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
           '${date.month.toString().padLeft(2, '0')}-'
           '${date.day.toString().padLeft(2, '0')}';
  }

  /// Duration을 포맷팅된 문자열로 변환
  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  /// 주간 통계 계산
  Map<String, dynamic> _calculateWeeklyStats() {
    if (_weeklyStats.isEmpty) {
      return {
        'average': Duration.zero,
        'max': Duration.zero,
        'min': Duration.zero,
        'maxDate': null,
        'minDate': null,
        'yesterdayChange': Duration.zero,
        'hasData': false,
      };
    }

    // 데이터가 있는 날짜만 필터링
    final validStats = _weeklyStats.where((stat) => 
      stat.screenTime.inMilliseconds > 0
    ).toList();

    if (validStats.isEmpty) {
      return {
        'average': Duration.zero,
        'max': Duration.zero,
        'min': Duration.zero,
        'maxDate': null,
        'minDate': null,
        'yesterdayChange': Duration.zero,
        'hasData': false,
      };
    }

    // 평균 계산
    final totalMs = validStats.fold<int>(
      0,
      (sum, stat) => sum + stat.screenTime.inMilliseconds,
    );
    final average = Duration(milliseconds: totalMs ~/ validStats.length);

    // 최고/최저 찾기
    DailyUsageStats? maxStat;
    DailyUsageStats? minStat;
    
    for (final stat in validStats) {
      if (maxStat == null || stat.screenTime > maxStat.screenTime) {
        maxStat = stat;
      }
      if (minStat == null || stat.screenTime < minStat.screenTime) {
        minStat = stat;
      }
    }

    // 어제 대비 변화량 계산
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    
    final todayStat = _weeklyStats.firstWhere(
      (stat) => _getDateKey(stat.date) == _getDateKey(today),
      orElse: () => DailyUsageStats(
        date: today,
        screenTime: Duration.zero,
        backgroundTime: Duration.zero,
        totalUsageTime: Duration.zero,
        backgroundConsumptionPercent: 0.0,
        topAppName: '없음',
        topAppPercent: 0.0,
      ),
    );
    
    final yesterdayStat = _weeklyStats.firstWhere(
      (stat) => _getDateKey(stat.date) == _getDateKey(yesterday),
      orElse: () => DailyUsageStats(
        date: yesterday,
        screenTime: Duration.zero,
        backgroundTime: Duration.zero,
        totalUsageTime: Duration.zero,
        backgroundConsumptionPercent: 0.0,
        topAppName: '없음',
        topAppPercent: 0.0,
      ),
    );

    final yesterdayChange = todayStat.screenTime - yesterdayStat.screenTime;

    return {
      'average': average,
      'max': maxStat?.screenTime ?? Duration.zero,
      'min': minStat?.screenTime ?? Duration.zero,
      'maxDate': maxStat?.date,
      'minDate': minStat?.date,
      'yesterdayChange': yesterdayChange,
      'hasData': true,
    };
  }

  /// 주간 통계 UI
  Widget _buildWeeklyStats(BuildContext context) {
    final stats = _calculateWeeklyStats();
    
    if (!(stats['hasData'] as bool)) {
      return const SizedBox.shrink();
    }

    final average = stats['average'] as Duration;
    final max = stats['max'] as Duration;
    final min = stats['min'] as Duration;
    final maxDate = stats['maxDate'] as DateTime?;
    final minDate = stats['minDate'] as DateTime?;
    final yesterdayChange = stats['yesterdayChange'] as Duration;

    // 요일 이름 가져오기
    String getWeekdayName(DateTime? date) {
      if (date == null) return '';
      final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
      return weekdays[date.weekday - 1];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 제목
        Text(
          '📈 주간 통계',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        // 통계 그리드
        Row(
          children: [
            // 평균
            Expanded(
              child: _buildStatItem(
                context,
                label: '평균',
                value: _formatDuration(average),
                icon: '📊',
              ),
            ),
            const SizedBox(width: 8),
            // 최고
            Expanded(
              child: _buildStatItem(
                context,
                label: '최고',
                value: _formatDuration(max),
                subtitle: maxDate != null ? '${getWeekdayName(maxDate)}요일' : '',
                icon: '⬆️',
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 8),
            // 최저
            Expanded(
              child: _buildStatItem(
                context,
                label: '최저',
                value: _formatDuration(min),
                subtitle: minDate != null ? '${getWeekdayName(minDate)}요일' : '',
                icon: '⬇️',
                color: Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // 어제 대비 변화량
        if (yesterdayChange.inMilliseconds != 0)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: yesterdayChange.inMilliseconds > 0
                  ? Colors.orange.withValues(alpha: 0.1)
                  : Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: yesterdayChange.inMilliseconds > 0
                    ? Colors.orange.withValues(alpha: 0.3)
                    : Colors.green.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Text(
                  yesterdayChange.inMilliseconds > 0 ? '⬆️' : '⬇️',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '어제 대비 ${yesterdayChange.inMilliseconds > 0 ? '증가' : '감소'}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatDuration(yesterdayChange.abs()),
                        style: TextStyle(
                          fontSize: 12,
                          color: yesterdayChange.inMilliseconds > 0
                              ? Colors.orange
                              : Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// 통계 아이템 위젯
  Widget _buildStatItem(
    BuildContext context, {
    required String label,
    required String value,
    String subtitle = '',
    required String icon,
    Color? color,
  }) {
    final itemColor = color ?? Theme.of(context).colorScheme.primary;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: itemColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: itemColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: itemColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          // subtitle이 없어도 동일한 높이를 유지하기 위해 항상 공간 확보
          const SizedBox(height: 2),
          SizedBox(
            height: 14, // subtitle 텍스트 높이와 동일하게 고정
            child: subtitle.isNotEmpty
                ? Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 10,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  /// 배터리 인사이트 섹션
  Widget _buildInsightsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 제목
        Text(
          '💡 배터리 관점 인사이트',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        // 인사이트 리스트
        ..._insights.map((insight) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildInsightItem(context, insight),
        )),
      ],
    );
  }

  /// 인사이트 아이템 위젯
  Widget _buildInsightItem(BuildContext context, BatteryInsight insight) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: insight.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: insight.color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 아이콘
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: insight.color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              insight.icon,
              color: insight.color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          // 내용
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 제목
                Text(
                  insight.title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // 메시지
                Text(
                  insight.message,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // 권장사항
                Text(
                  insight.recommendation,
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 날짜 상세 정보 바텀시트 표시
  void _showDateDetailBottomSheet(
    BuildContext context,
    DateTime date,
    DailyUsageStats stats,
    bool isToday,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 드래그 핸들
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // 헤더
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // 날짜 정보
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Text(
                              '${date.year}년 ${date.month}월 ${date.day}일',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            if (isToday) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '오늘',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getWeekdayName(date),
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 닫기 버튼
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: '닫기',
                  ),
                ],
              ),
            ),
            // 내용
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 스크린타임 요약
                    _buildDetailSection(
                      context,
                      title: '📱 스크린타임',
                      children: [
                        _buildDetailItem(
                          context,
                          label: '화면 사용 시간',
                          value: _formatDuration(stats.screenTime),
                          icon: Icons.phone_android,
                          color: Colors.blue,
                        ),
                        const SizedBox(height: 12),
                        _buildDetailItem(
                          context,
                          label: '백그라운드 시간',
                          value: _formatDuration(stats.backgroundTime),
                          icon: Icons.settings_backup_restore,
                          color: Colors.orange,
                        ),
                        const SizedBox(height: 12),
                        _buildDetailItem(
                          context,
                          label: '총 사용 시간',
                          value: _formatDuration(stats.totalUsageTime),
                          icon: Icons.access_time,
                          color: Colors.purple,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // 배터리 소모 정보
                    _buildDetailSection(
                      context,
                      title: '🔋 배터리 소모',
                      children: [
                        _buildDetailItem(
                          context,
                          label: '백그라운드 소모 비율',
                          value: '${stats.backgroundConsumptionPercent.toStringAsFixed(1)}%',
                          icon: Icons.battery_alert,
                          color: stats.backgroundConsumptionPercent > 30
                              ? Colors.red
                              : stats.backgroundConsumptionPercent > 15
                                  ? Colors.orange
                                  : Colors.green,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // 최고 사용 앱
                    if (stats.topAppName != '없음' && stats.topAppPercent > 0)
                      _buildDetailSection(
                        context,
                        title: '🏆 최고 사용 앱',
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.apps,
                                    color: Theme.of(context).colorScheme.primary,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        stats.topAppName,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).colorScheme.onSurface,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '전체 스크린타임의 ${stats.topAppPercent.toStringAsFixed(1)}%',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    // 데이터가 없는 경우
                    if (stats.screenTime.inMilliseconds == 0)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 48,
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                '이 날짜에는 사용 데이터가 없습니다',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    // 하단 여백
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 상세 정보 섹션 위젯
  Widget _buildDetailSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  /// 상세 정보 아이템 위젯
  Widget _buildDetailItem(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 요일 이름 가져오기
  String _getWeekdayName(DateTime date) {
    const weekdays = ['월요일', '화요일', '수요일', '목요일', '금요일', '토요일', '일요일'];
    return weekdays[date.weekday - 1];
  }
}

