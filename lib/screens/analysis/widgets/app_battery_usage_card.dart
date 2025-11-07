import 'package:flutter/material.dart';
import 'dart:convert';
import '../../../models/app_usage_models.dart';

/// 섹션 2: 앱별 배터리 소모 분석 (메인 기능)
class AppBatteryUsageCard extends StatefulWidget {
  final VoidCallback? onRefresh;
  
  const AppBatteryUsageCard({
    super.key,
    this.onRefresh,
  });

  @override
  State<AppBatteryUsageCard> createState() => AppBatteryUsageCardState();
}

class AppBatteryUsageCardState extends State<AppBatteryUsageCard> {
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

