import 'package:flutter/material.dart';
import '../models/battery_insight_model.dart';
import '../models/app_usage_models.dart';
import '../services/daily_usage_stats_service.dart';

/// 배터리 관점 인사이트 서비스
class BatteryInsightService {
  /// 주간 데이터를 기반으로 배터리 관점 인사이트 생성
  static List<BatteryInsight> generateWeeklyInsights({
    required ScreenTimeSummary todaySummary,
    required List<DailyUsageStats> weeklyStats,
  }) {
    final List<BatteryInsight> insights = [];

    // 1. 주간 평균 대비 현재 사용량 분석
    final averageInsight = _analyzeAverageUsage(todaySummary, weeklyStats);
    if (averageInsight != null) {
      insights.add(averageInsight);
    }

    // 2. 배터리 소모가 높은 앱 식별
    final appInsight = _analyzeTopAppConsumption(todaySummary);
    if (appInsight != null) {
      insights.add(appInsight);
    }

    // 3. 주말/평일 패턴 분석
    final patternInsight = _analyzeWeekendPattern(weeklyStats);
    if (patternInsight != null) {
      insights.add(patternInsight);
    }

    // 최대 3개만 반환
    return insights.take(3).toList();
  }

  /// 주간 평균 대비 현재 사용량 분석
  static BatteryInsight? _analyzeAverageUsage(
    ScreenTimeSummary todaySummary,
    List<DailyUsageStats> weeklyStats,
  ) {
    if (weeklyStats.isEmpty) return null;

    // 데이터가 있는 날짜만 필터링
    final validStats = weeklyStats.where((stat) => 
      stat.screenTime.inMilliseconds > 0
    ).toList();

    if (validStats.length < 2) return null; // 최소 2일 이상 데이터 필요

    // 평균 계산
    final totalMs = validStats.fold<int>(
      0,
      (sum, stat) => sum + stat.screenTime.inMilliseconds,
    );
    final averageMs = totalMs ~/ validStats.length;

    // 오늘 사용량
    final todayMs = todaySummary.totalScreenTime.inMilliseconds;

    // 평균 대비 비율 계산
    if (averageMs == 0) return null;
    final ratio = (todayMs / averageMs) * 100;

    // 15% 이상 차이가 나는 경우에만 인사이트 생성
    if (ratio > 115) {
      final increasePercent = (ratio - 100).round();
      return BatteryInsight(
        title: '이번 주 평균보다 높은 사용',
        message: '오늘의 스크린타임이 주간 평균보다 $increasePercent% 높습니다.',
        recommendation: '배터리 소모량이 증가할 수 있습니다. 사용 시간을 줄이면 배터리 수명에 도움이 됩니다.',
        type: InsightType.usageIncrease,
        icon: Icons.trending_up,
        color: Colors.orange,
      );
    } else if (ratio < 85) {
      final decreasePercent = (100 - ratio).round();
      return BatteryInsight(
        title: '이번 주 평균보다 낮은 사용',
        message: '오늘의 스크린타임이 주간 평균보다 $decreasePercent% 낮습니다.',
        recommendation: '좋은 습관입니다! 배터리 소모가 줄어들어 배터리 수명에 도움이 됩니다.',
        type: InsightType.positive,
        icon: Icons.trending_down,
        color: Colors.green,
      );
    }

    return null;
  }

  /// 배터리 소모가 높은 앱 식별
  static BatteryInsight? _analyzeTopAppConsumption(
    ScreenTimeSummary todaySummary,
  ) {
    if (todaySummary.topApps.isEmpty) return null;

    final topApp = todaySummary.topApps.first;
    
    // 상위 앱이 30% 이상 소모하는 경우
    if (topApp.batteryPercent >= 30) {
      return BatteryInsight(
        title: '${topApp.appName}의 높은 소모',
        message: '${topApp.appName}가 배터리의 ${topApp.batteryPercent.toStringAsFixed(1)}%를 소모하고 있습니다.',
        recommendation: '화면 밝기를 낮추거나, 사용 시간을 줄이면 배터리 소모를 줄일 수 있습니다.',
        type: InsightType.appConsumption,
        icon: Icons.battery_alert,
        color: Colors.red,
      );
    }

    return null;
  }

  /// 주말/평일 패턴 분석
  static BatteryInsight? _analyzeWeekendPattern(
    List<DailyUsageStats> weeklyStats,
  ) {
    if (weeklyStats.length < 7) return null;

    // 평일(월~금)과 주말(토~일) 구분
    final List<DailyUsageStats> weekdayStats = [];
    final List<DailyUsageStats> weekendStats = [];

    for (final stat in weeklyStats) {
      final weekday = stat.date.weekday;
      if (weekday >= 1 && weekday <= 5) {
        weekdayStats.add(stat);
      } else {
        weekendStats.add(stat);
      }
    }

    if (weekdayStats.isEmpty || weekendStats.isEmpty) return null;

    // 평일 평균
    final weekdayTotalMs = weekdayStats
        .where((stat) => stat.screenTime.inMilliseconds > 0)
        .fold<int>(0, (sum, stat) => sum + stat.screenTime.inMilliseconds);
    final weekdayCount = weekdayStats.where((stat) => stat.screenTime.inMilliseconds > 0).length;
    if (weekdayCount == 0) return null;
    final weekdayAverageMs = weekdayTotalMs ~/ weekdayCount;

    // 주말 평균
    final weekendTotalMs = weekendStats
        .where((stat) => stat.screenTime.inMilliseconds > 0)
        .fold<int>(0, (sum, stat) => sum + stat.screenTime.inMilliseconds);
    final weekendCount = weekendStats.where((stat) => stat.screenTime.inMilliseconds > 0).length;
    if (weekendCount == 0) return null;
    final weekendAverageMs = weekendTotalMs ~/ weekendCount;

    if (weekdayAverageMs == 0) return null;

    // 주말이 평일보다 30% 이상 높은 경우
    final ratio = (weekendAverageMs / weekdayAverageMs) * 100;
    if (ratio > 130) {
      final increasePercent = (ratio - 100).round();
      return BatteryInsight(
        title: '주말 사용량 증가',
        message: '주말 사용량이 평일보다 $increasePercent% 높습니다.',
        recommendation: '주말에도 충전 패턴을 조정하면 배터리 수명에 도움이 됩니다.',
        type: InsightType.patternAnalysis,
        icon: Icons.calendar_today,
        color: Colors.blue,
      );
    } else if (ratio < 70) {
      final decreasePercent = (100 - ratio).round();
      return BatteryInsight(
        title: '주말 사용량 감소',
        message: '주말 사용량이 평일보다 $decreasePercent% 낮습니다.',
        recommendation: '좋은 패턴입니다! 주말에 배터리를 아끼고 있습니다.',
        type: InsightType.positive,
        icon: Icons.calendar_today,
        color: Colors.green,
      );
    }

    return null;
  }
}

