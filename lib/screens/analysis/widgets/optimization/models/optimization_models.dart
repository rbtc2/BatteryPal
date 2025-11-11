import 'package:flutter/material.dart';

/// 최적화 통계 데이터 모델
class OptimizationStats {
  final DateTime lastOptimizedAt;
  final int todayOptimizationCount;
  final Duration todayTotalSaved;
  final int appsKilled;
  final int memoryMB;
  final int cacheMB;
  final int servicesStopped;

  OptimizationStats({
    required this.lastOptimizedAt,
    required this.todayOptimizationCount,
    required this.todayTotalSaved,
    required this.appsKilled,
    required this.memoryMB,
    required this.cacheMB,
    required this.servicesStopped,
  });
}

/// 최적화 항목 데이터 모델
class OptimizationItem {
  final String id;
  final String title;
  final String currentStatus;
  final String effect;
  final IconData icon;
  bool isEnabled;
  final bool isAutomatic; // true: 자동, false: 수동

  OptimizationItem({
    required this.id,
    required this.title,
    required this.currentStatus,
    required this.effect,
    required this.icon,
    this.isEnabled = false,
    required this.isAutomatic,
  });
}

/// 개별 실행 상태 모델
class ExecutionState {
  final bool isExecuting; // 실행 중인지
  final bool justCompleted; // 막 완료되었는지
  final String? completionMessage; // "✓ 완료! +15분"

  ExecutionState({
    this.isExecuting = false,
    this.justCompleted = false,
    this.completionMessage,
  });
}

/// 개별 실행 항목 데이터 모델
class IndividualExecutionItem {
  final String id;
  final String title;
  final String icon; // emoji
  final String currentStatus; // "현재: 15개 실행 중"
  final String lastExecuted; // "1시간 전"
  final String effect; // "+25분"

  IndividualExecutionItem({
    required this.id,
    required this.title,
    required this.icon,
    required this.currentStatus,
    required this.lastExecuted,
    required this.effect,
  });
}

