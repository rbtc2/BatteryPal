import 'package:flutter/material.dart';
import '../../../models/app_usage_models.dart';
import '../../../services/daily_usage_stats_service.dart';
import '../../../services/permission_helper.dart';

/// 섹션 1: 오늘의 배터리 사용 현황 요약
class TodaySummaryCard extends StatefulWidget {
  final VoidCallback? onRefresh;
  
  const TodaySummaryCard({
    super.key,
    this.onRefresh,
  });

  @override
  State<TodaySummaryCard> createState() => TodaySummaryCardState();
}

class TodaySummaryCardState extends State<TodaySummaryCard> {
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

