import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 앱 사용 통계 데이터 모델
class AppUsageData {
  final String packageName;
  final Duration totalTimeInForeground;
  final DateTime lastTimeUsed;
  final int launchCount;
  final DateTime firstTimeStamp;
  final DateTime lastTimeStamp;
  
  const AppUsageData({
    required this.packageName,
    required this.totalTimeInForeground,
    required this.lastTimeUsed,
    required this.launchCount,
    required this.firstTimeStamp,
    required this.lastTimeStamp,
  });
  
  /// 앱 이름 추출 (패키지명에서)
  String get appName {
    // 패키지명에서 앱 이름 추출
    final parts = packageName.split('.');
    if (parts.length > 1) {
      return parts.last;
    }
    return packageName;
  }
  
  /// 사용 시간을 포맷팅된 문자열로 반환
  String get formattedUsageTime {
    final hours = totalTimeInForeground.inHours;
    final minutes = totalTimeInForeground.inMinutes % 60;
    
    if (hours > 0) {
      return '$hours시간 $minutes분';
    } else if (minutes > 0) {
      return '$minutes분';
    } else {
      return '${totalTimeInForeground.inSeconds}초';
    }
  }
  
  /// 사용 시간을 분 단위로 반환
  int get usageMinutes => totalTimeInForeground.inMinutes;
  
  /// 앱 사용량 데이터를 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'packageName': packageName,
      'totalTimeInForeground': totalTimeInForeground.inMilliseconds,
      'lastTimeUsed': lastTimeUsed.toIso8601String(),
      'launchCount': launchCount,
      'firstTimeStamp': firstTimeStamp.toIso8601String(),
      'lastTimeStamp': lastTimeStamp.toIso8601String(),
    };
  }
  
  /// JSON에서 앱 사용량 데이터 생성
  factory AppUsageData.fromJson(Map<String, dynamic> json) {
    return AppUsageData(
      packageName: json['packageName'] as String,
      totalTimeInForeground: Duration(milliseconds: json['totalTimeInForeground'] as int),
      lastTimeUsed: DateTime.parse(json['lastTimeUsed'] as String),
      launchCount: json['launchCount'] as int,
      firstTimeStamp: DateTime.parse(json['firstTimeStamp'] as String),
      lastTimeStamp: DateTime.parse(json['lastTimeStamp'] as String),
    );
  }
}

/// 앱 사용 통계 서비스
class AppUsageService {
  static const MethodChannel _channel = MethodChannel('com.example.batterypal/battery');
  
  /// 오늘의 앱 사용 통계 가져오기
  static Future<List<AppUsageData>> getTodayAppUsage() async {
    try {
      debugPrint('앱 사용 통계 요청...');
      final List<dynamic> usageStats = await _channel.invokeMethod('getAppUsageStats');
      
      final List<AppUsageData> appUsageList = usageStats.map((stat) {
        return AppUsageData(
          packageName: stat['packageName'] as String,
          totalTimeInForeground: Duration(milliseconds: stat['totalTimeInForeground'] as int),
          lastTimeUsed: DateTime.fromMillisecondsSinceEpoch(stat['lastTimeUsed'] as int),
          launchCount: stat['launchCount'] as int,
          firstTimeStamp: DateTime.fromMillisecondsSinceEpoch(stat['firstTimeStamp'] as int),
          lastTimeStamp: DateTime.fromMillisecondsSinceEpoch(stat['lastTimeStamp'] as int),
        );
      }).toList();
      
      debugPrint('앱 사용 통계 수집 완료: ${appUsageList.length}개 앱');
      return appUsageList;
      
    } catch (e) {
      debugPrint('앱 사용 통계 가져오기 실패: $e');
      return [];
    }
  }
  
  /// 오늘의 총 스크린 타임 가져오기
  static Future<Duration> getTodayScreenTime() async {
    try {
      debugPrint('스크린 타임 요청...');
      final int screenTimeMs = await _channel.invokeMethod('getTodayScreenTime');
      
      final Duration screenTime = Duration(milliseconds: screenTimeMs);
      debugPrint('스크린 타임 수집 완료: ${screenTime.inMinutes}분');
      return screenTime;
      
    } catch (e) {
      debugPrint('스크린 타임 가져오기 실패: $e');
      return Duration.zero;
    }
  }
  
  /// 사용 통계 권한 확인
  static Future<bool> checkUsageStatsPermission() async {
    try {
      debugPrint('사용 통계 권한 확인...');
      final bool hasPermission = await _channel.invokeMethod('checkUsageStatsPermission');
      
      debugPrint('사용 통계 권한 상태: $hasPermission');
      return hasPermission;
      
    } catch (e) {
      debugPrint('사용 통계 권한 확인 실패: $e');
      return false;
    }
  }
  
  /// 사용 통계 설정 화면 열기
  static Future<void> openUsageStatsSettings() async {
    try {
      debugPrint('사용 통계 설정 화면 열기...');
      await _channel.invokeMethod('openUsageStatsSettings');
      debugPrint('사용 통계 설정 화면 열기 완료');
      
    } catch (e) {
      debugPrint('사용 통계 설정 화면 열기 실패: $e');
    }
  }
  
  /// 스크린 타임을 포맷팅된 문자열로 반환
  static String formatScreenTime(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    
    if (hours > 0) {
      return '$hours시간 $minutes분';
    } else if (minutes > 0) {
      return '$minutes분';
    } else {
      return '${duration.inSeconds}초';
    }
  }
  
  /// 앱 사용량을 백분율로 계산 (전체 스크린 타임 대비)
  static double calculateUsagePercentage(Duration appUsage, Duration totalScreenTime) {
    if (totalScreenTime.inMilliseconds == 0) return 0.0;
    return (appUsage.inMilliseconds / totalScreenTime.inMilliseconds) * 100;
  }
  
  /// 상위 N개 앱 사용량 가져오기
  static Future<List<AppUsageData>> getTopAppsUsage({int limit = 5}) async {
    final List<AppUsageData> allUsage = await getTodayAppUsage();
    
    // 사용 시간이 0보다 큰 앱만 필터링하고 상위 N개 반환
    return allUsage
        .where((app) => app.totalTimeInForeground.inMilliseconds > 0)
        .take(limit)
        .toList();
  }
  
  /// 특정 앱의 사용량 가져오기
  static Future<AppUsageData?> getAppUsage(String packageName) async {
    final List<AppUsageData> allUsage = await getTodayAppUsage();
    
    try {
      return allUsage.firstWhere((app) => app.packageName == packageName);
    } catch (e) {
      return null;
    }
  }
}
