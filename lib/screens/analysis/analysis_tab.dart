import 'package:flutter/material.dart';
import '../../models/app_models.dart';
import '../../models/battery_history_models.dart';
import '../../widgets/common/common_widgets.dart';
import '../../widgets/charts/charts.dart';
import '../../utils/dialog_utils.dart';
import '../../services/battery_service.dart';
import '../../services/battery_history_service.dart';
import '../../services/battery_analysis_engine.dart';
import '../../services/battery_analysis_chart_service.dart';

/// 배터리 분석 상태를 나타내는 enum
enum BatteryAnalysisState {
  /// 분석 대기 상태 (초기 상태)
  idle,
  /// 분석 진행 중
  analyzing,
  /// 분석 완료
  completed,
  /// 분석 실패
  error,
}

/// 배터리 분석 결과를 담는 클래스
class BatteryAnalysisResult {
  final BatteryHistoryAnalysis analysis;
  final Map<String, dynamic> chartData;
  final List<BatteryHistoryDataPoint> dataPoints;
  final DateTime analysisTime;
  final Duration analysisDuration;

  const BatteryAnalysisResult({
    required this.analysis,
    required this.chartData,
    required this.dataPoints,
    required this.analysisTime,
    required this.analysisDuration,
  });
}

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
  final BatteryService _batteryService = BatteryService();
  final BatteryHistoryService _batteryHistoryService = BatteryHistoryService();
  BatteryInfo? _currentBatteryInfo;
  
  // 배터리 분석 관련 상태 변수들
  BatteryAnalysisState _analysisState = BatteryAnalysisState.idle;
  BatteryAnalysisResult? _analysisResult;
  String? _analysisErrorMessage;
  
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
  void initState() {
    super.initState();
    _initializeBatteryService();
  }

  @override
  void dispose() {
    _batteryService.dispose();
    _batteryHistoryService.dispose();
    super.dispose();
  }

  Future<void> _initializeBatteryService() async {
    await _batteryService.startMonitoring();
    _batteryService.batteryInfoStream.listen((batteryInfo) {
      if (mounted) {
        setState(() {
          _currentBatteryInfo = batteryInfo;
        });
      }
    });
  }

  /// 배터리 분석을 수행하는 메서드
  Future<void> _performBatteryAnalysis() async {
    if (_analysisState == BatteryAnalysisState.analyzing) {
      return; // 이미 분석 중이면 중복 실행 방지
    }

    setState(() {
      _analysisState = BatteryAnalysisState.analyzing;
      _analysisErrorMessage = null;
    });

    try {
      final analysisStartTime = DateTime.now();
      
      // 배터리 히스토리 서비스 초기화
      await _batteryHistoryService.initialize();
      
      // 최근 24시간 데이터 조회
      final endTime = DateTime.now();
      final startTime = endTime.subtract(const Duration(hours: 24));
      
      final historyData = await _batteryHistoryService.getBatteryHistoryData(
        startTime: startTime,
        endTime: endTime,
      );
      
      if (historyData.isEmpty) {
        throw Exception('분석할 배터리 히스토리 데이터가 없습니다. 앱을 사용한 후 다시 시도해주세요.');
      }
      
      // 실제 분석 수행
      final analysis = await BatteryAnalysisEngine.performComprehensiveAnalysis(
        historyData,
        startTime: startTime,
        endTime: endTime,
      );
      
      // 차트 데이터 생성
      final chartData = BatteryAnalysisChartService.convertAnalysisToChartData(
        analysis,
        historyData,
      );
      
      final analysisEndTime = DateTime.now();
      final analysisDuration = analysisEndTime.difference(analysisStartTime);
      
      // 분석 결과 생성
      final result = BatteryAnalysisResult(
        analysis: analysis,
        chartData: chartData,
        dataPoints: historyData,
        analysisTime: analysisEndTime,
        analysisDuration: analysisDuration,
      );
      
      if (mounted) {
        setState(() {
          _analysisState = BatteryAnalysisState.completed;
          _analysisResult = result;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _analysisState = BatteryAnalysisState.error;
          _analysisErrorMessage = '분석 중 오류가 발생했습니다: ${e.toString()}';
        });
      }
    }
  }

  /// 분석 결과를 리셋하는 메서드
  void _resetAnalysis() {
    setState(() {
      _analysisState = BatteryAnalysisState.idle;
      _analysisResult = null;
      _analysisErrorMessage = null;
    });
  }

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
          // 헤더 영역
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '24시간 배터리 사용량',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
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
                    '무료: 최근 24시간',
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
          
          // 분석 버튼 영역
          _buildAnalysisButtonSection(),
          const SizedBox(height: 16),
          
          // 분석 결과 또는 프롬프트 영역
          _buildAnalysisContentArea(),
        ],
      ),
    );
  }

  /// 분석 버튼 섹션을 구성하는 위젯
  Widget _buildAnalysisButtonSection() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _analysisState == BatteryAnalysisState.analyzing 
                ? null 
                : _performBatteryAnalysis,
            icon: Icon(_getAnalysisButtonIcon()),
            label: Text(_getAnalysisButtonText()),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        if (_analysisState == BatteryAnalysisState.completed || 
            _analysisState == BatteryAnalysisState.error) ...[
          const SizedBox(width: 12),
          IconButton(
            onPressed: _resetAnalysis,
            icon: Icon(
              Icons.refresh,
              color: Theme.of(context).colorScheme.primary,
            ),
            tooltip: '새로 분석하기',
          ),
        ],
      ],
    );
  }

  /// 분석 버튼의 아이콘을 반환하는 메서드
  IconData _getAnalysisButtonIcon() {
    switch (_analysisState) {
      case BatteryAnalysisState.idle:
        return Icons.analytics;
      case BatteryAnalysisState.analyzing:
        return Icons.hourglass_empty;
      case BatteryAnalysisState.completed:
        return Icons.check_circle;
      case BatteryAnalysisState.error:
        return Icons.error;
    }
  }

  /// 분석 버튼의 텍스트를 반환하는 메서드
  String _getAnalysisButtonText() {
    switch (_analysisState) {
      case BatteryAnalysisState.idle:
        return '배터리 분석하기';
      case BatteryAnalysisState.analyzing:
        return '분석 중...';
      case BatteryAnalysisState.completed:
        return '분석 완료';
      case BatteryAnalysisState.error:
        return '다시 분석하기';
    }
  }

  /// 분석 콘텐츠 영역을 구성하는 위젯
  Widget _buildAnalysisContentArea() {
    switch (_analysisState) {
      case BatteryAnalysisState.idle:
        return _buildAnalysisPrompt();
      case BatteryAnalysisState.analyzing:
        return _buildAnalysisProgress();
      case BatteryAnalysisState.completed:
        return _buildAnalysisResult();
      case BatteryAnalysisState.error:
        return _buildAnalysisError();
    }
  }

  /// 분석 프롬프트를 표시하는 위젯
  Widget _buildAnalysisPrompt() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 12),
            Text(
              '배터리 사용 패턴 분석',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '최근 24시간의 배터리 사용량을 분석하여\n최적화 제안을 받아보세요',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '분석 시간: 약 2초',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 분석 진행 상태를 표시하는 위젯
  Widget _buildAnalysisProgress() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '배터리 데이터 분석 중...',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '잠시만 기다려주세요',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 분석 결과를 표시하는 위젯
  Widget _buildAnalysisResult() {
    if (_analysisResult == null) return const SizedBox.shrink();
    
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // 분석 완료 헤더
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '분석 완료',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_analysisResult!.analysisDuration.inSeconds}초 소요',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          // 실제 차트 영역
          Container(
            height: 400,
            padding: const EdgeInsets.all(16),
            child: BatteryDashboardChart(
              dataPoints: _analysisResult!.dataPoints,
              height: 400,
              title: '배터리 사용량 분석',
              subtitle: '최근 24시간 배터리 사용 패턴',
              visibleCharts: const [
                BatteryDashboardChartType.level,
                BatteryDashboardChartType.temperature,
                BatteryDashboardChartType.voltage,
              ],
              enableTouchInteraction: true,
              enableAnimation: true,
            ),
          ),
          
          // 분석 요약 정보
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '분석 요약',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildSummaryRow('분석 기간', '${_analysisResult!.analysis.analysisDurationHours.toStringAsFixed(1)}시간'),
                _buildSummaryRow('데이터 포인트', '${_analysisResult!.analysis.dataPointCount}개'),
                _buildSummaryRow('평균 배터리 레벨', '${_analysisResult!.analysis.averageBatteryLevel.toStringAsFixed(1)}%'),
                _buildSummaryRow('배터리 변동폭', '${_analysisResult!.analysis.batteryVariation.toStringAsFixed(1)}%'),
                _buildSummaryRow('효율성 등급', _analysisResult!.analysis.batteryEfficiencyGrade),
                const SizedBox(height: 16),
                _buildInsightsSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 요약 행을 구성하는 위젯
  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
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
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// 인사이트 섹션을 구성하는 위젯
  Widget _buildInsightsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.lightbulb_outline,
              color: Theme.of(context).colorScheme.secondary,
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              '분석 인사이트',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_analysisResult!.analysis.recommendations.isNotEmpty) ...[
          ..._analysisResult!.analysis.recommendations.map((recommendation) => 
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.tips_and_updates,
                    color: Theme.of(context).colorScheme.secondary,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      recommendation,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Text(
              '추가적인 최적화 제안이 없습니다. 현재 사용 패턴이 양호합니다.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// 분석 에러를 표시하는 위젯
  Widget _buildAnalysisError() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.error.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(
              '분석 실패',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _analysisErrorMessage ?? '알 수 없는 오류가 발생했습니다',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onErrorContainer.withValues(alpha: 0.8),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _performBatteryAnalysis,
              icon: const Icon(Icons.refresh),
              label: const Text('다시 시도'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
            ),
          ],
        ),
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
          
          // 배터리 용량 정보 (실제 데이터)
          if (_currentBatteryInfo != null) ...[
            _buildDetailRow('설계 용량', _currentBatteryInfo!.formattedCapacity),
            _buildDetailRow('현재 용량', _currentBatteryInfo!.formattedLevel),
          ] else ...[
            _buildDetailRow('설계 용량', '--mAh'),
            _buildDetailRow('현재 용량', '--%'),
          ],
          
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
