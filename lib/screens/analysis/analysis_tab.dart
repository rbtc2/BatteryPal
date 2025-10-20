import 'package:flutter/material.dart';
import '../../models/app_models.dart';
import '../../widgets/common/common_widgets.dart';
import '../../utils/dialog_utils.dart';

/// 분석 탭 화면
/// Phase 6에서 실제 구현
class AnalysisTab extends StatefulWidget {
  final bool isProUser;
  final VoidCallback onProToggle;

  const AnalysisTab({
    super.key,
    required this.isProUser,
    required this.onProToggle,
  });

  @override
  State<AnalysisTab> createState() => _AnalysisTabState();
}

class _AnalysisTabState extends State<AnalysisTab> {
  // 스켈레톤용 더미 데이터
  List<AppUsageData> appUsageData = [
    AppUsageData(
      name: 'YouTube',
      usage: 25,
      icon: Icons.play_circle,
      category: '엔터테인먼트',
      usageTime: const Duration(hours: 2, minutes: 30),
      lastUsed: DateTime.now().subtract(const Duration(minutes: 15)),
      powerConsumption: 150.0,
    ),
    AppUsageData(
      name: 'Instagram',
      usage: 18,
      icon: Icons.camera_alt,
      category: '소셜',
      usageTime: const Duration(hours: 1, minutes: 45),
      lastUsed: DateTime.now().subtract(const Duration(minutes: 5)),
      powerConsumption: 120.0,
    ),
    AppUsageData(
      name: 'Chrome',
      usage: 15,
      icon: Icons.web,
      category: '브라우저',
      usageTime: const Duration(hours: 1, minutes: 20),
      lastUsed: DateTime.now().subtract(const Duration(minutes: 2)),
      powerConsumption: 100.0,
    ),
    AppUsageData(
      name: 'WhatsApp',
      usage: 12,
      icon: Icons.message,
      category: '메신저',
      usageTime: const Duration(hours: 1, minutes: 5),
      lastUsed: DateTime.now().subtract(const Duration(minutes: 30)),
      powerConsumption: 80.0,
    ),
    AppUsageData(
      name: 'Spotify',
      usage: 8,
      icon: Icons.music_note,
      category: '음악',
      usageTime: const Duration(minutes: 45),
      lastUsed: DateTime.now().subtract(const Duration(hours: 1)),
      powerConsumption: 60.0,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('배터리 분석'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        actions: [
          if (!widget.isProUser)
            TextButton(
              onPressed: () => DialogUtils.showAnalysisProUpgradeDialog(
                context,
                onUpgrade: widget.onProToggle,
              ),
              child: const Text('Pro로 업그레이드'),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 배터리 사용량 차트
            _buildBatteryChartCard(),
            const SizedBox(height: 24),
            
            // 배터리 상세 정보 섹션
            _buildBatteryDetailsCard(),
            const SizedBox(height: 24),
            
            // 배터리 성능 지표 섹션
            _buildBatteryPerformanceCard(),
            const SizedBox(height: 24),
            
            // 앱별 전력 소비
            _buildAppUsageCard(),
            const SizedBox(height: 24),
            
            // Pro 기능 미리보기
            if (!widget.isProUser) _buildProPreviewCard(),
            
            const SizedBox(height: 24),
            
            // 일일 요약
            _buildDailySummaryCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildBatteryChartCard() {
    return CustomCard(
      elevation: 4,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '24시간 배터리 사용량',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (!widget.isProUser)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '무료: 최근 7일',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          
          // 차트 영역 (스켈레톤)
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.show_chart,
                    size: 48,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '배터리 사용량 차트',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Phase 6에서 실제 차트 구현 완료',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppUsageCard() {
    return CustomCard(
      elevation: 4,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '앱별 전력 소비',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (!widget.isProUser)
                TextButton(
                  onPressed: () => DialogUtils.showAnalysisProUpgradeDialog(
                    context,
                    onUpgrade: widget.onProToggle,
                  ),
                  child: const Text('Pro로 전체 보기'),
                ),
            ],
          ),
          const SizedBox(height: 16),
          
          // 앱 사용량 리스트 (무료: 상위 5개만)
          ...appUsageData.take(widget.isProUser ? appUsageData.length : 5).map((app) {
            return _buildAppUsageItem(app);
          }),
          
          // Pro 기능 안내
          if (!widget.isProUser)
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lock,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Pro로 모든 앱의 상세 분석을 확인하세요',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAppUsageItem(AppUsageData app) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // 앱 아이콘
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              app.icon,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          
          // 앱 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  app.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${app.usage}% 배터리 사용',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          // 사용량 바
          Container(
            width: 60,
            height: 8,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: app.usage / 100,
              child: Container(
                decoration: BoxDecoration(
                  color: _getUsageColor(app.usage.toDouble()),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProPreviewCard() {
    return CustomCard(
      elevation: 2,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.star,
                color: Colors.amber,
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                'Pro 기능 미리보기',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Pro 기능 목록
          _buildProFeatureItem('배터리 건강도 트렌드', Icons.trending_up),
          _buildProFeatureItem('충전 패턴 분석', Icons.battery_charging_full),
          _buildProFeatureItem('AI 인사이트', Icons.psychology),
          _buildProFeatureItem('상세 리포트', Icons.assessment),
          
          const SizedBox(height: 16),
          
          // 업그레이드 버튼
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => DialogUtils.showAnalysisProUpgradeDialog(
                context,
                onUpgrade: widget.onProToggle,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'Pro로 업그레이드',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProFeatureItem(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildDailySummaryCard() {
    return CustomCard(
      elevation: 2,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '오늘의 요약',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              SummaryItem(
                label: '총 사용량',
                value: '78%',
              ),
              SummaryItem(
                label: '절약된 전력',
                value: '120mW',
              ),
              SummaryItem(
                label: '최적화 횟수',
                value: '3회',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getUsageColor(double usage) {
    if (usage > 20) return Colors.red;
    if (usage > 10) return Colors.orange;
    return Colors.green;
  }

  Widget _buildBatteryDetailsCard() {
    return CustomCard(
      elevation: 4,
      borderRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.battery_std,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                '배터리 상세 정보',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // 배터리 기술 정보
          _buildDetailRow('배터리 기술', 'Li-Ion'),
          _buildDetailRow('제조사', 'Samsung SDI'),
          _buildDetailRow('설계 용량', '4,500 mAh'),
          _buildDetailRow('현재 용량', '4,200 mAh (93%)'),
          _buildDetailRow('충전 사이클', '1,247회'),
          _buildDetailRow('마지막 교체', '2023년 3월'),
          
          const SizedBox(height: 16),
          
          // 배터리 상태 지표
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '배터리 상태 지표',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                _buildStatusIndicator('건강도', 85, Colors.green),
                _buildStatusIndicator('성능', 78, Colors.orange),
                _buildStatusIndicator('안전성', 92, Colors.green),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBatteryPerformanceCard() {
    return CustomCard(
      elevation: 4,
      borderRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.speed,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                '배터리 성능 지표',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // 성능 메트릭
          Row(
            children: [
              Expanded(
                child: _buildPerformanceMetric(
                  '평균 사용 시간',
                  '18시간 32분',
                  Icons.access_time,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildPerformanceMetric(
                  '충전 속도',
                  '45분',
                  Icons.flash_on,
                  Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildPerformanceMetric(
                  '방전 속도',
                  '2.3%/시간',
                  Icons.trending_down,
                  Colors.red,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildPerformanceMetric(
                  '효율성',
                  '87%',
                  Icons.trending_up,
                  Colors.green,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // 최적화 제안
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '최적화 제안',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildSuggestionItem('화면 밝기를 70%로 낮추면 2시간 더 사용 가능'),
                _buildSuggestionItem('백그라운드 앱을 정리하면 배터리 수명 15% 향상'),
                _buildSuggestionItem('Wi-Fi 대신 모바일 데이터 사용 시 전력 소모 증가'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(String label, int value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Expanded(
            flex: 3,
            child: LinearProgressIndicator(
              value: value / 100,
              backgroundColor: color.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$value%',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceMetric(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionItem(String suggestion) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 4,
            margin: const EdgeInsets.only(top: 8, right: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              suggestion,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
