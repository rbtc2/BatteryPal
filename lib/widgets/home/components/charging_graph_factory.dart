import 'package:flutter/material.dart';
import '../../../models/charging_graph_theme.dart';
import 'ecg_graph.dart';
import 'spectrum_graph.dart';
import 'wave_graph.dart';
import 'aurora_graph.dart';

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
      
      case ChargingGraphTheme.spectrum:
        return SpectrumGraph(
          dataPoints: dataPoints,
          height: height,
        );
      
      case ChargingGraphTheme.wave:
        return WaveGraph(
          dataPoints: dataPoints,
          height: height,
        );
      
      case ChargingGraphTheme.aurora:
        return AuroraGraph(
          dataPoints: dataPoints,
          height: height,
        );
    }
  }
}

