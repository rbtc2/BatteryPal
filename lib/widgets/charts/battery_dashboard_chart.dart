import 'package:flutter/material.dart';
import '../../models/battery_history_models.dart';
import 'battery_level_chart.dart';
import 'battery_temperature_chart.dart';
import 'battery_voltage_chart.dart';

/// 통합 배터리 대시보드 차트 컴포넌트
/// 배터리 레벨, 온도, 전압을 하나의 대시보드에서 보여주는 전문가 수준의 차트
class BatteryDashboardChart extends StatefulWidget {
  /// 표시할 배터리 히스토리 데이터
  final List<BatteryHistoryDataPoint> dataPoints;
  
  /// 대시보드 높이
  final double height;
  
  /// 대시보드 너비
  final double? width;
  
  /// 대시보드 제목
  final String? title;
  
  /// 대시보드 부제목
  final String? subtitle;
  
  /// 표시할 차트 타입들
  final List<BatteryChartType> visibleCharts;
  
  /// 차트 간격
  final double chartSpacing;
  
  /// 터치 인터랙션 활성화 여부
  final bool enableTouchInteraction;
  
  /// 애니메이션 활성화 여부
  final bool enableAnimation;
  
  /// 애니메이션 지속 시간
  final Duration animationDuration;

  const BatteryDashboardChart({
    super.key,
    required this.dataPoints,
    this.height = 600.0,
    this.width,
    this.title,
    this.subtitle,
    this.visibleCharts = const [
      BatteryChartType.level,
      BatteryChartType.temperature,
      BatteryChartType.voltage,
    ],
    this.chartSpacing = 24.0,
    this.enableTouchInteraction = true,
    this.enableAnimation = true,
    this.animationDuration = const Duration(milliseconds: 1500),
  });

  @override
  State<BatteryDashboardChart> createState() => _BatteryDashboardChartState();
}

class _BatteryDashboardChartState extends State<BatteryDashboardChart> {
  @override
  Widget build(BuildContext context) {
    if (widget.dataPoints.isEmpty) {
      return _buildEmptyDashboard();
    }

    return Container(
      width: widget.width,
      height: widget.height,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.title != null || widget.subtitle != null) ...[
            _buildDashboardHeader(),
            const SizedBox(height: 16),
          ],
          Expanded(
            child: _buildChartsGrid(),
          ),
        ],
      ),
    );
  }

  /// 대시보드 헤더 구성
  Widget _buildDashboardHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.title != null)
          Text(
            widget.title!,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        if (widget.subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            widget.subtitle!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ],
    );
  }

  /// 차트 그리드 구성
  Widget _buildChartsGrid() {
    final visibleCharts = widget.visibleCharts;
    
    if (visibleCharts.length == 1) {
      return _buildSingleChart(visibleCharts.first);
    } else if (visibleCharts.length == 2) {
      return _buildTwoCharts(visibleCharts);
    } else {
      return _buildThreeCharts(visibleCharts);
    }
  }

  /// 단일 차트 구성
  Widget _buildSingleChart(BatteryChartType chartType) {
    return _buildChartByType(chartType, isFullHeight: true);
  }

  /// 두 개 차트 구성
  Widget _buildTwoCharts(List<BatteryChartType> chartTypes) {
    return Column(
      children: [
        Expanded(
          child: _buildChartByType(chartTypes[0]),
        ),
        SizedBox(height: widget.chartSpacing),
        Expanded(
          child: _buildChartByType(chartTypes[1]),
        ),
      ],
    );
  }

  /// 세 개 차트 구성
  Widget _buildThreeCharts(List<BatteryChartType> chartTypes) {
    return Column(
      children: [
        Expanded(
          flex: 2,
          child: _buildChartByType(chartTypes[0]),
        ),
        SizedBox(height: widget.chartSpacing),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: _buildChartByType(chartTypes[1]),
              ),
              SizedBox(width: widget.chartSpacing),
              Expanded(
                child: _buildChartByType(chartTypes[2]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 차트 타입에 따른 차트 구성
  Widget _buildChartByType(BatteryChartType chartType, {bool isFullHeight = false}) {
    final chartHeight = isFullHeight ? null : 200.0;
    
    switch (chartType) {
      case BatteryChartType.level:
        return BatteryLevelChart(
          dataPoints: widget.dataPoints,
          height: chartHeight ?? 200.0,
          title: '배터리 레벨',
          subtitle: '시간별 배터리 사용량',
          enableTouchInteraction: widget.enableTouchInteraction,
          enableAnimation: widget.enableAnimation,
          animationDuration: widget.animationDuration,
        );
      
      case BatteryChartType.temperature:
        return BatteryTemperatureChart(
          dataPoints: widget.dataPoints,
          height: chartHeight ?? 200.0,
          title: '배터리 온도',
          subtitle: '시간별 온도 변화',
          enableTouchInteraction: widget.enableTouchInteraction,
          enableAnimation: widget.enableAnimation,
          animationDuration: widget.animationDuration,
        );
      
      case BatteryChartType.voltage:
        return BatteryVoltageChart(
          dataPoints: widget.dataPoints,
          height: chartHeight ?? 200.0,
          title: '배터리 전압',
          subtitle: '시간별 전압 변화',
          enableTouchInteraction: widget.enableTouchInteraction,
          enableAnimation: widget.enableAnimation,
          animationDuration: widget.animationDuration,
        );
    }
  }

  /// 빈 대시보드 구성
  Widget _buildEmptyDashboard() {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.dashboard,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              '배터리 대시보드',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '표시할 데이터가 없습니다',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 배터리 차트 타입 열거형 (대시보드용)
enum BatteryChartType {
  level,
  temperature,
  voltage,
}

/// 배터리 대시보드 설정 클래스
class BatteryDashboardConfig {
  /// 기본 표시 차트
  static const List<BatteryChartType> defaultVisibleCharts = [
    BatteryChartType.level,
    BatteryChartType.temperature,
    BatteryChartType.voltage,
  ];
  
  /// 차트 간격
  static const double defaultChartSpacing = 24.0;
  
  /// 기본 대시보드 높이
  static const double defaultHeight = 600.0;
  
  /// 애니메이션 지속 시간
  static const Duration defaultAnimationDuration = Duration(milliseconds: 1500);
  
  /// 차트별 기본 높이
  static const Map<BatteryChartType, double> chartHeights = {
    BatteryChartType.level: 200.0,
    BatteryChartType.temperature: 150.0,
    BatteryChartType.voltage: 150.0,
  };
  
  /// 차트별 제목
  static const Map<BatteryChartType, String> chartTitles = {
    BatteryChartType.level: '배터리 레벨',
    BatteryChartType.temperature: '배터리 온도',
    BatteryChartType.voltage: '배터리 전압',
  };
  
  /// 차트별 부제목
  static const Map<BatteryChartType, String> chartSubtitles = {
    BatteryChartType.level: '시간별 배터리 사용량',
    BatteryChartType.temperature: '시간별 온도 변화',
    BatteryChartType.voltage: '시간별 전압 변화',
  };
}
