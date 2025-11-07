import 'package:flutter/material.dart';
import '../services/app_usage_service.dart';
import '../services/daily_usage_stats_service.dart';

/// 사용 시간 타입 (포그라운드/백그라운드)
enum UsageType {
  /// 포그라운드 사용 시간
  foreground,
  /// 백그라운드 사용 시간
  background,
}

/// 실제 앱 사용 데이터 모델 (기존 _AppUsageData 대체)
class RealAppUsageData {
  final String packageName;
  final String appName;
  final String? appIcon; // Base64 인코딩된 앱 아이콘
  final Duration totalTimeInForeground;
  final Duration backgroundTime;
  final double batteryPercent;
  final int launchCount;
  final DateTime lastTimeUsed;
  final Color color;
  
  const RealAppUsageData({
    required this.packageName,
    required this.appName,
    this.appIcon,
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
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m';
    } else {
      return '${totalTimeInForeground.inSeconds}s';
    }
  }
  
  /// 백그라운드 시간을 포맷팅된 문자열로 반환
  String get formattedBackgroundTime {
    final hours = backgroundTime.inHours;
    final minutes = backgroundTime.inMinutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m';
    } else {
      return '${backgroundTime.inSeconds}s';
    }
  }
  
  /// 배터리 사용량을 포맷팅된 문자열로 반환
  String get formattedBatteryPercent => '${batteryPercent.toStringAsFixed(1)}%';
  
  /// 포그라운드 사용 시간 비율 계산 (전체 포그라운드 시간 대비)
  /// 
  /// [totalForegroundTime] 전체 포그라운드 시간
  double getForegroundPercent(Duration totalForegroundTime) {
    if (totalForegroundTime.inMilliseconds == 0) return 0.0;
    return (totalTimeInForeground.inMilliseconds / totalForegroundTime.inMilliseconds) * 100;
  }
  
  /// 백그라운드 사용 시간 비율 계산 (전체 백그라운드 시간 대비)
  /// 
  /// [totalBackgroundTime] 전체 백그라운드 시간
  double getBackgroundPercent(Duration totalBackgroundTime) {
    if (totalBackgroundTime.inMilliseconds == 0) return 0.0;
    return (backgroundTime.inMilliseconds / totalBackgroundTime.inMilliseconds) * 100;
  }
  
  /// 선택된 타입에 따른 비율 계산
  /// 
  /// [usageType] 사용 시간 타입 (포그라운드/백그라운드)
  /// [totalForegroundTime] 전체 포그라운드 시간
  /// [totalBackgroundTime] 전체 백그라운드 시간
  double getPercentByType(
    UsageType usageType,
    Duration totalForegroundTime,
    Duration totalBackgroundTime,
  ) {
    switch (usageType) {
      case UsageType.foreground:
        return getForegroundPercent(totalForegroundTime);
      case UsageType.background:
        return getBackgroundPercent(totalBackgroundTime);
    }
  }
  
  /// 선택된 타입에 따른 비율을 포맷팅된 문자열로 반환
  String getFormattedPercentByType(
    UsageType usageType,
    Duration totalForegroundTime,
    Duration totalBackgroundTime,
  ) {
    final percent = getPercentByType(usageType, totalForegroundTime, totalBackgroundTime);
    return '${percent.toStringAsFixed(1)}%';
  }
  
  /// 앱 사용량 데이터를 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'packageName': packageName,
      'appName': appName,
      'appIcon': appIcon,
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
      appIcon: json['appIcon'] as String?,
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
  
  /// 총 스크린 타임을 포맷팅된 문자열로 반환 (메인 표시용)
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
  
  /// 총 스크린 타임을 간소화된 형식으로 반환 (카드용)
  String get formattedTotalScreenTimeCompact {
    final hours = totalScreenTime.inHours;
    final minutes = totalScreenTime.inMinutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m';
    } else {
      return '${totalScreenTime.inSeconds}s';
    }
  }
  
  /// 백그라운드 시간을 포맷팅된 문자열로 반환 (상세 표시용)
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
  
  /// 백그라운드 시간을 간소화된 형식으로 반환 (카드용)
  String get formattedBackgroundTimeCompact {
    final hours = backgroundTime.inHours;
    final minutes = backgroundTime.inMinutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m';
    } else {
      return '${backgroundTime.inSeconds}s';
    }
  }
  
  /// 총 사용 시간을 포맷팅된 문자열로 반환 (상세 표시용)
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
  
  /// 총 사용 시간을 간소화된 형식으로 반환 (카드용)
  String get formattedTotalUsageTimeCompact {
    final hours = totalUsageTime.inHours;
    final minutes = totalUsageTime.inMinutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m';
    } else {
      return '${totalUsageTime.inSeconds}s';
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
      
      // 오늘 자정 시간 계산 (필터링 기준)
      final DateTime now = DateTime.now();
      final DateTime todayStart = DateTime(now.year, now.month, now.day);
      
      // 시스템 앱 필터링 및 중복 제거 (같은 패키지명 합산)
      final Map<String, AppUsageData> mergedApps = {};
      
      for (final app in appUsageList) {
        // 오늘 자정 이후에 사용된 앱만 처리 (이중 확인)
        if (app.lastTimeStamp.isBefore(todayStart)) {
          continue;
        }
        
        // 시스템 앱 필터링 (패키지명 또는 앱 이름 기준)
        if (_isSystemApp(app.packageName) || _isSystemAppByName(app.appName)) {
          continue;
        }
        
        // 사용 시간이 0보다 큰 앱만 처리
        if (app.totalTimeInForeground.inMilliseconds <= 0) {
          continue;
        }
        
        // 같은 패키지명이 이미 있으면 시간 합산
        if (mergedApps.containsKey(app.packageName)) {
          final existingApp = mergedApps[app.packageName]!;
          // 시간 합산
          final mergedTime = existingApp.totalTimeInForeground + app.totalTimeInForeground;
          // 더 최근의 lastTimeUsed 사용
          final latestLastUsed = existingApp.lastTimeUsed.isAfter(app.lastTimeUsed)
              ? existingApp.lastTimeUsed
              : app.lastTimeUsed;
          // 더 이른 firstTimeStamp 사용
          final earliestFirstStamp = existingApp.firstTimeStamp.isBefore(app.firstTimeStamp)
              ? existingApp.firstTimeStamp
              : app.firstTimeStamp;
          // 더 늦은 lastTimeStamp 사용
          final latestLastStamp = existingApp.lastTimeStamp.isAfter(app.lastTimeStamp)
              ? existingApp.lastTimeStamp
              : app.lastTimeStamp;
          
          mergedApps[app.packageName] = AppUsageData(
            packageName: app.packageName,
            appName: app.appName, // 앱 이름은 동일하므로 그대로 사용
            appIcon: existingApp.appIcon ?? app.appIcon, // 아이콘은 기존 것이 있으면 사용
            totalTimeInForeground: mergedTime,
            lastTimeUsed: latestLastUsed,
            launchCount: existingApp.launchCount + app.launchCount,
            firstTimeStamp: earliestFirstStamp,
            lastTimeStamp: latestLastStamp,
          );
        } else {
          // 새로운 앱이면 그대로 추가
          mergedApps[app.packageName] = app;
        }
      }
      
      // 시스템 앱을 제외한 총 스크린 타임 계산
      final Duration totalScreenTime = mergedApps.values
          .fold<Duration>(
            Duration.zero,
            (sum, app) => sum + app.totalTimeInForeground,
          );
      
      // 오늘 날짜 기준으로 계산 (자정부터 현재까지)
      // now와 todayStart는 이미 위에서 선언됨
      final Duration todayDuration = now.difference(todayStart);
      
      // 백그라운드 시간 추정 (비율 계산에 사용하기 위해 먼저 계산)
      // 방법: 각 앱의 활성 기간에서 포그라운드 시간을 빼서 백그라운드 시간 추정
      // 단, 이 방법은 완벽하지 않지만 대략적인 추정치를 제공
      Duration totalEstimatedBackgroundTime = Duration.zero;
      
      for (final app in mergedApps.values) {
        if (app.totalTimeInForeground.inMilliseconds > 0) {
          // 앱의 활성 기간 계산 (firstTimeStamp ~ lastTimeStamp)
          // 단, 오늘 날짜 범위 내에서만 계산
          final DateTime appFirstTime = app.firstTimeStamp.isBefore(todayStart) 
              ? todayStart 
              : app.firstTimeStamp;
          final DateTime appLastTime = app.lastTimeStamp.isAfter(now) 
              ? now 
              : app.lastTimeStamp;
          
          final Duration appActiveDuration = appLastTime.difference(appFirstTime);
          
          // 활성 기간에서 포그라운드 시간을 빼면 대략적인 백그라운드 시간
          // 단, 포그라운드 시간이 활성 기간보다 길 수 있으므로 최소값은 0
          final Duration appBackgroundTime = appActiveDuration > app.totalTimeInForeground
              ? appActiveDuration - app.totalTimeInForeground
              : Duration.zero;
          
          // 백그라운드 시간이 너무 길면 (예: 24시간 이상) 제한
          // 실제로는 백그라운드 시간이 포그라운드 시간의 일정 비율을 넘지 않도록 제한
          final Duration maxReasonableBackground = app.totalTimeInForeground * 2; // 최대 포그라운드 시간의 2배
          final Duration finalAppBackgroundTime = appBackgroundTime > maxReasonableBackground
              ? maxReasonableBackground
              : appBackgroundTime;
          
          totalEstimatedBackgroundTime += finalAppBackgroundTime;
        }
      }
      
      // 백그라운드 시간이 오늘 하루 시간을 넘지 않도록 제한
      final Duration backgroundTime = totalEstimatedBackgroundTime > todayDuration
          ? todayDuration
          : totalEstimatedBackgroundTime;
      
      // 합산된 앱들을 시간 순으로 정렬하고 상위 5개 선택
      // 백그라운드 시간을 포함하여 비율 계산
      final List<RealAppUsageData> topApps = mergedApps.values
          .toList()
          .map((app) => _convertToRealAppUsageData(app, totalScreenTime, backgroundTime))
          .toList()
        ..sort((a, b) => b.totalTimeInForeground.compareTo(a.totalTimeInForeground));
      
      // 상위 5개만 선택
      final top5Apps = topApps.take(5).toList();
      
      // 총 사용 시간 (스크린 타임 + 백그라운드 시간)
      // 단, 오늘 하루 시간을 넘지 않도록 제한
      final Duration totalUsageTime = (totalScreenTime + backgroundTime) > todayDuration
          ? todayDuration
          : totalScreenTime + backgroundTime;
      
      _cachedSummary = ScreenTimeSummary(
        totalScreenTime: totalScreenTime,
        backgroundTime: backgroundTime,
        totalUsageTime: totalUsageTime,
        topApps: top5Apps,
        hasPermission: true,
      );
      
      _lastCacheTime = DateTime.now();
      
      // 어제 데이터 저장 체크 (백그라운드에서 실행)
      DailyUsageStatsService.checkAndSaveYesterday(_cachedSummary);
      
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
  RealAppUsageData _convertToRealAppUsageData(AppUsageData app, Duration totalScreenTime, Duration totalBackgroundTime) {
    // 배터리 사용량 추정
    // 주의: 이것은 스크린 타임 비율이지 실제 배터리 소모 비율이 아닙니다.
    // 실제 배터리 소모는 CPU 사용량, 네트워크 사용량, 화면 밝기 등에 따라 달라집니다.
    // 
    // 현재는 스크린 타임 비율을 사용합니다.
    // 배터리 소모 비율 = (포그라운드 시간 / 전체 스크린 타임) * 100
    
    // 앱별 백그라운드 시간 추정
    final DateTime now = DateTime.now();
    final DateTime todayStart = DateTime(now.year, now.month, now.day);
    
    final DateTime appFirstTime = app.firstTimeStamp.isBefore(todayStart) 
        ? todayStart 
        : app.firstTimeStamp;
    final DateTime appLastTime = app.lastTimeStamp.isAfter(now) 
        ? now 
        : app.lastTimeStamp;
    
    final Duration appActiveDuration = appLastTime.difference(appFirstTime);
    
    // 활성 기간에서 포그라운드 시간을 빼서 백그라운드 시간 추정
    final Duration appBackgroundTime = appActiveDuration > app.totalTimeInForeground
        ? appActiveDuration - app.totalTimeInForeground
        : Duration.zero;
    
    // 백그라운드 시간이 너무 길면 제한 (포그라운드 시간의 2배를 넘지 않도록)
    final Duration maxReasonableBackground = app.totalTimeInForeground * 2;
    final Duration finalBackgroundTime = appBackgroundTime > maxReasonableBackground
        ? maxReasonableBackground
        : appBackgroundTime;
    
    // 사용 시간 비율 계산 (스크린 타임 + 백그라운드 시간 고려)
    // 실제 배터리 소모를 정확히 측정하려면 Android의 BatteryStats API가 필요하지만,
    // 일반 앱에서는 사용할 수 없으므로 사용 시간 비율을 사용합니다.
    // 
    // 백그라운드 시간은 포그라운드 시간보다 덜 소모하므로 0.3배 가중치 적용
    // 앱의 총 사용 시간 = 포그라운드 시간 + (앱의 백그라운드 시간 × 0.3)
    final double effectiveAppUsageTime = app.totalTimeInForeground.inMilliseconds.toDouble() + 
        (finalBackgroundTime.inMilliseconds.toDouble() * 0.3);
    
    // 시스템 앱을 제외한 전체 총 사용 시간 계산 (포그라운드 + 백그라운드 가중치)
    // totalScreenTime은 이미 시스템 앱이 제외된 포그라운드 시간의 합
    // totalBackgroundTime은 모든 앱의 백그라운드 시간 합
    // 전체 총 사용 시간 = 전체 포그라운드 시간 + (전체 백그라운드 시간 × 0.3)
    double batteryPercent = 0.0;
    final double totalEffectiveUsageTime = totalScreenTime.inMilliseconds.toDouble() + 
        (totalBackgroundTime.inMilliseconds.toDouble() * 0.3);
    
    if (totalEffectiveUsageTime > 0) {
      batteryPercent = (effectiveAppUsageTime / totalEffectiveUsageTime) * 100;
    } else if (totalScreenTime.inMilliseconds > 0) {
      // 폴백: 포그라운드 시간만 사용 (백그라운드 시간이 없는 경우)
      batteryPercent = (app.totalTimeInForeground.inMilliseconds / totalScreenTime.inMilliseconds) * 100;
    }
    
    // 앱별 색상 결정
    final Color color = _getAppColor(app.packageName);
    
    return RealAppUsageData(
      packageName: app.packageName,
      appName: app.appName,
      appIcon: app.appIcon,
      totalTimeInForeground: app.totalTimeInForeground,
      backgroundTime: finalBackgroundTime,
      batteryPercent: batteryPercent,
      launchCount: app.launchCount,
      lastTimeUsed: app.lastTimeUsed,
      color: color,
    );
  }
  
  /// 시스템 앱인지 확인 (패키지명 기준)
  bool _isSystemApp(String packageName) {
    // 시스템 앱 패키지명 패턴
    final systemAppPatterns = [
      'com.android.',
      'com.google.android.apps.',
      'com.samsung.android.',
      'android',
      'com.sec.android.',
      'com.sec.',
      'com.samsung.',
      'com.microsoft.exchange', // Microsoft Exchange
      'com.android.email', // Android Email
      'com.samsung.android.email', // Samsung Email
    ];
    
    // 정확히 "android"인 경우도 시스템 앱으로 간주
    if (packageName == 'android') {
      return true;
    }
    
    // 패턴 매칭
    for (final pattern in systemAppPatterns) {
      if (packageName.startsWith(pattern)) {
        return true;
      }
    }
    
    return false;
  }
  
  /// 시스템 앱인지 확인 (앱 이름 기준)
  /// 앱 이름이 모호하거나 시스템 앱을 나타내는 경우 필터링
  bool _isSystemAppByName(String appName) {
    // 모호한 시스템 앱 이름들
    final ambiguousSystemNames = [
      'android',
      'Android',
      'ANDROID',
      '시스템',
      'System',
      'system',
      '시스템 UI',
      'System UI',
      '설정',
      'Settings',
      'settings',
      'exchange', // Exchange 서비스 (이메일 동기화)
      'Exchange',
      'EXCHANGE',
    ];
    
    // 정확히 일치하는 경우
    if (ambiguousSystemNames.contains(appName)) {
      return true;
    }
    
    // 소문자로 변환하여 비교
    final lowerName = appName.toLowerCase();
    if (lowerName == 'android' || 
        lowerName == 'system' || 
        lowerName == 'settings' ||
        lowerName == 'exchange') {
      return true;
    }
    
    return false;
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
