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
        // 스크린 타임 분석
        Builder(
          builder: (context) => Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.blue.withValues(alpha: 0.1),
                  Colors.blue.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.blue.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.screen_share,
                      color: Colors.blue[700],
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '스크린 타임 분석',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // 일별 추이
                Text(
                  '일별 추이:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                _buildDailyTrend(),
                const SizedBox(height: 16),
                
                // 시간대별 사용량
                Text(
                  '시간대별:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                _buildTimeSlotUsage(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDailyTrend() {
    return Builder(
      builder: (context) => Row(
        children: [
          _buildDayItem('월', '5h', Colors.blue),
          const SizedBox(width: 8),
          _buildDayItem('화', '6h', Colors.green),
          const SizedBox(width: 8),
          _buildDayItem('수', '7h', Colors.orange),
          const SizedBox(width: 8),
          _buildDayItem('목', '4h', Colors.purple),
          const SizedBox(width: 8),
          _buildDayItem('금', '8h', Colors.red),
        ],
      ),
    );
  }

  Widget _buildDayItem(String day, String hours, Color color) {
    return Builder(
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            Text(
              day,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              hours,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSlotUsage() {
    return Builder(
      builder: (context) => Column(
        children: [
          _buildTimeSlotItem('아침', '1h', Colors.yellow),
          const SizedBox(height: 8),
          _buildTimeSlotItem('점심', '2h', Colors.orange),
          const SizedBox(height: 8),
          _buildTimeSlotItem('오후', '3h', Colors.red),
          const SizedBox(height: 8),
          _buildTimeSlotItem('저녁', '2h', Colors.purple),
        ],
      ),
    );
  }

  Widget _buildTimeSlotItem(String timeSlot, String hours, Color color) {
    return Builder(
      builder: (context) => Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            timeSlot,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            hours,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
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
        // 앱별 배터리 사용량 도넛 차트
        Builder(
          builder: (context) => Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.purple.withValues(alpha: 0.1),
                  Colors.purple.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.purple.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.donut_large,
                      color: Colors.purple[700],
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '앱별 배터리 사용량 (도넛 차트)',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildAppUsageChart(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppUsageChart() {
    return Builder(
      builder: (context) => Column(
        children: [
          _buildAppUsageItem('YouTube', 35, Colors.red),
          const SizedBox(height: 8),
          _buildAppUsageItem('Instagram', 22, Colors.pink),
          const SizedBox(height: 8),
          _buildAppUsageItem('카카오톡', 15, Colors.yellow),
          const SizedBox(height: 8),
          _buildAppUsageItem('Chrome', 10, Colors.blue),
          const SizedBox(height: 8),
          _buildAppUsageItem('게임', 8, Colors.green),
          const SizedBox(height: 8),
          _buildAppUsageItem('기타', 10, Colors.grey),
        ],
      ),
    );
  }

  Widget _buildAppUsageItem(String appName, int percentage, Color color) {
    return Builder(
      builder: (context) => Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              appName,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$percentage%',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 8,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: percentage / 100,
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsageIntensity() {
    return Column(
      children: [
        // 사용 강도 맵
        Builder(
          builder: (context) => Container(
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
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.speed,
                      color: Colors.green[700],
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '사용 강도 맵',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildIntensityMap(),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // 이상 패턴 감지
        _buildAnomalyDetection(),
      ],
    );
  }

  Widget _buildIntensityMap() {
    return Builder(
      builder: (context) => Column(
        children: [
          _buildIntensityItem('🟢', '가벼운 사용 (웹서핑)', '-5%/시간', Colors.green),
          const SizedBox(height: 12),
          _buildIntensityItem('🟡', '보통 사용 (동영상)', '-12%/시간', Colors.orange),
          const SizedBox(height: 12),
          _buildIntensityItem('🔴', '무거운 사용 (게임)', '-25%/시간', Colors.red),
        ],
      ),
    );
  }

  Widget _buildIntensityItem(String emoji, String description, String consumption, Color color) {
    return Builder(
      builder: (context) => Row(
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              description,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: color.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              consumption,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnomalyDetection() {
    return Builder(
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.orange.withValues(alpha: 0.1),
              Colors.orange.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.orange.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning,
                  color: Colors.orange[700],
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  '이상 패턴 감지',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildAnomalyItem('⚠️', 'Instagram이 백그라운드에서 15% 소모'),
            const SizedBox(height: 12),
            _buildAnomalyItem('⚠️', '화요일 오후 비정상적 발열 감지'),
          ],
        ),
      ),
    );
  }

  Widget _buildAnomalyItem(String icon, String message) {
    return Builder(
      builder: (context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            icon,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
