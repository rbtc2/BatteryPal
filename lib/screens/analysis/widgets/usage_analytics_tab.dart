import 'package:flutter/material.dart';
import 'dart:convert';
import '../../../models/app_usage_models.dart';
import '../../../services/daily_usage_stats_service.dart';
import '../../../services/permission_helper.dart';

/// 사용 패턴 탭 - 완전히 새로 구현된 스켈레톤 UI
/// 
/// 🎯 주요 기능:
/// 1. TodaySummaryCard: 오늘의 배터리 사용 현황 요약
/// 2. AppBatteryUsageCard: 앱별 배터리 소모 분석 (메인)
/// 3. UsageTrendCard: 사용 트렌드 비교
/// 
/// 📱 구현된 섹션:
/// - 오늘의 요약: 스크린 타임, 백그라운드 소모, 총 사용 시간
/// - 앱별 소모: 5개 앱 + 기타 앱들의 배터리 소모 분석
/// - 사용 트렌드: 오늘 vs 어제 비교 (스크린 타임, 배터리 소모, 최고 앱)
/// 
/// 🎨 디자인 특징:
/// - 일관된 색상 시스템 (심각도별 색상)
/// - 반응형 레이아웃 (오버플로우 방지)
/// - 직관적 인터랙션 (펼치기/접기 기능)
/// - 다크모드/라이트모드 완벽 지원
/// 
/// ⚡ 성능 최적화:
/// - const 생성자 사용으로 불필요한 리빌드 방지
/// - StatelessWidget 활용으로 메모리 효율성
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
  final GlobalKey<_UsageTrendCardState> _trendCardKey = GlobalKey<_UsageTrendCardState>();

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
            
            // 섹션 2: 앱별 배터리 소모 (메인)
            AppBatteryUsageCard(
              key: _appUsageKey,
              onRefresh: _handleRefresh,
            ),
            
            const SizedBox(height: 16),
            
            // 섹션 3: 사용 트렌드
            UsageTrendCard(
              key: _trendCardKey,
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
        _trendCardKey.currentState?.refresh() ?? Future.value(),
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
                Text('📊', style: TextStyle(fontSize: 24)),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '오늘의 배터리 사용',
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
                      : Icon(Icons.refresh),
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
                    icon: Icon(Icons.settings),
                    onPressed: _handlePermissionRequest,
                    tooltip: '사용 통계 권한 설정',
                    iconSize: 20,
                  ),
              ],
            ),
          ),
          
          // 3개 메트릭 (가로 배치)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    context,
                    icon: '📱',
                    label: '스크린 타임',
                    value: _getScreenTimeValue(),
                    color: Colors.blue,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    context,
                    icon: '🔋',
                    label: '백그라운드 소모',
                    value: _getBackgroundConsumptionValue(),
                    color: Colors.orange,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    context,
                    icon: '⏱️',
                    label: '총 사용 시간',
                    value: _getTotalUsageTimeValue(),
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 16),
          
          // 인사이트 또는 권한 요청 메시지
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildInsightOrPermissionMessage(context),
          ),
          
          SizedBox(height: 16),
        ],
      ),
    );
  }

  String _getScreenTimeValue() {
    if (_isLoading) return '로딩 중...';
    if (_summary == null || !_summary!.hasPermission) {
      return '권한 필요';
    }
    return _summary!.formattedTotalScreenTime;
  }

  String _getBackgroundConsumptionValue() {
    if (_isLoading) return '로딩 중...';
    if (_summary == null || !_summary!.hasPermission) {
      return '권한 필요';
    }
    // Phase 2 완료: 실제 백그라운드 소모 비율 계산
    return _summary!.formattedBackgroundConsumptionPercent;
  }

  String _getTotalUsageTimeValue() {
    if (_isLoading) return '로딩 중...';
    if (_summary == null || !_summary!.hasPermission) {
      return '권한 필요';
    }
    return _summary!.formattedTotalUsageTime;
  }

  Widget _buildInsightOrPermissionMessage(BuildContext context) {
    if (_isLoading) {
      return Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                '데이터를 불러오는 중...',
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_summary == null || !_summary!.hasPermission) {
      return Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.orange.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, size: 18, color: Colors.orange[700]),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                '사용 통계 권한이 필요합니다. 설정에서 권한을 허용해주세요.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.orange[700],
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    // Phase 4 완료: 실제 트렌드 데이터 표시
    String insightText = '데이터를 확인할 수 없습니다';
    Color insightColor = Colors.grey;
    
    if (_yesterdayStats != null && _summary != null) {
      final change = _summary!.totalScreenTime - _yesterdayStats!.screenTime;
      final changeMinutes = change.inMinutes;
      
      if (changeMinutes > 0) {
        final hours = change.inHours;
        final minutes = change.inMinutes % 60;
        if (hours > 0) {
          insightText = '어제보다 스크린 타임 $hours시간 $minutes분 증가';
        } else {
          insightText = '어제보다 스크린 타임 $minutes분 증가';
        }
        insightColor = Colors.blue;
      } else if (changeMinutes < 0) {
        final hours = (-change).inHours;
        final minutes = (-change).inMinutes % 60;
        if (hours > 0) {
          insightText = '어제보다 스크린 타임 $hours시간 $minutes분 감소';
        } else {
          insightText = '어제보다 스크린 타임 $minutes분 감소';
        }
        insightColor = Colors.green;
      } else {
        insightText = '어제와 동일한 스크린 타임';
        insightColor = Colors.grey;
      }
    } else {
      insightText = '어제 데이터가 없습니다';
      insightColor = Colors.grey;
    }
    
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: insightColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: insightColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Text('💡', style: TextStyle(fontSize: 18)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              insightText,
              style: TextStyle(
                fontSize: 13,
                color: _getColorShade(insightColor),
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
  
  Color _getColorShade(Color color) {
    if (color == Colors.blue) return Colors.blue[700]!;
    if (color == Colors.green) return Colors.green[700]!;
    if (color == Colors.orange) return Colors.orange[700]!;
    return color;
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
                  child: Text(
                    '앱별 배터리 소모 (오늘)',
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

/// 섹션 3: 사용 트렌드 비교
class UsageTrendCard extends StatefulWidget {
  final VoidCallback? onRefresh;
  
  const UsageTrendCard({
    super.key,
    this.onRefresh,
  });

  @override
  State<UsageTrendCard> createState() => _UsageTrendCardState();
}

class _UsageTrendCardState extends State<UsageTrendCard> {
  final AppUsageManager _appUsageManager = AppUsageManager();
  ScreenTimeSummary? _todaySummary;
  DailyUsageStats? _yesterdayStats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTrendData();
  }

  Future<void> _loadTrendData({bool clearCache = false}) async {
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
      
      // 어제 데이터 가져오기
      final yesterdayStats = await DailyUsageStatsService.getYesterdayStatsImproved();
      
      setState(() {
        _todaySummary = todaySummary;
        _yesterdayStats = yesterdayStats;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('트렌드 데이터 로드 실패: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 외부에서 새로고침 호출 가능
  Future<void> refresh() async {
    await _loadTrendData(clearCache: true);
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('📈', style: TextStyle(fontSize: 24)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '사용 트렌드',
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
                SizedBox(height: 8),
                Text(
                  '오늘 vs 어제',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          
          // 로딩 또는 트렌드 아이템들
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.all(32),
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
                  _buildScreenTimeTrendItem(context),
                  SizedBox(height: 12),
                  _buildBackgroundConsumptionTrendItem(context),
                  SizedBox(height: 12),
                  _buildTopAppItem(context),
                ],
              ),
            ),
          
          SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildScreenTimeTrendItem(BuildContext context) {
    final todayScreenTime = _todaySummary!.formattedTotalScreenTime;
    final yesterdayScreenTime = _yesterdayStats?.screenTime;
    
    String changeText = '데이터 없음';
    bool isIncrease = false;
    
    if (yesterdayScreenTime != null) {
      final change = _todaySummary!.totalScreenTime - yesterdayScreenTime;
      final changeMinutes = change.inMinutes;
      
      if (changeMinutes > 0) {
        changeText = '⬆️ ${_formatDuration(change)} 증가';
        isIncrease = true;
      } else if (changeMinutes < 0) {
        changeText = '⬇️ ${_formatDuration(-change)} 감소';
        isIncrease = false;
      } else {
        changeText = '➡️ 변화 없음';
        isIncrease = false;
      }
    }
    
    return _buildTrendItem(
      context,
      label: '스크린 타임',
      today: todayScreenTime,
      yesterday: yesterdayScreenTime != null 
          ? _formatDuration(yesterdayScreenTime)
          : '데이터 없음',
      change: changeText,
      isIncrease: isIncrease,
    );
  }

  Widget _buildBackgroundConsumptionTrendItem(BuildContext context) {
    final todayPercent = _todaySummary!.formattedBackgroundConsumptionPercent;
    final yesterdayPercent = _yesterdayStats?.backgroundConsumptionPercent;
    
    String changeText = '데이터 없음';
    bool isIncrease = false;
    
    if (yesterdayPercent != null) {
      final change = _todaySummary!.backgroundConsumptionPercent - yesterdayPercent;
      
      if (change > 0.1) {
        changeText = '⬆️ ${change.toStringAsFixed(1)}%p 증가';
        isIncrease = true;
      } else if (change < -0.1) {
        changeText = '⬇️ ${(-change).toStringAsFixed(1)}%p 감소';
        isIncrease = false;
      } else {
        changeText = '➡️ 변화 없음';
        isIncrease = false;
      }
    }
    
    return _buildTrendItem(
      context,
      label: '백그라운드 소모',
      today: todayPercent,
      yesterday: yesterdayPercent != null 
          ? '${yesterdayPercent.toStringAsFixed(1)}%'
          : '데이터 없음',
      change: changeText,
      isIncrease: isIncrease,
    );
  }

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
  
  Widget _buildTrendItem(
    BuildContext context, {
    required String label,
    required String today,
    required String yesterday,
    required String change,
    required bool isIncrease,
  }) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      today,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2),
                    Text(
                      '오늘',
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 30,
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      yesterday,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2),
                    Text(
                      '어제',
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isIncrease 
                  ? Colors.orange.withValues(alpha: 0.1)
                  : Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              change,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isIncrease ? Colors.orange[700] : Colors.green[700],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTopAppItem(BuildContext context) {
    final todayTopApp = _todaySummary!.topApps.isNotEmpty 
        ? _todaySummary!.topApps.first 
        : null;
    final yesterdayTopAppName = _yesterdayStats?.topAppName;
    final yesterdayTopAppPercent = _yesterdayStats?.topAppPercent;
    
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.withValues(alpha: 0.1),
            Colors.purple.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.purple.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '가장 많이 쓴 앱',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 8),
          if (todayTopApp != null)
            _buildAppComparisonRow(
              context,
              label: '오늘',
              app: todayTopApp.appName,
              percent: todayTopApp.formattedBatteryPercent,
              color: todayTopApp.color,
            )
          else
            _buildAppComparisonRow(
              context,
              label: '오늘',
              app: '없음',
              percent: '0%',
              color: Colors.grey,
            ),
          SizedBox(height: 6),
          if (yesterdayTopAppName != null && yesterdayTopAppPercent != null)
            _buildAppComparisonRow(
              context,
              label: '어제',
              app: yesterdayTopAppName,
              percent: '${yesterdayTopAppPercent.toStringAsFixed(1)}%',
              color: Colors.purple[400]!,
            )
          else
            _buildAppComparisonRow(
              context,
              label: '어제',
              app: '데이터 없음',
              percent: '-',
              color: Colors.grey,
            ),
        ],
      ),
    );
  }
  
  Widget _buildAppComparisonRow(
    BuildContext context, {
    required String label,
    required String app,
    required String percent,
    required Color color,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 40,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            app,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        SizedBox(width: 8),
        Text(
          percent,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}