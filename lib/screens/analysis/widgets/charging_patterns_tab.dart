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
        // 24시간 타임라인 바 차트
        Builder(
          builder: (context) => Container(
            height: 80,
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              children: [
                Text(
                  '24시간 충전 타임라인',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: _buildTimelineBar(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // 충전 세션 상세 정보
        _buildChargingSessionDetail(
          icon: '🌙',
          title: '새벽 충전 (02:15 - 07:00)',
          batteryChange: '15% → 100%',
          duration: '4시간 45분',
          speed: '저속(500mA)',
          color: const Color(0xFF94A3B8), // slate-400
        ),
        const SizedBox(height: 12),
        _buildChargingSessionDetail(
          icon: '⚡',
          title: '아침 충전 (09:00 - 10:15)',
          batteryChange: '25% → 85%',
          duration: '1시간 15분',
          speed: '고속(2100mA)',
          color: const Color(0xFF6366F1), // indigo-600
        ),
        const SizedBox(height: 12),
        _buildChargingSessionDetail(
          icon: '🔌',
          title: '저녁 충전 (18:30 - 19:00)',
          batteryChange: '45% → 75%',
          duration: '30분',
          speed: '일반(1000mA)',
          color: const Color(0xFF3B82F6), // blue-500
        ),
      ],
    );
  }

  Widget _buildTimelineBar() {
    return Builder(
      builder: (context) => Container(
        height: 20,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Stack(
          children: [
            // 배경 그리드 (시간 표시)
            _buildTimeGrid(),
            // 충전 세션 블록들
            _buildChargingBlocks(),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeGrid() {
    return Builder(
      builder: (context) => Row(
        children: List.generate(25, (index) {
          return Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                    width: 0.5,
                  ),
                ),
              ),
              child: Center(
                child: Text(
                  index.toString().padLeft(2, '0'),
                  style: TextStyle(
                    fontSize: 8,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildChargingBlocks() {
    return Builder(
      builder: (context) => Stack(
        children: [
          // 새벽 충전 (02:15 - 07:00)
          Positioned(
            left: 2.25 * 4.0, // 2시간 15분 = 2.25시간
            child: Container(
              width: (7.0 - 2.25) * 4.0, // 4시간 45분
              height: 20,
              decoration: BoxDecoration(
                color: const Color(0xFF94A3B8), // slate-400
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  '02-07시',
                  style: const TextStyle(
                    fontSize: 8,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          // 아침 충전 (09:00 - 10:15)
          Positioned(
            left: 9.0 * 4.0, // 9시간
            child: Container(
              width: (10.25 - 9.0) * 4.0, // 1시간 15분
              height: 20,
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1), // indigo-600
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  '09-10시',
                  style: const TextStyle(
                    fontSize: 8,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          // 저녁 충전 (18:30 - 19:00)
          Positioned(
            left: 18.5 * 4.0, // 18시간 30분
            child: Container(
              width: (19.0 - 18.5) * 4.0, // 30분
              height: 20,
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6), // blue-500
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  '18-19시',
                  style: const TextStyle(
                    fontSize: 8,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChargingSessionDetail({
    required String icon,
    required String title,
    required String batteryChange,
    required String duration,
    required String speed,
    required Color color,
  }) {
    return Builder(
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border(
            left: BorderSide(
              color: color,
              width: 4,
            ),
          ),
        ),
        child: Row(
          children: [
            Text(
              icon,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '배터리 변화: $batteryChange',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '충전 시간: $duration',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '충전 속도: $speed',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
        // 충전 습관 히트맵
        Builder(
          builder: (context) => Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '충전 습관 히트맵 (주간)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                _buildHeatmapGrid(),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // 충전 통계
        _buildChargingStats(),
      ],
    );
  }

  Widget _buildHeatmapGrid() {
    return Builder(
      builder: (context) => Column(
        children: [
          // 요일 헤더
          Row(
            children: [
              const SizedBox(width: 60), // 시간 라벨 공간
              ...['월', '화', '수', '목', '금', '토', '일'].map((day) => 
                Expanded(
                  child: Center(
                    child: Text(
                      day,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 히트맵 그리드
          ..._buildHeatmapRows(context),
        ],
      ),
    );
  }

  List<Widget> _buildHeatmapRows(BuildContext context) {
    final timeLabels = ['06시', '09시', '12시', '18시', '23시'];
    final timeDescriptions = ['← 출근 전', '← 출근 중', '← 점심', '← 퇴근 후', '← 취침 전'];
    
    // 샘플 데이터: 각 시간대별로 충전한 요일들
    final heatmapData = [
      [false, false, false, false, false, false, false], // 06시
      [true, true, false, true, true, false, false],     // 09시
      [false, false, true, false, false, false, false],  // 12시
      [true, true, true, true, true, true, true],        // 18시
      [false, false, false, false, false, false, true],  // 23시
    ];

    return List.generate(5, (rowIndex) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            // 시간 라벨
            SizedBox(
              width: 60,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    timeLabels[rowIndex],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    timeDescriptions[rowIndex],
                    style: TextStyle(
                      fontSize: 10,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // 히트맵 셀들
            ...List.generate(7, (colIndex) {
              final isCharged = heatmapData[rowIndex][colIndex];
              return Expanded(
                child: Container(
                  height: 24,
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  decoration: BoxDecoration(
                    color: isCharged 
                        ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.8)
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                      width: 0.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      isCharged ? '■' : '□',
                      style: TextStyle(
                        fontSize: 12,
                        color: isCharged 
                            ? Colors.white
                            : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      );
    });
  }

  Widget _buildChargingStats() {
    return Builder(
      builder: (context) => Column(
        children: [
          // 평균 시작/종료
          Container(
            width: double.infinity,
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
                  '평균 시작/종료',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '평균 시작: 28% | 평균 종료: 87%',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          
          // 충전 빈도와 타입 비율
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.green.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '충전 빈도',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '일 평균: 2.3회',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      Text(
                        '주 평균: 16회',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '충전 타입 비율',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '고속:일반:저속',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      Text(
                        '= 45:35:20',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
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
