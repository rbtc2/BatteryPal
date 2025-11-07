import 'package:flutter/material.dart';

/// 배터리 관점 인사이트 모델
class BatteryInsight {
  final String title;
  final String message;
  final String recommendation;
  final InsightType type;
  final IconData icon;
  final Color color;

  const BatteryInsight({
    required this.title,
    required this.message,
    required this.recommendation,
    required this.type,
    required this.icon,
    required this.color,
  });
}

/// 인사이트 타입
enum InsightType {
  /// 사용량 증가 경고
  usageIncrease,
  
  /// 앱별 소모 분석
  appConsumption,
  
  /// 패턴 분석
  patternAnalysis,
  
  /// 긍정적 피드백
  positive,
}

