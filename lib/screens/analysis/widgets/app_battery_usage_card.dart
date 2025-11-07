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
  ScreenTimeSummary? _summary; // 비율 계산에 사용
  bool _isLoading = true;
  bool _showAll = false;
  UsageType _selectedUsageType = UsageType.foreground;
  
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
        _summary = summary;
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
    // 선택된 타입에 따라 정렬된 앱 리스트
    List<RealAppUsageData> sortedApps;
    if (_summary != null) {
      sortedApps = List<RealAppUsageData>.from(_apps);
      sortedApps.sort((a, b) {
        final aPercent = a.getPercentByType(
          _selectedUsageType,
          _summary!.totalScreenTime,
          _summary!.backgroundTime,
        );
        final bPercent = b.getPercentByType(
          _selectedUsageType,
          _summary!.totalScreenTime,
          _summary!.backgroundTime,
        );
        return bPercent.compareTo(aPercent); // 내림차순 정렬
      });
    } else {
      sortedApps = _apps;
    }
    
    // 기타 앱들의 배터리 소모 비율 계산
    final displayedApps = _showAll ? sortedApps : sortedApps.take(4).toList();
    final displayedAppsPercent = _summary != null
        ? displayedApps.fold<double>(
            0.0,
            (sum, app) => sum + app.getPercentByType(
              _selectedUsageType,
              _summary!.totalScreenTime,
              _summary!.backgroundTime,
            ),
          )
        : displayedApps.fold<double>(
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
                        _selectedUsageType == UsageType.foreground
                            ? '포그라운드 사용량 (오늘)'
                            : '백그라운드 사용량 (오늘)',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _selectedUsageType == UsageType.foreground
                            ? '화면이 켜져 있고 앱을 직접 사용하는 시간'
                            : '앱이 실행 중이지만 화면에 보이지 않는 시간',
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
          
          // SegmentedButton (포그라운드/백그라운드 선택)
          if (!_isLoading && _apps.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SegmentedButton<UsageType>(
                segments: const [
                  ButtonSegment<UsageType>(
                    value: UsageType.foreground,
                    label: Text('포그라운드'),
                    icon: Icon(Icons.phone_android, size: 16),
                  ),
                  ButtonSegment<UsageType>(
                    value: UsageType.background,
                    label: Text('백그라운드'),
                    icon: Icon(Icons.apps, size: 16),
                  ),
                ],
                selected: {_selectedUsageType},
                onSelectionChanged: (Set<UsageType> newSelection) {
                  setState(() {
                    _selectedUsageType = newSelection.first;
                    _showAll = false; // 타입 변경 시 리스트 초기화
                  });
                },
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
                    _buildOtherAppsItem(context, otherAppsPercent, sortedApps.length)
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
    // 선택된 타입에 따른 비율 계산
    final percent = _summary != null
        ? app.getPercentByType(
            _selectedUsageType,
            _summary!.totalScreenTime,
            _summary!.backgroundTime,
          )
        : app.batteryPercent;
    final formattedPercent = _summary != null
        ? app.getFormattedPercentByType(
            _selectedUsageType,
            _summary!.totalScreenTime,
            _summary!.backgroundTime,
          )
        : app.formattedBatteryPercent;
    
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
                formattedPercent,
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
              value: (percent / 100).clamp(0.0, 1.0),
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
  
  Widget _buildOtherAppsItem(BuildContext context, double percent, int totalAppsCount) {
    final otherAppsCount = (totalAppsCount - 4).clamp(0, totalAppsCount);
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
                '기타 ($otherAppsCount개 앱)',
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

