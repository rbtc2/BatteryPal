import 'package:flutter/material.dart';
import '../widgets/analysis_tab_widgets.dart';

/// 배터리 건강도 탭 - 배터리 용량, 건강도, 온도 분석
class BatteryHealthTab extends StatelessWidget {
  final bool isProUser;
  final VoidCallback? onProUpgrade;

  const BatteryHealthTab({
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
          // 현재 건강도 카드
          AnalysisCard(
            title: '현재 배터리 건강도',
            child: _buildCurrentHealth(),
          ),
          const SizedBox(height: 24),

          // 건강도 변화 추이 카드
          AnalysisCard(
            title: '건강도 변화 추이',
            showProUpgrade: !isProUser,
            onProUpgrade: onProUpgrade,
            child: _buildHealthTrend(),
          ),
          const SizedBox(height: 24),

          // 온도 패턴 분석 카드
          AnalysisCard(
            title: '온도 패턴 분석',
            showProUpgrade: !isProUser,
            onProUpgrade: onProUpgrade,
            child: _buildTemperatureAnalysis(),
          ),
          const SizedBox(height: 24),

          // 수명 예측 카드
          AnalysisCard(
            title: '배터리 수명 예측',
            showProUpgrade: !isProUser,
            onProUpgrade: onProUpgrade,
            child: _buildLifespanPrediction(),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentHealth() {
    return Column(
      children: [
        // 건강도 점수
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
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
            children: [
              Text(
                '92',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '건강도 점수',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.green[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '매우 좋음',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.green[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // 상세 지표들
        Row(
          children: [
            Expanded(
              child: MetricCard(
                title: '설계 용량',
                value: '4,000mAh',
                icon: Icons.battery_full,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: MetricCard(
                title: '현재 용량',
                value: '3,680mAh',
                icon: Icons.battery_6_bar,
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
                title: '충전 사이클',
                value: '245회',
                icon: Icons.repeat,
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: MetricCard(
                title: '평균 온도',
                value: '32°C',
                icon: Icons.thermostat,
                color: Colors.red,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHealthTrend() {
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
                  Icons.trending_up,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  '건강도 변화 차트',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Pro로 업그레이드하면 상세한 추이를 확인할 수 있습니다',
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
                title: '1주 전',
                value: '94%',
                icon: Icons.calendar_today,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: MetricCard(
                title: '1개월 전',
                value: '96%',
                icon: Icons.calendar_month,
                color: Colors.green,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTemperatureAnalysis() {
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
                  Icons.thermostat,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  '온도 패턴 분석',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Pro로 업그레이드하면 상세한 온도 분석을 확인할 수 있습니다',
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
                title: '최고 온도',
                value: '38°C',
                icon: Icons.trending_up,
                color: Colors.red,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: MetricCard(
                title: '최저 온도',
                value: '25°C',
                icon: Icons.trending_down,
                color: Colors.blue,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLifespanPrediction() {
    return Column(
      children: [
        Container(
          width: double.infinity,
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
            children: [
              Icon(
                Icons.schedule,
                size: 48,
                color: Colors.orange[600],
              ),
              const SizedBox(height: 16),
              Text(
                '예상 수명',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.orange[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '2년 3개월',
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.orange[800],
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '현재 사용 패턴을 유지하면 이 정도 수명을 예상할 수 있습니다',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.orange[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: MetricCard(
                title: '80% 수명',
                value: '1년 8개월',
                icon: Icons.warning,
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: MetricCard(
                title: '교체 권장',
                value: '2년 6개월',
                icon: Icons.info,
                color: Colors.red,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
