import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// Android 네이티브 배터리 정보를 가져오는 서비스
class NativeBatteryService {
  static const MethodChannel _channel = MethodChannel('com.example.batterypal/battery');

  /// 배터리 온도 가져오기 (섭씨)
  static Future<double> getBatteryTemperature() async {
    try {
      final double temperature = await _channel.invokeMethod('getBatteryTemperature');
      debugPrint('네이티브 배터리 온도: ${temperature.toStringAsFixed(1)}°C');
      return temperature;
    } catch (e) {
      debugPrint('배터리 온도 가져오기 실패: $e');
      return -1.0;
    }
  }

  /// 배터리 전압 가져오기 (mV)
  static Future<int> getBatteryVoltage() async {
    try {
      final int voltage = await _channel.invokeMethod('getBatteryVoltage');
      debugPrint('네이티브 배터리 전압: $voltage mV');
      return voltage;
    } catch (e) {
      debugPrint('배터리 전압 가져오기 실패: $e');
      return -1;
    }
  }

  /// 배터리 용량 가져오기
  static Future<int> getBatteryCapacity() async {
    try {
      final int capacity = await _channel.invokeMethod('getBatteryCapacity');
      debugPrint('네이티브 배터리 용량: $capacity');
      return capacity;
    } catch (e) {
      debugPrint('배터리 용량 가져오기 실패: $e');
      return -1;
    }
  }

  /// 배터리 건강도 가져오기
  static Future<int> getBatteryHealth() async {
    try {
      final int health = await _channel.invokeMethod('getBatteryHealth');
      debugPrint('네이티브 배터리 건강도: $health');
      return health;
    } catch (e) {
      debugPrint('배터리 건강도 가져오기 실패: $e');
      return -1;
    }
  }
}
