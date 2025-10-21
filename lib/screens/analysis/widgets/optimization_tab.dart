import 'package:flutter/material.dart';
import '../widgets/analysis_tab_widgets.dart';

/// 최적화 탭 - 개인화된 절약 팁, 충전 최적화 제안, 사용 패턴 개선
class OptimizationTab extends StatelessWidget {
  final bool isProUser;
  final VoidCallback? onProUpgrade;

  const OptimizationTab({
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
          // 개인화된 절약 팁 카드
          AnalysisCard(
            title: '개인화된 절약 팁',
            child: _buildPersonalizedTips(),
          ),
          const SizedBox(height: 24),

          // 충전 최적화 제안 카드
          AnalysisCard(
            title: '충전 최적화 제안',
            child: _buildChargingOptimization(),
          ),
          const SizedBox(height: 24),

          // 사용 패턴 개선 카드
          AnalysisCard(
            title: '사용 패턴 개선',
            showProUpgrade: !isProUser,
            onProUpgrade: onProUpgrade,
            child: _buildUsagePatternImprovement(),
          ),
          const SizedBox(height: 24),

          // 목표 설정 및 추적 카드
          AnalysisCard(
            title: '목표 설정 및 추적',
            showProUpgrade: !isProUser,
            onProUpgrade: onProUpgrade,
            child: _buildGoalSetting(),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalizedTips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTipItem(
          icon: Icons.brightness_high,
          title: '화면 밝기 조절',
          description: '현재 화면 밝기가 평균보다 20% 높습니다. 자동 밝기 조절을 사용하면 배터리를 절약할 수 있습니다.',
          impact: '15% 절약 가능',
          color: Colors.orange,
          isImplemented: false,
        ),
        const SizedBox(height: 16),
        _buildTipItem(
          icon: Icons.location_on,
          title: '위치 서비스 최적화',
          description: '사용하지 않는 앱의 위치 서비스를 비활성화하면 배터리 수명을 연장할 수 있습니다.',
          impact: '8% 절약 가능',
          color: Colors.blue,
          isImplemented: true,
        ),
        const SizedBox(height: 16),
        _buildTipItem(
          icon: Icons.wifi,
          title: 'Wi-Fi 자동 연결',
          description: 'Wi-Fi 자동 연결을 활성화하면 모바일 데이터 사용량을 줄이고 배터리를 절약할 수 있습니다.',
          impact: '12% 절약 가능',
          color: Colors.green,
          isImplemented: false,
        ),
        const SizedBox(height: 16),
        _buildTipItem(
          icon: Icons.notifications_off,
          title: '불필요한 알림 비활성화',
          description: '중요하지 않은 앱의 알림을 비활성화하면 배터리와 성능을 개선할 수 있습니다.',
          impact: '5% 절약 가능',
          color: Colors.purple,
          isImplemented: false,
        ),
      ],
    );
  }

  Widget _buildTipItem({
    required IconData icon,
    required String title,
    required String description,
    required String impact,
    required Color color,
    required bool isImplemented,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isImplemented 
            ? Colors.green.withValues(alpha: 0.1)
            : color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isImplemented 
              ? Colors.green.withValues(alpha: 0.3)
              : color.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: isImplemented ? Colors.green : color,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isImplemented ? Colors.green : color,
                  ),
                ),
              ),
              if (isImplemented)
                Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 20,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                impact,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isImplemented ? Colors.green : color,
                ),
              ),
              if (!isImplemented)
                TextButton(
                  onPressed: () {
                    // TODO: 구현 로직 추가
                  },
                  child: const Text('적용하기'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChargingOptimization() {
    return Column(
      children: [
        // 충전 패턴 분석
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
              Row(
                children: [
                  Icon(
                    Icons.charging_station,
                    color: Colors.blue[600],
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '충전 패턴 분석',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '현재 충전 패턴을 분석한 결과, 다음과 같은 최적화를 제안합니다:',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              _buildOptimizationSuggestion(
                '80% 이상 충전을 피하세요',
                '배터리 수명을 위해 80%까지만 충전하는 것을 권장합니다',
                Colors.orange,
              ),
              _buildOptimizationSuggestion(
                '야간 충전 시간을 줄이세요',
                '밤새 충전하는 것보다 낮에 짧게 여러 번 충전하는 것이 좋습니다',
                Colors.red,
              ),
              _buildOptimizationSuggestion(
                'AC 충전을 더 자주 사용하세요',
                'USB 충전보다 AC 충전이 효율적입니다',
                Colors.green,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 충전 최적화 통계
        Row(
          children: [
            Expanded(
              child: MetricCard(
                title: '현재 효율',
                value: '78%',
                icon: Icons.analytics,
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: MetricCard(
                title: '최적화 후',
                value: '92%',
                icon: Icons.trending_up,
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
                title: '절약 시간',
                value: '30분/일',
                icon: Icons.access_time,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: MetricCard(
                title: '수명 연장',
                value: '6개월',
                icon: Icons.schedule,
                color: Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOptimizationSuggestion(String title, String description, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lightbulb,
            color: color,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsagePatternImprovement() {
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
                  '사용 패턴 개선 분석',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Pro로 업그레이드하면 상세한 사용 패턴 개선 제안을 확인할 수 있습니다',
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

        // 기본 개선 제안들
        _buildImprovementItem(
          '앱 사용 시간 제한',
          'YouTube 사용 시간을 하루 2시간으로 제한하면 15% 절약 가능',
          Colors.red,
        ),
        const SizedBox(height: 12),
        _buildImprovementItem(
          '배경 앱 새로고침 최적화',
          '불필요한 배경 새로고침을 비활성화하면 8% 절약 가능',
          Colors.orange,
        ),
        const SizedBox(height: 12),
        _buildImprovementItem(
          '다크 모드 활용',
          '다크 모드를 더 자주 사용하면 12% 절약 가능',
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildImprovementItem(String title, String description, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(
              fontSize: 12,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalSetting() {
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
                  Icons.flag,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  '목표 설정 및 추적',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Pro로 업그레이드하면 개인화된 목표를 설정하고 추적할 수 있습니다',
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

        // 기본 목표들
        Row(
          children: [
            Expanded(
              child: MetricCard(
                title: '일일 목표',
                value: '80% 이하',
                icon: Icons.today,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: MetricCard(
                title: '현재 달성률',
                value: '75%',
                icon: Icons.check_circle,
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
                title: '주간 목표',
                value: '5회 이하',
                icon: Icons.calendar_view_week,
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: MetricCard(
                title: '현재 달성률',
                value: '80%',
                icon: Icons.trending_up,
                color: Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
