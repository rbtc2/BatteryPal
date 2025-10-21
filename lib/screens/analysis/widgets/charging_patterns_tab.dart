import 'package:flutter/material.dart';
import '../widgets/analysis_tab_widgets.dart';

/// 충전 패턴 탭 - 일일 충전 타임라인, 충전 방식별 통계, 충전 속도 분석
class ChargingPatternsTab extends StatelessWidget {
  final bool isProUser;
  final VoidCallback? onProUpgrade;

  const ChargingPatternsTab({
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
          // 일일 충전 타임라인 카드
          AnalysisCard(
            title: '일일 충전 타임라인',
            child: _buildChargingTimeline(),
          ),
          const SizedBox(height: 24),

          // 충전 방식별 통계 카드
          AnalysisCard(
            title: '충전 방식별 통계',
            showProUpgrade: !isProUser,
            onProUpgrade: onProUpgrade,
            child: _buildChargingMethodStats(),
          ),
          const SizedBox(height: 24),

          // 충전 속도 분석 카드
          AnalysisCard(
            title: '충전 속도 분석',
            child: _buildChargingSpeedAnalysis(),
          ),
          const SizedBox(height: 24),

          // 시간대별 충전 패턴 카드
          AnalysisCard(
            title: '시간대별 충전 패턴',
            showProUpgrade: !isProUser,
            onProUpgrade: onProUpgrade,
            child: _buildTimeBasedPatterns(),
          ),
          const SizedBox(height: 24),

          // 충전 효율성 인사이트 카드
          AnalysisCard(
            title: '충전 효율성 인사이트',
            showProUpgrade: !isProUser,
            onProUpgrade: onProUpgrade,
            child: _buildEfficiencyInsights(),
          ),
        ],
      ),
    );
  }

  Widget _buildChargingTimeline() {
    return Column(
      children: [
        // 오늘의 충전 세션들
        _buildChargingSession(
          time: '08:30 - 09:15',
          duration: '45분',
          method: 'USB 충전',
          speed: '저속 충전',
          efficiency: '85%',
          color: Colors.blue,
        ),
        const SizedBox(height: 12),
        _buildChargingSession(
          time: '13:20 - 13:45',
          duration: '25분',
          method: 'AC 충전',
          speed: '고속 충전',
          efficiency: '92%',
          color: Colors.green,
        ),
        const SizedBox(height: 12),
        _buildChargingSession(
          time: '19:30 - 20:30',
          duration: '60분',
          method: '무선 충전',
          speed: '정상 충전',
          efficiency: '78%',
          color: Colors.orange,
        ),
        const SizedBox(height: 16),
        
        // 요약 통계
        Row(
          children: [
            Expanded(
              child: MetricCard(
                title: '총 충전 시간',
                value: '2시간 10분',
                icon: Icons.access_time,
                color: Colors.purple,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: MetricCard(
                title: '평균 효율',
                value: '85%',
                icon: Icons.trending_up,
                color: Colors.green,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChargingSession({
    required String time,
    required String duration,
    required String method,
    required String speed,
    required String efficiency,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                time,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                duration,
                style: TextStyle(
                  fontSize: 14,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildSessionDetail('방식', method),
              ),
              Expanded(
                child: _buildSessionDetail('속도', speed),
              ),
              Expanded(
                child: _buildSessionDetail('효율', efficiency),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSessionDetail(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildChargingMethodStats() {
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
                  '충전 방식별 통계 차트',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Pro로 업그레이드하면 상세한 통계를 확인할 수 있습니다',
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
        Row(
          children: [
            Expanded(
              child: MetricCard(
                title: 'USB 충전',
                value: '45%',
                icon: Icons.usb,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: MetricCard(
                title: 'AC 충전',
                value: '35%',
                icon: Icons.power,
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
                title: '무선 충전',
                value: '20%',
                icon: Icons.wifi,
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: MetricCard(
                title: '빠른 충전',
                value: '60%',
                icon: Icons.flash_on,
                color: Colors.red,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChargingSpeedAnalysis() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: MetricCard(
                title: '초고속 충전',
                value: '2회',
                icon: Icons.flash_on,
                color: Colors.red,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: MetricCard(
                title: '고속 충전',
                value: '5회',
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
                title: '정상 충전',
                value: '8회',
                icon: Icons.battery_charging_full,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: MetricCard(
                title: '저속 충전',
                value: '3회',
                icon: Icons.battery_6_bar,
                color: Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // 충전 속도별 평균 시간
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.blue.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '충전 속도별 평균 시간',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
              const SizedBox(height: 12),
              _buildSpeedTimeItem('초고속 충전', '25분', Colors.red),
              _buildSpeedTimeItem('고속 충전', '45분', Colors.orange),
              _buildSpeedTimeItem('정상 충전', '90분', Colors.green),
              _buildSpeedTimeItem('저속 충전', '180분', Colors.blue),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSpeedTimeItem(String speed, String time, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            speed,
            style: const TextStyle(fontSize: 14),
          ),
          Text(
            time,
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

  Widget _buildTimeBasedPatterns() {
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
                  Icons.schedule,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  '시간대별 충전 패턴 히트맵',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Pro로 업그레이드하면 상세한 패턴을 확인할 수 있습니다',
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
        
        // 시간대별 통계
        Row(
          children: [
            Expanded(
              child: MetricCard(
                title: '오전 충전',
                value: '3회',
                icon: Icons.wb_sunny,
                color: Colors.yellow,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: MetricCard(
                title: '오후 충전',
                value: '2회',
                icon: Icons.wb_sunny_outlined,
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
                title: '저녁 충전',
                value: '4회',
                icon: Icons.nights_stay,
                color: Colors.purple,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: MetricCard(
                title: '야간 충전',
                value: '1회',
                icon: Icons.bedtime,
                color: Colors.indigo,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEfficiencyInsights() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInsightItem(
          icon: Icons.trending_up,
          title: 'AC 충전의 효율성이 무선 충전보다 15% 높습니다',
          color: Colors.green,
        ),
        const SizedBox(height: 12),
        _buildInsightItem(
          icon: Icons.schedule,
          title: '오후 2-4시 충전이 가장 효율적입니다',
          color: Colors.blue,
        ),
        const SizedBox(height: 12),
        _buildInsightItem(
          icon: Icons.warning,
          title: '야간 충전은 배터리 수명에 영향을 줄 수 있습니다',
          color: Colors.orange,
        ),
        const SizedBox(height: 12),
        _buildInsightItem(
          icon: Icons.lightbulb,
          title: '80% 이상 충전 시 효율성이 크게 감소합니다',
          color: Colors.red,
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
                    'Pro로 업그레이드하면 더 자세한 효율성 분석을 확인할 수 있습니다',
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
