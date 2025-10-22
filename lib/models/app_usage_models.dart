import 'package:flutter/material.dart';
import '../services/app_usage_service.dart';

/// 실제 앱 사용 데이터 모델 (기존 _AppUsageData 대체)
class RealAppUsageData {
  final String packageName;
  final String appName;
  final Duration totalTimeInForeground;
  final Duration backgroundTime;
  final double batteryPercent;
  final int launchCount;
  final DateTime lastTimeUsed;
  final Color color;
  
  const RealAppUsageData({
    required this.packageName,
    required this.appName,
    required this.totalTimeInForeground,
    required this.backgroundTime,
    required this.batteryPercent,
    required this.launchCount,
    required this.lastTimeUsed,
    required this.color,
  });
  
  /// 사용 시간을 포맷팅된 문자열로 반환
  String get formattedScreenTime {
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
  
  /// 백그라운드 시간을 포맷팅된 문자열로 반환
  String get formattedBackgroundTime {
    final hours = backgroundTime.inHours;
    final minutes = backgroundTime.inMinutes % 60;
    
    if (hours > 0) {
      return '$hours시간 $minutes분';
    } else if (minutes > 0) {
      return '$minutes분';
    } else {
      return '${backgroundTime.inSeconds}초';
    }
  }
  
  /// 배터리 사용량을 포맷팅된 문자열로 반환
  String get formattedBatteryPercent => '${batteryPercent.toStringAsFixed(1)}%';
  
  /// 앱 사용량 데이터를 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'packageName': packageName,
      'appName': appName,
      'totalTimeInForeground': totalTimeInForeground.inMilliseconds,
      'backgroundTime': backgroundTime.inMilliseconds,
      'batteryPercent': batteryPercent,
      'launchCount': launchCount,
      'lastTimeUsed': lastTimeUsed.toIso8601String(),
      'color': color.toARGB32(),
    };
  }
  
  /// JSON에서 앱 사용량 데이터 생성
  factory RealAppUsageData.fromJson(Map<String, dynamic> json) {
    return RealAppUsageData(
      packageName: json['packageName'] as String,
      appName: json['appName'] as String,
      totalTimeInForeground: Duration(milliseconds: json['totalTimeInForeground'] as int),
      backgroundTime: Duration(milliseconds: json['backgroundTime'] as int),
      batteryPercent: json['batteryPercent'] as double,
      launchCount: json['launchCount'] as int,
      lastTimeUsed: DateTime.parse(json['lastTimeUsed'] as String),
      color: Color(json['color'] as int),
    );
  }
}

/// 스크린 타임 요약 데이터 모델
class ScreenTimeSummary {
  final Duration totalScreenTime;
  final Duration backgroundTime;
  final Duration totalUsageTime;
  final List<RealAppUsageData> topApps;
  final bool hasPermission;
  
  const ScreenTimeSummary({
    required this.totalScreenTime,
    required this.backgroundTime,
    required this.totalUsageTime,
    required this.topApps,
    required this.hasPermission,
  });
  
  /// 총 스크린 타임을 포맷팅된 문자열로 반환
  String get formattedTotalScreenTime {
    final hours = totalScreenTime.inHours;
    final minutes = totalScreenTime.inMinutes % 60;
    
    if (hours > 0) {
      return '$hours시간 $minutes분';
    } else if (minutes > 0) {
      return '$minutes분';
    } else {
      return '${totalScreenTime.inSeconds}초';
    }
  }
  
  /// 백그라운드 시간을 포맷팅된 문자열로 반환
  String get formattedBackgroundTime {
    final hours = backgroundTime.inHours;
    final minutes = backgroundTime.inMinutes % 60;
    
    if (hours > 0) {
      return '$hours시간 $minutes분';
    } else if (minutes > 0) {
      return '$minutes분';
    } else {
      return '${backgroundTime.inSeconds}초';
    }
  }
  
  /// 총 사용 시간을 포맷팅된 문자열로 반환
  String get formattedTotalUsageTime {
    final hours = totalUsageTime.inHours;
    final minutes = totalUsageTime.inMinutes % 60;
    
    if (hours > 0) {
      return '$hours시간 $minutes분';
    } else if (minutes > 0) {
      return '$minutes분';
    } else {
      return '${totalUsageTime.inSeconds}초';
    }
  }
  
  /// 백그라운드 소모 비율 계산
  double get backgroundConsumptionPercent {
    if (totalUsageTime.inMilliseconds == 0) return 0.0;
    return (backgroundTime.inMilliseconds / totalUsageTime.inMilliseconds) * 100;
  }
  
  /// 백그라운드 소모 비율을 포맷팅된 문자열로 반환
  String get formattedBackgroundConsumptionPercent => 
      '${backgroundConsumptionPercent.toStringAsFixed(1)}%';
}

/// 앱 사용 통계 관리 서비스
class AppUsageManager {
  static final AppUsageManager _instance = AppUsageManager._internal();
  factory AppUsageManager() => _instance;
  AppUsageManager._internal();
  
