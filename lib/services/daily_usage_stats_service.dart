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
  /// 날짜가 바뀌었는지 확인하고, 어제의 최종 데이터를 저장
  /// summary는 현재 날짜의 데이터이며, 날짜가 바뀌었을 때는 어제의 최종 데이터로 저장됩니다.
  static Future<void> checkAndSaveYesterday(ScreenTimeSummary? summary) async {
    if (summary == null || !summary.hasPermission) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      final lastSavedDateStr = prefs.getString(_lastSavedDateKey);
      
      // 처음 실행이거나 저장된 데이터가 없는 경우
      if (lastSavedDateStr == null) {
        // 오늘 날짜를 저장하고, 내일 자정에 오늘 데이터를 어제로 저장하도록 준비
        await prefs.setString(_lastSavedDateKey, today.toIso8601String());
        debugPrint('DailyUsageStatsService: 첫 실행 - 오늘 날짜 저장 완료');
        return;
      }
      
      final lastSavedDate = DateTime.parse(lastSavedDateStr);
      final lastSavedDay = DateTime(lastSavedDate.year, lastSavedDate.month, lastSavedDate.day);
      
      // 날짜가 바뀌었는지 확인 (자정이 지났는지)
      if (lastSavedDay.isBefore(today)) {
        // 날짜가 바뀌었다면, 현재 summary는 어제의 최종 데이터입니다.
        // (날짜가 바뀌었지만 아직 오늘의 데이터가 수집되지 않았으므로)
        // 하지만 실제로는 summary가 오늘의 데이터일 수도 있으므로,
        // 마지막으로 저장된 오늘의 데이터를 "어제 데이터"로 저장하는 것이 더 안전합니다.
        // 현재는 summary를 어제 데이터로 저장합니다.
        await saveYesterdayData(summary, lastSavedDay);
        // 오늘 날짜로 업데이트
        await prefs.setString(_lastSavedDateKey, today.toIso8601String());
        debugPrint('DailyUsageStatsService: 어제 데이터 저장 완료 (${lastSavedDay.toIso8601String()})');
      } else if (lastSavedDay.isAtSameMomentAs(today)) {
        // 같은 날짜이면, 오늘의 최종 데이터를 임시로 저장 (내일 자정에 어제 데이터로 사용)
        // 이렇게 하면 자정에 앱이 실행되지 않아도 다음에 앱이 시작될 때 어제 데이터를 저장할 수 있습니다.
        await _saveTodayDataForTomorrow(summary, today);
      }
    } catch (e) {
      debugPrint('어제 데이터 저장 체크 실패: $e');
    }
  }

  /// 오늘의 데이터를 임시로 저장 (내일 자정에 어제 데이터로 사용)
  static Future<void> _saveTodayDataForTomorrow(ScreenTimeSummary summary, DateTime today) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 상위 앱 정보 추출
      final topAppName = summary.topApps.isNotEmpty 
          ? summary.topApps.first.appName 
          : '없음';
      final topAppPercent = summary.topApps.isNotEmpty 
          ? summary.topApps.first.batteryPercent 
          : 0.0;

      // 오늘 데이터를 임시로 저장 (날짜는 오늘로 저장)
      await prefs.setString('${_prefsKey}_temp_date', today.toIso8601String());
      await prefs.setInt('${_prefsKey}_temp_screenTime', summary.totalScreenTime.inMilliseconds);
      await prefs.setInt('${_prefsKey}_temp_backgroundTime', summary.backgroundTime.inMilliseconds);
      await prefs.setInt('${_prefsKey}_temp_totalUsageTime', summary.totalUsageTime.inMilliseconds);
      await prefs.setDouble('${_prefsKey}_temp_backgroundPercent', summary.backgroundConsumptionPercent);
      await prefs.setString('${_prefsKey}_temp_topAppName', topAppName);
      await prefs.setDouble('${_prefsKey}_temp_topAppPercent', topAppPercent);
      
      debugPrint('DailyUsageStatsService: 오늘 데이터 임시 저장 완료 (내일 어제 데이터로 사용)');
    } catch (e) {
      debugPrint('오늘 데이터 임시 저장 실패: $e');
    }
  }

  /// 어제의 최종 데이터를 저장 (날짜와 함께)
  static Future<void> saveYesterdayData(ScreenTimeSummary summary, DateTime yesterdayDate) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 상위 앱 정보 추출
      final topAppName = summary.topApps.isNotEmpty 
          ? summary.topApps.first.appName 
          : '없음';
      final topAppPercent = summary.topApps.isNotEmpty 
          ? summary.topApps.first.batteryPercent 
          : 0.0;

      // 어제 데이터 저장 (각 필드를 개별 저장)
      await prefs.setString('${_prefsKey}_date', yesterdayDate.toIso8601String());
      await prefs.setInt('${_prefsKey}_screenTime', summary.totalScreenTime.inMilliseconds);
      await prefs.setInt('${_prefsKey}_backgroundTime', summary.backgroundTime.inMilliseconds);
      await prefs.setInt('${_prefsKey}_totalUsageTime', summary.totalUsageTime.inMilliseconds);
      await prefs.setDouble('${_prefsKey}_backgroundPercent', summary.backgroundConsumptionPercent);
      await prefs.setString('${_prefsKey}_topAppName', topAppName);
      await prefs.setDouble('${_prefsKey}_topAppPercent', topAppPercent);
      
      debugPrint('DailyUsageStatsService: 어제 데이터 저장 완료 - $topAppName (${topAppPercent.toStringAsFixed(1)}%)');
    } catch (e) {
      debugPrint('어제 데이터 저장 실패: $e');
    }
  }

  /// 앱 시작 시 어제 데이터 저장 확인 (날짜가 바뀌었는지 체크)
  /// 이 메서드는 앱이 시작될 때 호출되어야 합니다
  static Future<void> checkAndSaveYesterdayOnAppStart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      final lastSavedDateStr = prefs.getString(_lastSavedDateKey);
      
      // 처음 실행인 경우
      if (lastSavedDateStr == null) {
        await prefs.setString(_lastSavedDateKey, today.toIso8601String());
        debugPrint('DailyUsageStatsService: 첫 실행 - 오늘 날짜 저장');
        return;
      }
      
      final lastSavedDate = DateTime.parse(lastSavedDateStr);
      final lastSavedDay = DateTime(lastSavedDate.year, lastSavedDate.month, lastSavedDate.day);
      
      // 날짜가 바뀌었는지 확인
      if (lastSavedDay.isBefore(today)) {
        // 날짜가 바뀌었다면, 임시로 저장된 어제의 최종 데이터를 "어제 데이터"로 저장
        final tempDateStr = prefs.getString('${_prefsKey}_temp_date');
        final tempScreenTimeMs = prefs.getInt('${_prefsKey}_temp_screenTime');
        final tempBackgroundTimeMs = prefs.getInt('${_prefsKey}_temp_backgroundTime');
        final tempTotalUsageTimeMs = prefs.getInt('${_prefsKey}_temp_totalUsageTime');
        final tempBackgroundPercent = prefs.getDouble('${_prefsKey}_temp_backgroundPercent');
        final tempTopAppName = prefs.getString('${_prefsKey}_temp_topAppName');
        final tempTopAppPercent = prefs.getDouble('${_prefsKey}_temp_topAppPercent');
        
        if (tempDateStr != null && tempScreenTimeMs != null) {
          // 임시 저장된 데이터가 있으면 어제 데이터로 저장
          final yesterday = lastSavedDay;
          
          await prefs.setString('${_prefsKey}_date', yesterday.toIso8601String());
          await prefs.setInt('${_prefsKey}_screenTime', tempScreenTimeMs);
          await prefs.setInt('${_prefsKey}_backgroundTime', tempBackgroundTimeMs ?? 0);
          await prefs.setInt('${_prefsKey}_totalUsageTime', tempTotalUsageTimeMs ?? tempScreenTimeMs);
          await prefs.setDouble('${_prefsKey}_backgroundPercent', tempBackgroundPercent ?? 0.0);
          await prefs.setString('${_prefsKey}_topAppName', tempTopAppName ?? '없음');
          await prefs.setDouble('${_prefsKey}_topAppPercent', tempTopAppPercent ?? 0.0);
          
          // 임시 데이터 삭제
          await prefs.remove('${_prefsKey}_temp_date');
          await prefs.remove('${_prefsKey}_temp_screenTime');
          await prefs.remove('${_prefsKey}_temp_backgroundTime');
          await prefs.remove('${_prefsKey}_temp_totalUsageTime');
          await prefs.remove('${_prefsKey}_temp_backgroundPercent');
          await prefs.remove('${_prefsKey}_temp_topAppName');
          await prefs.remove('${_prefsKey}_temp_topAppPercent');
          
          debugPrint('DailyUsageStatsService: 앱 시작 시 어제 데이터 저장 완료 (${yesterday.toIso8601String()})');
        }
        
        // 오늘 날짜로 업데이트
        await prefs.setString(_lastSavedDateKey, today.toIso8601String());
        debugPrint('DailyUsageStatsService: 날짜 변경 감지 - ${lastSavedDay.toIso8601String()} -> ${today.toIso8601String()}');
      }
    } catch (e) {
      debugPrint('앱 시작 시 어제 데이터 체크 실패: $e');
    }
  }
}

