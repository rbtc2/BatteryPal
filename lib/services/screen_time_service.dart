import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// 화면 켜짐 시간 추적 서비스
/// Android UsageStatsManager를 사용하여 화면 켜짐 시간을 추적합니다
class ScreenTimeService {
  static const MethodChannel _channel = 
      MethodChannel('com.example.batterypal/system_settings');

  /// Usage Stats 권한이 있는지 확인
  /// 
  /// Returns 권한이 있으면 true, 없으면 false
  Future<bool> hasUsageStatsPermission() async {
    try {
      debugPrint('화면 시간: Usage Stats 권한 확인 요청');
      final bool? hasPermission = await _channel.invokeMethod('hasUsageStatsPermission') as bool?;
      debugPrint('화면 시간: Usage Stats 권한 = $hasPermission');
      return hasPermission ?? false;
    } catch (e) {
      debugPrint('Usage Stats 권한 확인 실패: $e');
      return false;
    }
  }

  /// Usage Stats 설정 화면으로 이동
  /// 사용자가 수동으로 권한을 부여할 수 있는 설정 화면을 엽니다
  Future<void> openUsageStatsSettings() async {
    try {
      debugPrint('화면 시간: Usage Stats 설정 화면 열기 요청');
      await _channel.invokeMethod('openUsageStatsSettings');
      debugPrint('화면 시간: Usage Stats 설정 화면 열기 완료');
    } catch (e) {
      debugPrint('Usage Stats 설정 화면 열기 실패: $e');
    }
  }

  /// 특정 날짜의 화면 켜짐 시간 가져오기 (시간 단위)
  /// 
  /// [targetDate] 조회할 날짜 (시간은 무시됨)
  /// Returns 화면 켜짐 시간 (시간 단위), 권한이 없거나 실패하면 null
  Future<double?> getScreenOnTimeForDate(DateTime targetDate) async {
    try {
      // 날짜의 시작 시간 (00:00:00)을 밀리초로 변환
      final dateOnly = DateTime(targetDate.year, targetDate.month, targetDate.day);
      final dateMillis = dateOnly.millisecondsSinceEpoch;
      
      debugPrint('화면 시간: 화면 켜짐 시간 조회 요청 - ${dateOnly.toString().split(' ')[0]}');
      
      final int? screenOnTimeMs = await _channel.invokeMethod(
        'getScreenOnTime',
        {'dateMillis': dateMillis},
      );
      
      if (screenOnTimeMs == null || screenOnTimeMs < 0) {
        debugPrint('화면 시간: 화면 켜짐 시간 조회 실패 또는 권한 없음');
        return null;
      }
      
      // 밀리초를 시간으로 변환
      final hours = screenOnTimeMs / 1000.0 / 60.0 / 60.0;
      debugPrint('화면 시간: 화면 켜짐 시간 = ${hours.toStringAsFixed(2)}시간');
      return hours;
    } catch (e) {
      debugPrint('화면 켜짐 시간 가져오기 실패: $e');
      return null;
    }
  }
}

