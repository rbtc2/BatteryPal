import 'package:flutter/material.dart';
import '../widgets/analysis_tab_widgets.dart';

/// 사용 패턴 탭 - 시간대별 사용량 분석, 요일별 패턴, 앱별 배터리 소모량
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
          // 시간대별 사용량 분석 카드
          AnalysisCard(
            title: '시간대별 사용량 분석',
            child: _buildHourlyUsage(),
          ),
          const SizedBox(height: 24),

          // 요일별 패턴 분석 카드
          AnalysisCard(
            title: '요일별 패턴 분석',
            showProUpgrade: !isProUser,
            onProUpgrade: onProUpgrade,
            child: _buildWeeklyPatterns(),
          ),
          const SizedBox(height: 24),

          // 앱별 배터리 소모량 카드
          AnalysisCard(
            title: '앱별 배터리 소모량',
            showProUpgrade: !isProUser,
            onProUpgrade: onProUpgrade,
            child: _buildAppUsage(),
          ),
          const SizedBox(height: 24),

          // 사용 강도 분석 카드
          AnalysisCard(
            title: '사용 강도 분석',
            showProUpgrade: !isProUser,
            onProUpgrade: onProUpgrade,
            child: _buildUsageIntensity(),
          ),
        ],
      ),
    );
  }

  Widget _buildHourlyUsage() {
    return Column(
      children: [
        // 시간대별 사용량 차트
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.withValues(alpha: 0.3),
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.bar_chart,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  '24시간 사용량 차트',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '시간대별 배터리 사용량을 확인할 수 있습니다',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 주요 시간대 통계
        Row(
          children: [
            Expanded(
              child: MetricCard(
                title: '최고 사용 시간',
                value: '14:00-15:00',
                icon: Icons.trending_up,
                color: Colors.red,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: MetricCard(
                title: '최저 사용 시간',
                value: '03:00-04:00',
                icon: Icons.trending_down,
                color: Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: MetricCard(
                title: '평균 사용량',
                value: '4.2%/시간',
                icon: Icons.analytics,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: MetricCard(
                title: '피크 사용량',
                value: '8.5%/시간',
                icon: Icons.show_chart,
                color: Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWeeklyPatterns() {
    return Column(
      children: [
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.withValues(alpha: 0.3),
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.calendar_view_week,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  '요일별 패턴 분석',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Pro로 업그레이드하면 상세한 요일별 패턴을 확인할 수 있습니다',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 요일별 통계
        Row(
          children: [
            Expanded(
              child: MetricCard(
                title: '월요일',
                value: '85%',
                icon: Icons.calendar_today,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: MetricCard(
                title: '화요일',
                value: '78%',
                icon: Icons.calendar_today,
                color: Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: MetricCard(
                title: '수요일',
                value: '92%',
                icon: Icons.calendar_today,
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: MetricCard(
                title: '목요일',
                value: '88%',
                icon: Icons.calendar_today,
                color: Colors.purple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: MetricCard(
                title: '금요일',
                value: '95%',
                icon: Icons.calendar_today,
                color: Colors.red,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: MetricCard(
                title: '주말 평균',
                value: '72%',
                icon: Icons.weekend,
                color: Colors.teal,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAppUsage() {
    return Column(
      children: [
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.withValues(alpha: 0.3),
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.pie_chart,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  '앱별 배터리 소모량 차트',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Pro로 업그레이드하면 상세한 앱별 분석을 확인할 수 있습니다',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 상위 앱들 (무료 버전에서는 상위 5개만)
        ..._getTopApps().take(isProUser ? _getTopApps().length : 5).map((app) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildAppUsageItem(app),
          );
        }),
      ],
    );
  }

  Widget _buildAppUsageItem(Map<String, dynamic> app) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            app['icon'],
            color: app['color'],
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  app['name'],
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  app['category'],
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${app['usage']}%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: app['color'],
                ),
              ),
              Text(
                app['time'],
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUsageIntensity() {
    return Column(
      children: [
        Container(
          height: 150,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.withValues(alpha: 0.3),
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.speed,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  '사용 강도 분석',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Pro로 업그레이드하면 상세한 사용 강도 분석을 확인할 수 있습니다',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 사용 강도 통계
        Row(
          children: [
            Expanded(
              child: MetricCard(
                title: '고강도 사용',
                value: '2시간',
                icon: Icons.flash_on,
                color: Colors.red,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: MetricCard(
                title: '중강도 사용',
                value: '6시간',
                icon: Icons.speed,
                color: Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: MetricCard(
                title: '저강도 사용',
                value: '4시간',
                icon: Icons.battery_6_bar,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: MetricCard(
                title: '대기 시간',
                value: '12시간',
                icon: Icons.pause,
                color: Colors.blue,
              ),
            ),
          ],
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _getTopApps() {
    return [
      {
        'name': 'YouTube',
        'category': '엔터테인먼트',
        'usage': 25,
        'time': '2시간 30분',
        'icon': Icons.play_circle,
        'color': Colors.red,
      },
      {
        'name': 'Instagram',
        'category': '소셜',
        'usage': 18,
        'time': '1시간 45분',
        'icon': Icons.camera_alt,
        'color': Colors.pink,
      },
      {
        'name': 'Chrome',
        'category': '브라우저',
        'usage': 15,
        'time': '1시간 20분',
        'icon': Icons.web,
        'color': Colors.blue,
      },
      {
        'name': 'WhatsApp',
        'category': '메신저',
        'usage': 12,
        'time': '1시간 5분',
        'icon': Icons.message,
        'color': Colors.green,
      },
      {
        'name': 'Spotify',
        'category': '음악',
        'usage': 8,
        'time': '45분',
        'icon': Icons.music_note,
        'color': Colors.green,
      },
      {
        'name': 'TikTok',
        'category': '소셜',
        'usage': 6,
        'time': '30분',
        'icon': Icons.video_library,
        'color': Colors.black,
      },
      {
        'name': 'Netflix',
        'category': '엔터테인먼트',
        'usage': 5,
        'time': '25분',
        'icon': Icons.movie,
        'color': Colors.red,
      },
    ];
  }
}
