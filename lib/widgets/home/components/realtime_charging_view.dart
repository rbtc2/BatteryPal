import 'package:flutter/material.dart';
import '../../../models/charging_monitor_display_mode.dart';
import 'ecg_graph.dart';
import 'charging_info_row.dart';

/// 실시간 충전 뷰
/// 충전 중일 때 실시간 그래프와 정보를 표시하는 위젯
class RealtimeChargingView extends StatelessWidget {
  final List<double> dataPoints;
  final int currentValue;
  final ChargingMonitorDisplayMode displayMode;
  final Duration? elapsedDuration;
  final double graphHeight;
  final double infoRowHeight;

  const RealtimeChargingView({
    super.key,
    required this.dataPoints,
    required this.currentValue,
    required this.displayMode,
    this.elapsedDuration,
    this.graphHeight = 180.0,
    this.infoRowHeight = 60.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.green.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Column(
        children: [
          // 심전도 스타일 그래프
          ECGGraph(
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

