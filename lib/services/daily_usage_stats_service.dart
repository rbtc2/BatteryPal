import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_usage_models.dart';

/// 일일 사용 통계 데이터 모델
class DailyUsageStats {
  final DateTime date;
  final Duration screenTime;
  final Duration backgroundTime;
  final Duration totalUsageTime;
  final double backgroundConsumptionPercent;
  final String topAppName;
  final double topAppPercent;

  const DailyUsageStats({
    required this.date,
    required this.screenTime,
    required this.backgroundTime,
    required this.totalUsageTime,
    required this.backgroundConsumptionPercent,
    required this.topAppName,
    required this.topAppPercent,
  });

  /// JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'screenTime': screenTime.inMilliseconds,
      'backgroundTime': backgroundTime.inMilliseconds,
      'totalUsageTime': totalUsageTime.inMilliseconds,
      'backgroundConsumptionPercent': backgroundConsumptionPercent,
      'topAppName': topAppName,
      'topAppPercent': topAppPercent,
    };
  }

  /// JSON에서 생성
  factory DailyUsageStats.fromJson(Map<String, dynamic> json) {
    return DailyUsageStats(
      date: DateTime.parse(json['date'] as String),
      screenTime: Duration(milliseconds: json['screenTime'] as int),
      backgroundTime: Duration(milliseconds: json['backgroundTime'] as int),
      totalUsageTime: Duration(milliseconds: json['totalUsageTime'] as int),
      backgroundConsumptionPercent: json['backgroundConsumptionPercent'] as double,
      topAppName: json['topAppName'] as String,
      topAppPercent: json['topAppPercent'] as double,
    );
  }
}

/// 일일 사용 통계 관리 서비스
class DailyUsageStatsService {
  static const String _prefsKey = 'daily_usage_stats';
  static const String _lastSavedDateKey = 'last_saved_date';

  /// 어제 데이터 가져오기 (각 필드를 개별 저장)
  static Future<DailyUsageStats?> getYesterdayStatsImproved() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final dateStr = prefs.getString('${_prefsKey}_date');
      final screenTimeMs = prefs.getInt('${_prefsKey}_screenTime');
      final backgroundTimeMs = prefs.getInt('${_prefsKey}_backgroundTime');
      final totalUsageTimeMs = prefs.getInt('${_prefsKey}_totalUsageTime');
      final backgroundPercent = prefs.getDouble('${_prefsKey}_backgroundPercent');
      final topAppName = prefs.getString('${_prefsKey}_topAppName');
      final topAppPercent = prefs.getDouble('${_prefsKey}_topAppPercent');

      if (dateStr == null || screenTimeMs == null) {
        return null;
      }

      final date = DateTime.parse(dateStr);
      
      // 저장된 날짜가 실제로 어제인지 확인
      final now = DateTime.now();
      final yesterday = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 1));
      
      if (date.year != yesterday.year ||
          date.month != yesterday.month ||
          date.day != yesterday.day) {
        return null;
      }

      return DailyUsageStats(
        date: date,
        screenTime: Duration(milliseconds: screenTimeMs),
        backgroundTime: Duration(milliseconds: backgroundTimeMs ?? 0),
        totalUsageTime: Duration(milliseconds: totalUsageTimeMs ?? screenTimeMs),
        backgroundConsumptionPercent: backgroundPercent ?? 0.0,
        topAppName: topAppName ?? '없음',
        topAppPercent: topAppPercent ?? 0.0,
      );
    } catch (e) {
      debugPrint('어제 데이터 가져오기 실패: $e');
      return null;
    }
  }

  /// 오늘의 데이터를 어제 데이터로 저장 (개선된 버전)
  static Future<void> saveTodayAsYesterdayImproved(ScreenTimeSummary summary) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      // 마지막 저장 날짜 확인
      final lastSavedDateStr = prefs.getString(_lastSavedDateKey);
      if (lastSavedDateStr != null) {
        final lastSavedDate = DateTime.parse(lastSavedDateStr);
        // 같은 날짜면 저장하지 않음 (하루에 한 번만 저장)
        if (lastSavedDate.isAtSameMomentAs(today)) {
          debugPrint('오늘 데이터는 이미 저장되었습니다.');
          return;
        }
      }

      // 상위 앱 정보 추출
      final topAppName = summary.topApps.isNotEmpty 
          ? summary.topApps.first.appName 
          : '없음';
      final topAppPercent = summary.topApps.isNotEmpty 
          ? summary.topApps.first.batteryPercent 
          : 0.0;

      // 오늘 데이터를 어제 데이터로 저장 (각 필드를 개별 저장)
      final yesterday = today.subtract(const Duration(days: 1));
      
      await prefs.setString('${_prefsKey}_date', yesterday.toIso8601String());
      await prefs.setInt('${_prefsKey}_screenTime', summary.totalScreenTime.inMilliseconds);
      await prefs.setInt('${_prefsKey}_backgroundTime', summary.backgroundTime.inMilliseconds);
      await prefs.setInt('${_prefsKey}_totalUsageTime', summary.totalUsageTime.inMilliseconds);
      await prefs.setDouble('${_prefsKey}_backgroundPercent', summary.backgroundConsumptionPercent);
      await prefs.setString('${_prefsKey}_topAppName', topAppName);
      await prefs.setDouble('${_prefsKey}_topAppPercent', topAppPercent);
      await prefs.setString(_lastSavedDateKey, today.toIso8601String());
      
      debugPrint('어제 데이터 저장 완료: $topAppName (${topAppPercent.toStringAsFixed(1)}%)');
    } catch (e) {
      debugPrint('어제 데이터 저장 실패: $e');
    }
  }

  /// 자정에 자동으로 호출되도록 체크 (앱 시작 시 또는 데이터 업데이트 시)
  static Future<void> checkAndSaveYesterday(ScreenTimeSummary? summary) async {
    if (summary == null || !summary.hasPermission) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      final lastSavedDateStr = prefs.getString(_lastSavedDateKey);
      
      // 저장된 데이터가 없거나, 마지막 저장 날짜가 오늘이 아니면 저장
      if (lastSavedDateStr == null) {
        // 처음 실행이거나 저장된 데이터가 없으면 저장하지 않음
        // (오늘 데이터를 어제로 저장하려면 내일 자정에 저장해야 함)
        return;
      }
      
      final lastSavedDate = DateTime.parse(lastSavedDateStr);
      final lastSavedDay = DateTime(lastSavedDate.year, lastSavedDate.month, lastSavedDate.day);
      
      // 마지막 저장 날짜가 어제이고 오늘이면, 어제 데이터를 저장
      final yesterday = today.subtract(const Duration(days: 1));
      if (lastSavedDay.isAtSameMomentAs(yesterday)) {
        // 어제 데이터를 저장해야 함
        await saveTodayAsYesterdayImproved(summary);
      }
    } catch (e) {
      debugPrint('어제 데이터 저장 체크 실패: $e');
    }
  }
}

