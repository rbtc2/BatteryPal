import 'package:flutter/material.dart';
import '../widgets/analysis_tab_widgets.dart';

/// 개요 탭 - 일일 배터리 사용량 요약 및 주요 통계
class OverviewTab extends StatelessWidget {
  final bool isProUser;
  final VoidCallback? onProUpgrade;
  final Function(int)? onTabChange;

  const OverviewTab({
    super.key,
    required this.isProUser,
    this.onProUpgrade,
    this.onTabChange,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 오늘의 요약 카드
          AnalysisCard(
            title: '오늘의 요약',
            showProUpgrade: !isProUser,
            onProUpgrade: onProUpgrade,
            child: _buildTodaySummary(),
          ),
          const SizedBox(height: 24),

          // 주요 지표 한눈에
          AnalysisCard(
            title: '주요 지표 한눈에',
            child: _buildKeyMetrics(),
          ),
          const SizedBox(height: 24),

          // 오늘의 인사이트
          AnalysisCard(
            title: '오늘의 인사이트',
            showProUpgrade: !isProUser,
            onProUpgrade: onProUpgrade,
            child: _buildTodayInsights(),
          ),
        ],
      ),
    );
  }

  Widget _buildTodaySummary() {
    return Column(
      children: [
        // 배터리 점수 메인 카드
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.green.withValues(alpha: 0.1),
                Colors.green.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.green.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    Icons.battery_full,
                    color: Colors.green,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '배터리 점수: 85/100',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '🟢',
                    style: TextStyle(fontSize: 20),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // 세부 지표들
              _buildScoreDetail('건강도', '92%', '우수', Colors.green),
              const SizedBox(height: 8),
              _buildScoreDetail('충전 효율', '88%', '양호', Colors.blue),
              const SizedBox(height: 8),
              _buildScoreDetail('사용 효율', '79%', '개선 필요', Colors.orange),
              const SizedBox(height: 8),
              _buildScoreDetail('절전 실천', '82%', '양호', Colors.purple),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScoreDetail(String label, String value, String status, Color color) {
    return Builder(
      builder: (context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '├─ $label: $value ($status)',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyMetrics() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMiniChartCard(
                icon: '🔋',
                title: '배터리 잔량 트렌드',
                subtitle: '(24시간)',
                onTap: () => onTabChange?.call(1), // 배터리 건강도 탭
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMiniChartCard(
                icon: '⚡',
                title: '오늘 충전 세션',
                subtitle: '(타임라인)',
                onTap: () => onTabChange?.call(2), // 충전 패턴 탭
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMiniChartCard(
                icon: '📱',
                title: '스크린 온 타임',
                subtitle: '(6시간 15분)',
                onTap: () => onTabChange?.call(3), // 사용 패턴 탭
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMiniChartCard(
                icon: '🌡️',
                title: '평균 온도',
                subtitle: '(28°C)',
                onTap: () => onTabChange?.call(1), // 배터리 건강도 탭
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMiniChartCard({
    required String icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Builder(
      builder: (context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                icon,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              // 간단한 차트 시각화 (막대 그래프)
              _buildSimpleChart(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSimpleChart(BuildContext context) {
    return SizedBox(
      height: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(5, (index) {
          double height = (index % 3 == 0) ? 0.8 : (index % 2 == 0) ? 0.6 : 0.4;
          return Container(
            width: 3,
            height: 20 * height,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(1.5),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTodayInsights() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInsightItem(
          icon: '💡',
          title: '오후 2-4시 사이 배터리 소모가 40% 증가했어요',
          color: Colors.orange,
        ),
        const SizedBox(height: 16),
        _buildInsightItem(
          icon: '💡',
          title: '저녁 충전을 80%에서 멈추면 수명이 연장됩니다',
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
    required String icon,
    required String title,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          icon,
          style: const TextStyle(fontSize: 20),
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
