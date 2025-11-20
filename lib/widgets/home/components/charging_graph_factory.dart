import 'package:flutter/material.dart';
import '../../../models/charging_graph_theme.dart';
import 'ecg_graph.dart';
import 'oscilloscope_graph.dart';
import 'bar_graph.dart';

/// 충전 그래프 팩토리
/// 테마에 따라 적절한 그래프 위젯을 생성하는 팩토리 클래스
class ChargingGraphFactory {
  /// 테마에 따라 그래프 위젯을 생성
  static Widget createGraph({
    required ChargingGraphTheme theme,
    required List<double> dataPoints,
    required double height,
  }) {
    switch (theme) {
      case ChargingGraphTheme.ecg:
        return ECGGraph(
          dataPoints: dataPoints,
          height: height,
        );
      
      case ChargingGraphTheme.oscilloscope:
        return OscilloscopeGraph(
          dataPoints: dataPoints,
          height: height,
        );
      
      case ChargingGraphTheme.bar:
        return BarGraph(
          dataPoints: dataPoints,
          height: height,
        );
      
      // 아직 구현되지 않은 테마들은 기본값(ECG)으로 대체
      // 향후 각 테마별 구현이 완료되면 해당 case를 추가하여 실제 그래프 위젯을 반환
      case ChargingGraphTheme.wave:
      case ChargingGraphTheme.particle:
      case ChargingGraphTheme.electric:
      case ChargingGraphTheme.spectrum:
      case ChargingGraphTheme.dna:
        // 임시로 ECG 그래프를 반환 (각 테마 구현 완료 후 교체 예정)
        return ECGGraph(
          dataPoints: dataPoints,
          height: height,
        );
    }
  }
}

