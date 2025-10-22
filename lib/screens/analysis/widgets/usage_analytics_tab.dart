import 'package:flutter/material.dart';
import '../../../models/app_usage_models.dart';

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
class UsageAnalyticsTab extends StatelessWidget {
  final bool isProUser;
  final VoidCallback? onProUpgrade;

  const UsageAnalyticsTab({
    super.key,
    required this.isProUser,
    this.onProUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 섹션 1: 오늘의 요약
          const TodaySummaryCard(),
          
          const SizedBox(height: 16),
          
          // 섹션 2: 앱별 배터리 소모 (메인)
          const AppBatteryUsageCard(),
          
          const SizedBox(height: 16),
          
          // 섹션 3: 사용 트렌드
          const UsageTrendCard(),
          
          // 하단 여백
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

/// 섹션 1: 오늘의 배터리 사용 현황 요약
class TodaySummaryCard extends StatefulWidget {
  const TodaySummaryCard({super.key});

  @override
  State<TodaySummaryCard> createState() => _TodaySummaryCardState();
}

class _TodaySummaryCardState extends State<TodaySummaryCard> {
  final AppUsageManager _appUsageManager = AppUsageManager();
  ScreenTimeSummary? _summary;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadScreenTimeData();
  }

  Future<void> _loadScreenTimeData() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      final summary = await _appUsageManager.getScreenTimeSummary();
      
      setState(() {
        _summary = summary;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  Future<void> _handlePermissionRequest() async {
    await _appUsageManager.openPermissionSettings();
    // 설정에서 돌아온 후 데이터 새로고침
    await _loadScreenTimeData();
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
              ],
            ),
          ),
          
          // 3개 메트릭 (가로 배치)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildMetricsRow(context),
          ),
          
          SizedBox(height: 16),
          
          // 인사이트
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.blue.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Text('💡', style: TextStyle(fontSize: 18)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '어제보다 스크린 타임 15분 증가',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue[700],
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildMetricsRow(BuildContext context) {
    if (_isLoading) {
      return Row(
        children: [
          Expanded(child: _buildLoadingMetricCard(context)),
          SizedBox(width: 12),
          Expanded(child: _buildLoadingMetricCard(context)),
          SizedBox(width: 12),
          Expanded(child: _buildLoadingMetricCard(context)),
        ],
      );
    }

    if (_hasError || _summary == null) {
      return Row(
        children: [
          Expanded(child: _buildErrorState(context)),
          SizedBox(width: 12),
          Expanded(child: SizedBox()), // 빈 공간
          SizedBox(width: 12),
          Expanded(child: SizedBox()), // 빈 공간
        ],
      );
    }

    if (!_summary!.hasPermission) {
      return Row(
        children: [
          Expanded(child: _buildPermissionRequest(context)),
          SizedBox(width: 12),
          Expanded(child: SizedBox()), // 빈 공간
          SizedBox(width: 12),
          Expanded(child: SizedBox()), // 빈 공간
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            context,
            icon: '📱',
            label: '스크린 타임',
            value: _summary!.formattedTotalScreenTime,
            color: Colors.blue,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            context,
            icon: '🔋',
            label: '백그라운드 소모',
            value: _summary!.formattedBackgroundConsumptionPercent,
            color: Colors.orange,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            context,
            icon: '⏱️',
            label: '총 사용 시간',
            value: _summary!.formattedTotalUsageTime,
            color: Colors.purple,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingMetricCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(strokeWidth: 2),
          SizedBox(height: 8),
          Text(
            '로딩 중...',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.red.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: 24),
          SizedBox(height: 8),
          Text(
            '데이터를 불러올 수 없습니다',
            style: TextStyle(
              fontSize: 14,
              color: Colors.red[700],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          ElevatedButton(
            onPressed: _loadScreenTimeData,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('다시 시도'),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionRequest(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.security, color: Colors.orange, size: 24),
          SizedBox(height: 8),
          Text(
            '사용 통계 권한이 필요합니다',
            style: TextStyle(
              fontSize: 14,
              color: Colors.orange[700],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          ElevatedButton(
            onPressed: _handlePermissionRequest,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: Text('권한 설정'),
          ),
        ],
      ),
    );
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
  const AppBatteryUsageCard({super.key});

  @override
  State<AppBatteryUsageCard> createState() => _AppBatteryUsageCardState();
}

class _AppBatteryUsageCardState extends State<AppBatteryUsageCard> {
  final AppUsageManager _appUsageManager = AppUsageManager();
  bool _showAll = false;
  ScreenTimeSummary? _summary;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadAppUsageData();
  }

  Future<void> _loadAppUsageData() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      final summary = await _appUsageManager.getScreenTimeSummary();
      
      setState(() {
        _summary = summary;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingState(context);
    }

    if (_hasError || _summary == null) {
      return _buildErrorState(context);
    }

    if (!_summary!.hasPermission) {
      return _buildPermissionState(context);
    }

    final apps = _summary!.topApps;
    final displayedApps = _showAll ? apps : apps.take(4).toList();
    final otherAppsPercent = _showAll ? 0 : _calculateOtherAppsPercent(apps);
    
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
              ],
            ),
          ),
          
          // 앱 리스트
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                ...displayedApps.map((app) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildRealAppItem(context, app),
                )),
                
                // "기타" 또는 "전체 보기" 버튼
                if (!_showAll && otherAppsPercent > 0)
                  _buildOtherAppsItem(context, otherAppsPercent.toInt())
                else if (!_showAll)
                  SizedBox(height: 4),
              ],
            ),
          ),
          
          SizedBox(height: 16),
        ],
      ),
    );
  }

  double _calculateOtherAppsPercent(List<RealAppUsageData> apps) {
    if (apps.length <= 4) return 0.0;
    
    final remainingTotal = apps.skip(4).fold<double>(0.0, (sum, app) => sum + app.batteryPercent);
    
    return remainingTotal;
  }

  Widget _buildLoadingState(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
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
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              '앱 사용 데이터를 불러오는 중...',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
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
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Icon(Icons.error_outline, color: Colors.red, size: 48),
            SizedBox(height: 16),
            Text(
              '앱 사용 데이터를 불러올 수 없습니다',
              style: TextStyle(
                fontSize: 14,
                color: Colors.red[700],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadAppUsageData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionState(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
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
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Icon(Icons.security, color: Colors.orange, size: 48),
            SizedBox(height: 16),
            Text(
              '앱 사용 통계 권한이 필요합니다',
              style: TextStyle(
                fontSize: 14,
                color: Colors.orange[700],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                await _appUsageManager.openPermissionSettings();
                await _loadAppUsageData();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: Text('권한 설정'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRealAppItem(BuildContext context, RealAppUsageData app) {
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
              // 심각도 아이콘
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: app.color,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 8),
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
              value: app.batteryPercent / 100,
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
  
  Widget _buildOtherAppsItem(BuildContext context, int percent) {
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
                '기타 (12개 앱)',
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
              '$percent%',
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
class UsageTrendCard extends StatelessWidget {
  const UsageTrendCard({super.key});

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
          
          // 트렌드 아이템들
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _buildTrendItem(
                  context,
                  label: '스크린 타임',
                  today: '4시간 32분',
                  yesterday: '4시간 17분',
                  change: '⬆️ 15분 증가',
                  isIncrease: true,
                ),
                SizedBox(height: 12),
                _buildTrendItem(
                  context,
                  label: '배터리 소모량',
                  today: '65%',
                  yesterday: '58%',
                  change: '⬆️ 7%p 증가',
                  isIncrease: true,
                ),
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
          _buildAppComparisonRow(
            context,
            label: '오늘',
            app: 'YouTube',
            percent: '35%',
            color: Colors.red[400]!,
          ),
          SizedBox(height: 6),
          _buildAppComparisonRow(
            context,
            label: '어제',
            app: 'Instagram',
            percent: '28%',
            color: Colors.pink[400]!,
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