  // 캐시된 데이터
  ScreenTimeSummary? _cachedSummary;
  DateTime? _lastCacheTime;
  static const Duration _cacheValidityDuration = Duration(minutes: 5);
  
  /// 스크린 타임 요약 데이터 가져오기
  Future<ScreenTimeSummary> getScreenTimeSummary() async {
    // 캐시된 데이터가 유효한지 확인
    if (_cachedSummary != null && 
        _lastCacheTime != null && 
        DateTime.now().difference(_lastCacheTime!) < _cacheValidityDuration) {
      return _cachedSummary!;
    }
    
    try {
      // 권한 확인
      final bool hasPermission = await AppUsageService.checkUsageStatsPermission();
      
      if (!hasPermission) {
        _cachedSummary = ScreenTimeSummary(
          totalScreenTime: Duration.zero,
          backgroundTime: Duration.zero,
          totalUsageTime: Duration.zero,
          topApps: [],
          hasPermission: false,
        );
        _lastCacheTime = DateTime.now();
        return _cachedSummary!;
      }
      
      // 앱 사용 통계 가져오기
      final List<AppUsageData> appUsageList = await AppUsageService.getTodayAppUsage();
      
      // 총 스크린 타임 계산
      final Duration totalScreenTime = await AppUsageService.getTodayScreenTime();
      
      // 상위 앱들 변환
      final List<RealAppUsageData> topApps = appUsageList
          .where((app) => app.totalTimeInForeground.inMilliseconds > 0)
          .take(5)
          .map((app) => _convertToRealAppUsageData(app, totalScreenTime))
          .toList();
      
      // 백그라운드 시간 추정 (실제로는 정확한 백그라운드 시간을 알기 어려움)
      final Duration backgroundTime = Duration.zero; // 추후 개선 필요
      
      // 총 사용 시간 (스크린 타임 + 백그라운드 시간)
      final Duration totalUsageTime = totalScreenTime + backgroundTime;
      
      _cachedSummary = ScreenTimeSummary(
        totalScreenTime: totalScreenTime,
        backgroundTime: backgroundTime,
        totalUsageTime: totalUsageTime,
        topApps: topApps,
        hasPermission: true,
      );
      
      _lastCacheTime = DateTime.now();
      return _cachedSummary!;
      
    } catch (e) {
      debugPrint('스크린 타임 요약 데이터 가져오기 실패: $e');
      
      _cachedSummary = ScreenTimeSummary(
        totalScreenTime: Duration.zero,
        backgroundTime: Duration.zero,
        totalUsageTime: Duration.zero,
        topApps: [],
        hasPermission: false,
      );
      _lastCacheTime = DateTime.now();
      return _cachedSummary!;
    }
  }
  
  /// AppUsageData를 RealAppUsageData로 변환
  RealAppUsageData _convertToRealAppUsageData(AppUsageData app, Duration totalScreenTime) {
    // 배터리 사용량 추정 (실제 배터리 사용량은 별도로 수집해야 함)
    final double batteryPercent = AppUsageService.calculateUsagePercentage(
      app.totalTimeInForeground, 
      totalScreenTime
    );
    
    // 앱별 색상 결정
    final Color color = _getAppColor(app.packageName);
    
    return RealAppUsageData(
      packageName: app.packageName,
      appName: app.appName,
      totalTimeInForeground: app.totalTimeInForeground,
      backgroundTime: Duration.zero, // 추후 개선 필요
      batteryPercent: batteryPercent,
      launchCount: app.launchCount,
      lastTimeUsed: app.lastTimeUsed,
      color: color,
    );
  }
  
  /// 앱별 색상 결정
  Color _getAppColor(String packageName) {
    // 앱 패키지명에 따른 색상 매핑
    final colorMap = {
      'com.google.android.youtube': Colors.red[400]!,
      'com.instagram.android': Colors.pink[400]!,
      'com.kakao.talk': Colors.yellow[400]!,
      'com.android.chrome': Colors.green[400]!,
      'com.spotify.music': Colors.green[600]!,
      'com.facebook.katana': Colors.blue[400]!,
      'com.twitter.android': Colors.lightBlue[400]!,
      'com.whatsapp': Colors.green[500]!,
      'com.netflix.mediaclient': Colors.red[600]!,
      'com.amazon.mShop.android.shopping': Colors.orange[400]!,
    };
    
    return colorMap[packageName] ?? Colors.grey[400]!;
  }
  
  /// 캐시 초기화
  void clearCache() {
    _cachedSummary = null;
    _lastCacheTime = null;
  }
  
  /// 권한 설정 화면 열기
  Future<void> openPermissionSettings() async {
    await AppUsageService.openUsageStatsSettings();
  }
  
  /// 권한 상태 확인
  Future<bool> checkPermission() async {
    return await AppUsageService.checkUsageStatsPermission();
  }
}
