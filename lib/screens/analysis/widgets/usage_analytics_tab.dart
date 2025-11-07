import 'package:flutter/material.dart';
import 'dart:convert';
import '../../../models/app_usage_models.dart';
import '../../../services/daily_usage_stats_service.dart';
import '../../../services/permission_helper.dart';
import 'weekly_calendar_card.dart';

/// 사용 패턴 탭 - 완전히 새로 구현된 스켈레톤 UI
/// 
/// 🎯 주요 기능:
/// 1. TodaySummaryCard: 오늘의 스크린타임 대시보드 (큰 숫자 + 어제 대비)
/// 2. WeeklyCalendarCard: 주간 달력 + 통계 + 배터리 인사이트 (NEW!)
/// 3. AppBatteryUsageCard: 앱별 배터리 소모 분석 (메인)
/// 
/// 📱 구현된 섹션:
/// - 오늘의 대시보드: 큰 스크린타임 숫자, 어제 대비 변화량, 3개 메트릭 박스
/// - 주간 달력: 최근 7일 스크린타임 달력, 주간 통계, 배터리 관점 인사이트
/// - 앱별 소모: 5개 앱 + 기타 앱들의 배터리 소모 분석
/// 
/// 🎨 디자인 특징:
/// - 일관된 색상 시스템 (심각도별 색상)
/// - 반응형 레이아웃 (오버플로우 방지)
/// - 직관적 인터랙션 (펼치기/접기 기능)
/// - 다크모드/라이트모드 완벽 지원
/// 
/// ⚡ 성능 최적화:
/// - const 생성자 사용으로 불필요한 리빌드 방지
/// - 데이터 캐싱 (5분 유효기간)
/// - 텍스트 줄바꿈 방지로 레이아웃 안정성

/// 사용 패턴 탭 - 메인 위젯
class UsageAnalyticsTab extends StatefulWidget {
  final bool isProUser;
  final VoidCallback? onProUpgrade;

  const UsageAnalyticsTab({
    super.key,
    required this.isProUser,
    this.onProUpgrade,
  });

  @override
  State<UsageAnalyticsTab> createState() => _UsageAnalyticsTabState();
}

class _UsageAnalyticsTabState extends State<UsageAnalyticsTab> {
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
  final GlobalKey<_TodaySummaryCardState> _todaySummaryKey = GlobalKey<_TodaySummaryCardState>();
  final GlobalKey<_AppBatteryUsageCardState> _appUsageKey = GlobalKey<_AppBatteryUsageCardState>();

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      key: _refreshIndicatorKey,
      onRefresh: _handleRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(), // 항상 스크롤 가능하도록
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 섹션 1: 오늘의 요약
            TodaySummaryCard(
              key: _todaySummaryKey,
              onRefresh: _handleRefresh,
            ),
            
            const SizedBox(height: 16),
            
            // 섹션 2: 주간 달력 (NEW!)
            WeeklyCalendarCard(
              onRefresh: _handleRefresh,
            ),
            
            const SizedBox(height: 16),
            
            // 섹션 3: 앱별 배터리 소모 (메인)
            AppBatteryUsageCard(
              key: _appUsageKey,
              onRefresh: _handleRefresh,
            ),
            
            // 하단 여백
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  /// 전체 새로고침 처리
  Future<void> _handleRefresh() async {
    try {
      // 캐시 클리어
      final appUsageManager = AppUsageManager();
      appUsageManager.clearCache();
      
      // 모든 카드 새로고침
      await Future.wait([
        _todaySummaryKey.currentState?.refresh() ?? Future.value(),
        _appUsageKey.currentState?.refresh() ?? Future.value(),
      ]);
    } catch (e) {
      debugPrint('전체 새로고침 실패: $e');
    }
  }
}

/// 섹션 1: 오늘의 배터리 사용 현황 요약
class TodaySummaryCard extends StatefulWidget {
  final VoidCallback? onRefresh;
  
  const TodaySummaryCard({
    super.key,
    this.onRefresh,
  });

  @override
  State<TodaySummaryCard> createState() => _TodaySummaryCardState();
}

