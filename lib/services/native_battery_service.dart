import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// Android 네이티브 배터리 정보를 가져오는 서비스
class NativeBatteryService {
  static const MethodChannel _channel = MethodChannel('com.example.batterypal/battery');

  /// 배터리 온도 가져오기 (섭씨)
  static Future<double> getBatteryTemperature() async {
    try {
      debugPrint('네이티브 배터리 온도 요청...');
      final double temperature = await _channel.invokeMethod('getBatteryTemperature');
      debugPrint('네이티브 배터리 온도 응답: ${temperature.toStringAsFixed(1)}°C');
      return temperature;
    } catch (e) {
      debugPrint('배터리 온도 가져오기 실패: $e');
      return -1.0;
    }
  }

  /// 배터리 전압 가져오기 (mV)
  static Future<int> getBatteryVoltage() async {
    try {
      debugPrint('네이티브 배터리 전압 요청...');
      final int voltage = await _channel.invokeMethod('getBatteryVoltage');
      debugPrint('네이티브 배터리 전압 응답: $voltage mV');
      return voltage;
    } catch (e) {
      debugPrint('배터리 전압 가져오기 실패: $e');
      return -1;
    }
  }

  /// 배터리 용량 가져오기
  static Future<int> getBatteryCapacity() async {
    try {
      debugPrint('네이티브 배터리 용량 요청...');
      final int capacity = await _channel.invokeMethod('getBatteryCapacity');
      debugPrint('네이티브 배터리 용량 응답: $capacity mAh');
      return capacity;
    } catch (e) {
      debugPrint('배터리 용량 가져오기 실패: $e');
      return -1;
    }
  }

  /// 배터리 건강도 가져오기
  static Future<int> getBatteryHealth() async {
    try {
      debugPrint('네이티브 배터리 건강도 요청...');
      final int health = await _channel.invokeMethod('getBatteryHealth');
      debugPrint('네이티브 배터리 건강도 응답: $health');
      return health;
    } catch (e) {
      debugPrint('배터리 건강도 가져오기 실패: $e');
      return -1;
    }
  }

  /// 배터리 레벨 가져오기 (더 정확한 소수점 포함)
  static Future<double> getBatteryLevel() async {
    try {
      debugPrint('네이티브 배터리 레벨 요청...');
      final double level = await _channel.invokeMethod('getBatteryLevel');
      debugPrint('네이티브 배터리 레벨 응답: ${level.toStringAsFixed(2)}%');
      return level;
    } catch (e) {
      debugPrint('배터리 레벨 가져오기 실패: $e');
      return -1.0;
    }
  }

  /// 충전 정보 가져오기
  static Future<Map<String, dynamic>> getChargingInfo() async {
    try {
      debugPrint('네이티브 충전 정보 요청...');
      final Map<dynamic, dynamic> chargingInfo = await _channel.invokeMethod('getChargingInfo');
      debugPrint('네이티브 충전 정보 응답: $chargingInfo');
      return Map<String, dynamic>.from(chargingInfo);
    } catch (e) {
      debugPrint('충전 정보 가져오기 실패: $e');
      return {
        'chargingType': 'Unknown',
        'chargingCurrent': -1,
        'currentNow': -1,
        'currentAverage': -1,
        'isCharging': false,
      };
    }
  }
}
