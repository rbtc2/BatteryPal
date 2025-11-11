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
}