class _TodaySummaryCardState extends State<TodaySummaryCard> {
  final AppUsageManager _appUsageManager = AppUsageManager();
  ScreenTimeSummary? _summary;
  DailyUsageStats? _yesterdayStats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadScreenTimeData();
  }

  Future<void> _loadScreenTimeData({bool clearCache = false}) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 새로고침 시에만 캐시 클리어
      if (clearCache) {
        _appUsageManager.clearCache();
      }
      
      final summary = await _appUsageManager.getScreenTimeSummary();
      final yesterdayStats = await DailyUsageStatsService.getYesterdayStatsImproved();
      
      setState(() {
        _summary = summary;
        _yesterdayStats = yesterdayStats;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('스크린 타임 데이터 로드 실패: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 외부에서 새로고침 호출 가능
  Future<void> refresh() async {
    await _loadScreenTimeData(clearCache: true);
  }

  Future<void> _handlePermissionRequest() async {
    // 개선된 권한 요청: 다이얼로그를 먼저 표시하고 사용자가 허용하면 설정으로 이동
    final granted = await PermissionHelper.requestUsageStatsPermission(context);
    if (granted) {
      // 권한이 허용되었으면 데이터 새로고침
      await _loadScreenTimeData(clearCache: true);
    }
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
                const Text('📱', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '오늘의 스크린타임',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
                // 권한이 없으면 권한 설정 버튼
                if (!_isLoading && 
                    (_summary == null || !_summary!.hasPermission))
                  IconButton(
                    icon: const Icon(Icons.settings),
                    onPressed: _handlePermissionRequest,
                    tooltip: '사용 통계 권한 설정',
                    iconSize: 20,
                  ),
              ],
            ),
          ),
          
          // 메인 스크린타임 표시 (큰 숫자)
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else if (_summary == null || !_summary!.hasPermission)
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
                  // 큰 스크린타임 숫자
                  Text(
                    _summary!.formattedTotalScreenTime,
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  // 어제 대비 변화량
                  _buildYesterdayComparison(context),
                  const SizedBox(height: 24),
                  // 3개 메트릭 (가로 배치)
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          context,
                          icon: '📱',
                          label: '포그라운드',
                          value: _summary!.formattedTotalScreenTime,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricCard(
                          context,
                          icon: '🔋',
                          label: '백그라운드',
                          value: _summary!.formattedBackgroundTime,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricCard(
                          context,
                          icon: '⏱️',
                          label: '총 사용',
                          value: _summary!.formattedTotalUsageTime,
                          color: Colors.purple,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// 어제 대비 변화량 표시
  Widget _buildYesterdayComparison(BuildContext context) {
    if (_yesterdayStats == null) {
      return Text(
        '어제 데이터 없음',
        style: TextStyle(
          fontSize: 13,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
        ),
      );
    }

    final change = _summary!.totalScreenTime - _yesterdayStats!.screenTime;
    final changeMinutes = change.inMinutes;
    
    if (changeMinutes == 0) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '➡️',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(width: 4),
          Text(
            '어제와 동일',
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }

    final isIncrease = changeMinutes > 0;
    final changeText = _formatDuration(change.abs());
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          isIncrease ? '⬆️' : '⬇️',
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(width: 4),
        Text(
          '어제보다 ${isIncrease ? '증가' : '감소'}',
          style: TextStyle(
            fontSize: 13,
            color: isIncrease 
                ? Colors.orange 
                : Colors.green,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          changeText,
          style: TextStyle(
            fontSize: 13,
            color: isIncrease 
                ? Colors.orange 
                : Colors.green,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// Duration을 포맷팅된 문자열로 변환
  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    
    if (hours > 0) {
      return '$hours시간 $minutes분';
    } else if (minutes > 0) {
      return '$minutes분';
    } else {
      return '${duration.inSeconds}초';
    }
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required String icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: TextStyle(fontSize: 24)),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// 섹션 2: 앱별 배터리 소모 분석 (메인 기능)
class AppBatteryUsageCard extends StatefulWidget {
  final VoidCallback? onRefresh;
  
  const AppBatteryUsageCard({
    super.key,
    this.onRefresh,
  });

  @override
  State<AppBatteryUsageCard> createState() => _AppBatteryUsageCardState();
}

class _AppBatteryUsageCardState extends State<AppBatteryUsageCard> {
  final AppUsageManager _appUsageManager = AppUsageManager();
  List<RealAppUsageData> _apps = [];
  bool _isLoading = true;
  bool _showAll = false;
  
  @override
  void initState() {
    super.initState();
    _loadAppUsageData();
  }

  Future<void> _loadAppUsageData({bool clearCache = false}) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 새로고침 시에만 캐시 클리어
      if (clearCache) {
        _appUsageManager.clearCache();
      }
      
      final summary = await _appUsageManager.getScreenTimeSummary();
      setState(() {
        _apps = summary.topApps;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('앱 사용 데이터 로드 실패: $e');
      setState(() {
        _apps = [];
        _isLoading = false;
      });
    }
  }

  /// 외부에서 새로고침 호출 가능
  Future<void> refresh() async {
    await _loadAppUsageData(clearCache: true);
  }

  @override
  Widget build(BuildContext context) {
    // 기타 앱들의 배터리 소모 비율 계산
    final displayedApps = _showAll ? _apps : _apps.take(4).toList();
    final displayedAppsPercent = displayedApps.fold<double>(
      0.0,
      (sum, app) => sum + app.batteryPercent,
    );
    final otherAppsPercent = _showAll ? 0.0 : (100.0 - displayedAppsPercent).clamp(0.0, 100.0);
    
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
            offset: Offset(0, 2),
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
                Text('📱', style: TextStyle(fontSize: 24)),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '앱별 사용 시간 비율 (오늘)',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '스크린 타임 기준 비율 (실제 배터리 소모와 다를 수 있음)',
                        style: TextStyle(
                          fontSize: 11,
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
                      : Icon(Icons.refresh),
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
          
          // 로딩 또는 앱 리스트
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      '앱 사용 데이터를 불러오는 중...',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (_apps.isEmpty)
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
                    SizedBox(height: 16),
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
                  ...displayedApps.map((app) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildAppItem(context, app),
                  )),
                  
                  // "기타" 또는 "전체 보기" 버튼
                  if (!_showAll && otherAppsPercent > 0)
                    _buildOtherAppsItem(context, otherAppsPercent)
                  else if (_showAll)
                    SizedBox(height: 4),
                ],
              ),
            ),
          
          SizedBox(height: 16),
        ],
      ),
    );
  }
  
  Widget _buildAppItem(BuildContext context, RealAppUsageData app) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: app.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: app.color.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 앱 이름 + 퍼센트
          Row(
            children: [
              // 앱 아이콘 또는 색상 점
              if (app.appIcon != null && app.appIcon!.isNotEmpty)
                Container(
                  width: 24,
                  height: 24,
                  margin: EdgeInsets.only(right: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.memory(
                      base64Decode(app.appIcon!),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        // 아이콘 로드 실패 시 폴백
                        return Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: app.color.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(Icons.apps, size: 16, color: app.color),
                        );
                      },
                    ),
                  ),
                )
              else
                Container(
                  width: 8,
                  height: 8,
                  margin: EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: app.color,
                    shape: BoxShape.circle,
                  ),
                ),
              Expanded(
                child: Text(
                  app.appName,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                app.formattedBatteryPercent,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: app.color,
                ),
              ),
            ],
          ),
          
          SizedBox(height: 8),
          
          // 진행 바
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (app.batteryPercent / 100).clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(app.color),
            ),
          ),
          
          SizedBox(height: 8),
          
          // 스크린 vs 백그라운드 시간
          Row(
            children: [
              Expanded(
                child: _buildTimeChip(
                  context,
                  icon: Icons.phone_android,
                  label: '스크린',
                  time: app.formattedScreenTime,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _buildTimeChip(
                  context,
                  icon: Icons.apps,
                  label: '백그라운드',
                  time: app.formattedBackgroundTime,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildTimeChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String time,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
          SizedBox(width: 4),
          Flexible(
            child: Text(
              time,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildOtherAppsItem(BuildContext context, double percent) {
    return InkWell(
      onTap: () {
        setState(() {
          _showAll = !_showAll;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.grey,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                '기타 (${(_apps.length - 4).clamp(0, _apps.length)}개 앱)',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '${percent.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            SizedBox(width: 8),
            Icon(
              _showAll ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
  
}
