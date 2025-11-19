import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// 시스템 설정을 읽는 서비스
/// Android/iOS 네이티브 코드를 통해 시스템 설정 값을 읽어옵니다
class SystemSettingsService {
  static const MethodChannel _channel = 
      MethodChannel('com.example.batterypal/system_settings');

  /// 화면 밝기 읽기 (0-100)
  /// 
  /// Android: Settings.System.SCREEN_BRIGHTNESS 사용
  /// iOS: UIScreen.main.brightness 사용
  Future<int?> getScreenBrightness() async {
    try {
      debugPrint('시스템 설정: 화면 밝기 읽기 요청');
      final int brightness = await _channel.invokeMethod('getScreenBrightness');
      debugPrint('시스템 설정: 화면 밝기 = $brightness%');
      return brightness;
    } catch (e) {
      debugPrint('화면 밝기 읽기 실패: $e');
      return null;
    }
  }

  /// 위치 서비스 상태 읽기
  /// 
  /// 반환값: "켜짐", "꺼짐", "고정밀도", "절약 모드" 등
  Future<String?> getLocationServiceStatus() async {
    try {
      debugPrint('시스템 설정: 위치 서비스 상태 읽기 요청');
      final String status = await _channel.invokeMethod('getLocationServiceStatus');
      debugPrint('시스템 설정: 위치 서비스 상태 = $status');
      return status;
    } catch (e) {
      debugPrint('위치 서비스 상태 읽기 실패: $e');
      return null;
    }
  }

  /// 네트워크 연결 타입 읽기
  /// 
  /// 반환값: "Wi-Fi", "5G", "4G", "3G", "없음" 등
  Future<String?> getNetworkConnectionType() async {
    try {
      debugPrint('시스템 설정: 네트워크 연결 타입 읽기 요청');
      final String type = await _channel.invokeMethod('getNetworkConnectionType');
      debugPrint('시스템 설정: 네트워크 연결 타입 = $type');
      return type;
    } catch (e) {
      debugPrint('네트워크 연결 타입 읽기 실패: $e');
      return null;
    }
  }

  /// 화면 시간 초과 읽기 (초 단위)
  /// 
  /// 반환값: 초 단위 (예: 30, 60, 120 등)
  Future<int?> getScreenTimeout() async {
    try {
      debugPrint('시스템 설정: 화면 시간 초과 읽기 요청');
      final int timeout = await _channel.invokeMethod('getScreenTimeout');
      debugPrint('시스템 설정: 화면 시간 초과 = $timeout초');
      return timeout;
    } catch (e) {
      debugPrint('화면 시간 초과 읽기 실패: $e');
      return null;
    }
  }

  /// 배터리 세이버 모드 상태 읽기
  /// 
  /// 반환값: true (켜짐), false (꺼짐)
  Future<bool?> isBatterySaverEnabled() async {
    try {
      debugPrint('시스템 설정: 배터리 세이버 모드 상태 읽기 요청');
      final bool enabled = await _channel.invokeMethod('isBatterySaverEnabled');
      debugPrint('시스템 설정: 배터리 세이버 모드 = $enabled');
      return enabled;
    } catch (e) {
      debugPrint('배터리 세이버 모드 상태 읽기 실패: $e');
      return null;
    }
  }

  /// 동기화 상태 읽기
  /// 
  /// 반환값: "켜짐", "꺼짐", "자동 동기화 켜짐" 등
  Future<String?> getSyncStatus() async {
    try {
      debugPrint('시스템 설정: 동기화 상태 읽기 요청');
      final String status = await _channel.invokeMethod('getSyncStatus');
      debugPrint('시스템 설정: 동기화 상태 = $status');
      return status;
    } catch (e) {
      debugPrint('동기화 상태 읽기 실패: $e');
      return null;
    }
  }

  /// 화면 밝기 설정 (0-100)
  /// 
  /// [brightness] 0-100 범위의 밝기 값
  /// Returns 설정 성공 여부
  Future<bool> setScreenBrightness(int brightness) async {
    try {
      debugPrint('시스템 설정: 화면 밝기 설정 요청 - $brightness%');
      final bool success = await _channel.invokeMethod(
        'setScreenBrightness',
        {'brightness': brightness},
      );
      debugPrint('시스템 설정: 화면 밝기 설정 결과 = $success');
      return success;
    } catch (e) {
      debugPrint('화면 밝기 설정 실패: $e');
      return false;
    }
  }

  /// 시스템 설정 변경 권한 확인
  /// 
  /// Returns 권한이 있는지 여부
  Future<bool> canWriteSettings() async {
    try {
      debugPrint('시스템 설정: 권한 확인 요청');
      final bool canWrite = await _channel.invokeMethod('canWriteSettings');
      debugPrint('시스템 설정: 권한 확인 결과 = $canWrite');
      return canWrite;
    } catch (e) {
      debugPrint('권한 확인 실패: $e');
      return false;
    }
  }

  /// 시스템 설정 변경 권한 설정 화면으로 이동
  /// WRITE_SETTINGS 권한을 허용하기 위한 특별한 설정 화면으로 이동
  Future<void> openWriteSettingsPermission() async {
    try {
      debugPrint('시스템 설정: 권한 설정 화면 열기 요청');
      await _channel.invokeMethod('openWriteSettingsPermission');
      debugPrint('시스템 설정: 권한 설정 화면 열기 완료');
    } catch (e) {
      debugPrint('권한 설정 화면 열기 실패: $e');
    }
  }

