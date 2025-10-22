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
      children: [
        // 현재 절전 레벨
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
                      Icons.battery_saver,
                      color: Colors.green[700],
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '현재 절전 레벨',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildPowerLevelSelector(),
                const SizedBox(height: 16),
                _buildUsageTimeComparison(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPowerLevelSelector() {
    return Builder(
      builder: (context) => Row(
        children: [
          _buildPowerLevelButton('기본', false, Colors.grey),
          const SizedBox(width: 8),
          _buildPowerLevelButton('절전', true, Colors.orange),
          const SizedBox(width: 8),
          _buildPowerLevelButton('초절전', false, Colors.red),
          const SizedBox(width: 8),
          _buildPowerLevelButton('커스텀', false, Colors.purple),
        ],
      ),
    );
  }

  Widget _buildPowerLevelButton(String label, bool isSelected, Color color) {
    return Builder(
      builder: (context) => Expanded(
        child: GestureDetector(
          onTap: () {
            // TODO: 절전 레벨 변경 로직
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isSelected 
                  ? color.withValues(alpha: 0.2)
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected 
                    ? color
                    : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              children: [
                if (isSelected) ...[
                  Icon(
                    Icons.keyboard_arrow_up,
                    color: color,
                    size: 16,
                  ),
                  const SizedBox(height: 4),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? color : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                if (isSelected) ...[
                  const SizedBox(height: 4),
                  Text(
                    '현재 설정',
                    style: TextStyle(
                      fontSize: 10,
                      color: color,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUsageTimeComparison() {
    return Builder(
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.blue.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '예상 사용 시간:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '8시간 → 12시간 (+4시간)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.trending_up,
              color: Colors.green[700],
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChargingOptimization() {
    return Column(
      children: [
        // 맞춤 최적화 제안
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
                      Icons.auto_fix_high,
                      color: Colors.purple[700],
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '맞춤 최적화 제안',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // 즉시 적용 가능
                Text(
                  '즉시 적용 가능:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                _buildOptimizationItem('화면 밝기 자동 조절', '+45분', false),
                _buildOptimizationItem('5G → LTE 전환', '+1시간', false),
                _buildOptimizationItem('백그라운드 앱 제한', '+30분', false),
                
                const SizedBox(height: 16),
                
                // 장기 개선
                Text(
                  '장기 개선:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                _buildOptimizationItem('충전 상한 80% 설정', '', false),
                _buildOptimizationItem('야간 자동 절전 모드', '', false),
                _buildOptimizationItem('위치 서비스 최적화', '', false),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOptimizationItem(String title, String benefit, bool isChecked) {
    return Builder(
      builder: (context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            GestureDetector(
              onTap: () {
                // TODO: 체크박스 토글 로직
              },
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: isChecked 
                      ? Colors.green
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isChecked 
                        ? Colors.green
                        : Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
                  ),
                ),
                child: isChecked
                    ? const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 14,
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            if (benefit.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.green.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  benefit,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsagePatternImprovement() {
    return Column(
      children: [
        // 절전 시뮬레이터
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
                      Icons.tune,
                      color: Colors.blue[700],
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '절전 시뮬레이터',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSimulatorSlider('화면 밝기', 70, Colors.yellow),
                const SizedBox(height: 16),
                _buildSimulatorSlider('CPU 성능', 85, Colors.orange),
                const SizedBox(height: 16),
                _buildSimulatorSlider('네트워크 속도', 60, Colors.green),
                const SizedBox(height: 16),
                _buildExpectedTimeDisplay(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSimulatorSlider(String label, int value, Color color) {
    return Builder(
      builder: (context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Text(
                '$value%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: color,
              inactiveTrackColor: color.withValues(alpha: 0.3),
              thumbColor: color,
              overlayColor: color.withValues(alpha: 0.2),
            ),
            child: Slider(
              value: value.toDouble(),
              min: 0,
              max: 100,
              divisions: 20,
              onChanged: (newValue) {
                // TODO: 슬라이더 값 변경 로직
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpectedTimeDisplay() {
    return Builder(
      builder: (context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.green.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            Text(
              '실시간 예상 사용시간 변화',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '8시간 → 12시간 (+4시간)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '현재 설정으로 예상되는 배터리 사용 시간',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalSetting() {
    return Column(
      children: [
        // 실행 기록
        Builder(
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
                      Icons.history,
                      color: Colors.orange[700],
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '실행 기록',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                Text(
                  '최근 최적화:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                _buildOptimizationRecord('3일 전', '백그라운드 제한', '+2시간/일'),
                const SizedBox(height: 12),
                _buildOptimizationRecord('1주 전', '다크모드 적용', '+1시간/일'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOptimizationRecord(String date, String action, String benefit) {
    return Builder(
      builder: (context) => Row(
        children: [
          Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$date: $action',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Text(
                  '→ $benefit',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
