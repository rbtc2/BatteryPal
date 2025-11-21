import 'package:flutter/material.dart';
import '../../../models/charging_monitor_display_mode.dart';
import '../../../models/charging_graph_theme.dart';
import '../../../utils/charging_graph_theme_colors.dart';
import 'charging_info_row.dart';
import 'charging_graph_factory.dart';

/// 실시간 충전 뷰
/// 충전 중일 때 실시간 그래프와 정보를 표시하는 위젯
class RealtimeChargingView extends StatelessWidget {
  final List<double> dataPoints;
  final int currentValue;
  final ChargingMonitorDisplayMode displayMode;
  final ChargingGraphTheme graphTheme;
  final Duration? elapsedDuration;
  final double graphHeight;
  final double infoRowHeight;

  const RealtimeChargingView({
    super.key,
    required this.dataPoints,
    required this.currentValue,
    required this.displayMode,
    required this.graphTheme,
    this.elapsedDuration,
    this.graphHeight = 180.0,
    this.infoRowHeight = 60.0,
  });

  @override
  Widget build(BuildContext context) {
    // 테마별 색상 스키마 가져오기
    final backgroundColor = ChargingGraphThemeColors.getBackgroundColor(graphTheme);
    final backgroundGradient = ChargingGraphThemeColors.getBackgroundGradient(graphTheme);
    final borderColor = ChargingGraphThemeColors.getBorderColor(graphTheme);

    return Container(
      key: ValueKey('realtime_charging_view_${graphTheme.name}'),
      decoration: BoxDecoration(
        // 그라데이션이 있으면 그라데이션 사용, 없으면 단색 사용
        gradient: backgroundGradient,
        color: backgroundGradient == null ? backgroundColor : null,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Column(
        children: [
          // 테마에 따른 그래프
          // key를 사용하여 테마 변경 시 위젯이 확실히 rebuild되도록 함
          ChargingGraphFactory.createGraph(
            theme: graphTheme,
            dataPoints: dataPoints,
            height: graphHeight,
          ),
          
          const SizedBox(height: 20),
          
          // 충전 속도와 지속 시간 (한 줄에 배치)
          SizedBox(
            height: infoRowHeight, // 고정 높이로 스크롤 방지
            child: ChargingInfoRow(
              currentValue: currentValue,
              displayMode: displayMode,
              elapsedDuration: elapsedDuration,
            ),
          ),
        ],
      ),
    );
  }
}