  /// Phase 3: 배터리 최적화 예외 여부 확인
  /// 
  /// Returns: 배터리 최적화에서 제외되었으면 true, 그렇지 않으면 false
  Future<bool?> isIgnoringBatteryOptimizations() async {
    try {
      debugPrint('시스템 설정: 배터리 최적화 예외 여부 확인 요청');
      final bool isIgnoring = await _channel.invokeMethod('isIgnoringBatteryOptimizations');
      debugPrint('시스템 설정: 배터리 최적화 예외 여부 = $isIgnoring');
      return isIgnoring;
    } catch (e) {
      debugPrint('배터리 최적화 예외 여부 확인 실패: $e');
      return null;
    }
  }

  /// Phase 3: 배터리 최적화 설정 화면으로 이동
  /// 
  /// 사용자가 앱을 배터리 최적화에서 제외할 수 있도록 설정 화면을 엽니다.
  Future<void> openBatteryOptimizationSettings() async {
    try {
      debugPrint('시스템 설정: 배터리 최적화 설정 화면 열기 요청');
      await _channel.invokeMethod('openBatteryOptimizationSettings');
      debugPrint('시스템 설정: 배터리 최적화 설정 화면 열기 완료');
    } catch (e) {
      debugPrint('배터리 최적화 설정 화면 열기 실패: $e');
    }
  }

  /// 개발자 모드: 네이티브에서 개발자 모드 충전 테스트 활성화 여부 확인
  /// 
  /// Returns: 네이티브에서 읽은 값 (Flutter와 동기화 확인용)
  Future<bool?> getDeveloperModeChargingTestEnabled() async {
    try {
      debugPrint('시스템 설정: 개발자 모드 충전 테스트 활성화 여부 확인 요청');
      final bool? isEnabled = await _channel.invokeMethod('getDeveloperModeChargingTestEnabled');
      debugPrint('시스템 설정: 개발자 모드 충전 테스트 활성화 여부 (네이티브) = $isEnabled');
      return isEnabled;
    } catch (e) {
      debugPrint('개발자 모드 충전 테스트 활성화 여부 확인 실패: $e');
      return null;
    }
  }

  /// 개발자 모드: Flutter SharedPreferences의 모든 값 가져오기 (디버깅용)
  /// 
  /// Returns: 모든 SharedPreferences 키-값 쌍
  Future<Map<String, dynamic>?> getAllFlutterSharedPreferences() async {
    try {
      debugPrint('시스템 설정: Flutter SharedPreferences 전체 읽기 요청');
      final Map<dynamic, dynamic>? allPrefs = await _channel.invokeMethod('getAllFlutterSharedPreferences');
      if (allPrefs != null) {
        final result = Map<String, dynamic>.from(allPrefs);
        debugPrint('시스템 설정: Flutter SharedPreferences 읽기 완료 - ${result.length}개 키');
        return result;
      }
      return null;
    } catch (e) {
      debugPrint('Flutter SharedPreferences 읽기 실패: $e');
      return null;
    }
  }

  /// 개발자 모드: 마지막 충전 이벤트 시간 가져오기 (진단용)
  /// 
  /// Returns: 마지막 충전 이벤트 정보 (time, type, formatted)
  Future<Map<String, dynamic>?> getLastChargingEventTime() async {
    try {
      debugPrint('시스템 설정: 마지막 충전 이벤트 시간 요청');
      final Map<dynamic, dynamic>? eventInfo = await _channel.invokeMethod('getLastChargingEventTime');
      if (eventInfo != null) {
        final result = Map<String, dynamic>.from(eventInfo);
        debugPrint('시스템 설정: 마지막 충전 이벤트 시간 = ${result['formatted']}');
        return result;
      }
      return null;
    } catch (e) {
      debugPrint('마지막 충전 이벤트 시간 읽기 실패: $e');
      return null;
    }
  }

  /// 개발자 모드: BatteryStateReceiver 등록 확인 (진단용)
  /// 
  /// Returns: AndroidManifest에 리시버가 등록되어 있는지 여부
  Future<bool?> checkBatteryStateReceiverRegistered() async {
    try {
      debugPrint('시스템 설정: BatteryStateReceiver 등록 확인 요청');
      final bool? isRegistered = await _channel.invokeMethod('checkBatteryStateReceiverRegistered');
      debugPrint('시스템 설정: BatteryStateReceiver 등록 여부 = $isRegistered');
      return isRegistered;
    } catch (e) {
      debugPrint('BatteryStateReceiver 등록 확인 실패: $e');
      return null;
    }
  }

  /// 개발자 모드: BatteryPal 관련 로그 가져오기 (logcat에서)
  /// 
  /// Returns: 최근 로그 목록
  Future<List<String>?> getBatteryPalLogs() async {
    try {
      debugPrint('시스템 설정: BatteryPal 로그 읽기 요청');
      final List<dynamic>? logs = await _channel.invokeMethod('getBatteryPalLogs');
      if (logs != null) {
        final result = logs.map((e) => e.toString()).toList();
        debugPrint('시스템 설정: BatteryPal 로그 읽기 완료 - ${result.length}줄');
        return result;
      }
      return null;
    } catch (e) {
      debugPrint('BatteryPal 로그 읽기 실패: $e');
      return null;
    }
  }
}

