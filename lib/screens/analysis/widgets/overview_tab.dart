import 'package:flutter/material.dart';
import '../widgets/analysis_tab_widgets.dart';

/// 개요 탭 - 일일 배터리 사용량 요약 및 주요 통계
class OverviewTab extends StatelessWidget {
  final bool isProUser;
  final VoidCallback? onProUpgrade;

  const OverviewTab({
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
          // 일일 배터리 요약 카드
          AnalysisCard(
            title: '일일 배터리 요약',
            showProUpgrade: !isProUser,
            onProUpgrade: onProUpgrade,
            child: _buildDailySummary(),
          ),
          const SizedBox(height: 24),

          // 주요 통계 카드
          AnalysisCard(
            title: '주요 통계',
            child: _buildKeyMetrics(),
          ),
          const SizedBox(height: 24),

          // 빠른 인사이트 카드
          AnalysisCard(
            title: '빠른 인사이트',
            showProUpgrade: !isProUser,
            onProUpgrade: onProUpgrade,
            child: _buildQuickInsights(),
          ),
        ],
      ),
    );
  }

  Widget _buildDailySummary() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: MetricCard(
                title: '오늘 사용량',
                value: '85%',
                icon: Icons.battery_6_bar,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: MetricCard(
                title: '충전 횟수',
                value: '3회',
                icon: Icons.charging_station,
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
                title: '사용 시간',
                value: '12시간',
                icon: Icons.access_time,
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: MetricCard(
                title: '절약 시간',
                value: '2시간',
                icon: Icons.trending_down,
                color: Colors.red,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKeyMetrics() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: MetricCard(
                title: '평균 사용량',
                value: '78%',
                icon: Icons.analytics,
                color: Colors.purple,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: MetricCard(
                title: '최고 효율',
                value: '92%',
                icon: Icons.star,
                color: Colors.amber,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: MetricCard(
                title: '절약 목표',
                value: '80%',
                icon: Icons.flag,
                color: Colors.teal,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: MetricCard(
                title: '달성률',
                value: '75%',
                icon: Icons.check_circle,
                color: Colors.green,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickInsights() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInsightItem(
          icon: Icons.trending_up,
          title: '배터리 사용량이 평소보다 15% 증가했습니다',
          color: Colors.red,
        ),
        const SizedBox(height: 12),
        _buildInsightItem(
          icon: Icons.schedule,
          title: '오후 2-4시에 가장 많은 배터리를 사용합니다',
          color: Colors.orange,
        ),
        const SizedBox(height: 12),
        _buildInsightItem(
          icon: Icons.battery_charging_full,
          title: '빠른 충전을 2회 사용하여 효율이 향상되었습니다',
          color: Colors.green,
        ),
        if (!isProUser) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.blue.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.blue,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Pro로 업그레이드하면 더 자세한 인사이트를 확인할 수 있습니다',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInsightItem({
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: color,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
