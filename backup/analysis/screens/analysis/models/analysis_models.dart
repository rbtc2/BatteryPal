import 'package:flutter/material.dart';
import '../../../models/battery_history_models.dart';

/// 배터리 분석 상태를 나타내는 enum
enum BatteryAnalysisState {
  /// 분석 대기 상태 (초기 상태)
  idle,
  /// 분석 진행 중
  analyzing,
  /// 분석 완료
  completed,
  /// 데이터 수집 중 (이전 error 상태)
  collecting,
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

/// 앱 사용량 데이터 모델 (스켈레톤용)
class AppUsageData {
  final String name;
  final double usage; // 백분율
  final IconData icon;
  final String category;
  final Duration usageTime;
  final DateTime lastUsed;
  final double powerConsumption; // mW

  const AppUsageData({
    required this.name,
    required this.usage,
    required this.icon,
    required this.category,
    required this.usageTime,
    required this.lastUsed,
    required this.powerConsumption,
  });
}

/// 분석 탭의 공통 상태를 관리하는 클래스
class AnalysisTabState {
  final BatteryAnalysisState analysisState;
  final BatteryAnalysisResult? analysisResult;
  final String? analysisStatusMessage;
  final bool isProUser;

  const AnalysisTabState({
    this.analysisState = BatteryAnalysisState.idle,
    this.analysisResult,
    this.analysisStatusMessage,
    this.isProUser = false,
  });

  AnalysisTabState copyWith({
    BatteryAnalysisState? analysisState,
    BatteryAnalysisResult? analysisResult,
    String? analysisStatusMessage,
    bool? isProUser,
  }) {
    return AnalysisTabState(
      analysisState: analysisState ?? this.analysisState,
      analysisResult: analysisResult ?? this.analysisResult,
      analysisStatusMessage: analysisStatusMessage ?? this.analysisStatusMessage,
      isProUser: isProUser ?? this.isProUser,
    );
  }
}
