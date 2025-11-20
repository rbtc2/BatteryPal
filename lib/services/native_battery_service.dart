import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// Android 네이티브 배터리 정보를 가져오는 서비스
class NativeBatteryService {
  static const MethodChannel _channel = MethodChannel('com.example.batterypal/battery');
  
  /// 배터리 상태 변화 콜백 함수
  static Function(Map<String, dynamic>)? _onBatteryStateChanged;

  /// 배터리 상태 변화 실시간 감지 초기화
  static void initializeBatteryStateListener(Function(Map<String, dynamic>) onBatteryStateChanged) {
    _onBatteryStateChanged = onBatteryStateChanged;
    
    // 네이티브에서 오는 배터리 상태 변화 이벤트 처리
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onBatteryStateChanged') {
        final chargingInfo = Map<String, dynamic>.from(call.arguments);
        debugPrint('네이티브에서 배터리 상태 변화 감지: $chargingInfo');
        _onBatteryStateChanged?.call(chargingInfo);
      }
    });
    
    debugPrint('네이티브 배터리 상태 변화 리스너 초기화 완료');
  }

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

  /// 충전 전류만 빠르게 가져오기 (실시간 모니터링용)
  static Future<int> getChargingCurrentOnly() async {
    try {
      debugPrint('네이티브 충전 전류만 요청...');
      final int chargingCurrent = await _channel.invokeMethod('getChargingCurrentOnly');
      debugPrint('네이티브 충전 전류만 응답: ${chargingCurrent}mA');
      return chargingCurrent;
    } catch (e) {
      debugPrint('충전 전류만 가져오기 실패: $e');
      return -1;
    }
  }

  /// 충전 세션 정보 가져오기 (SharedPreferences에서 읽기)
  /// BatteryStateReceiver에서 저장한 충전 세션 정보를 읽어옵니다
  static Future<ChargingSessionInfo?> getChargingSessionInfo() async {
    try {
      debugPrint('네이티브 충전 세션 정보 요청...');
      final Map<dynamic, dynamic> sessionInfo = await _channel.invokeMethod('getChargingSessionInfo');
      debugPrint('네이티브 충전 세션 정보 응답: $sessionInfo');
      
      final startTime = sessionInfo['startTime'] as int?;
      final endTime = sessionInfo['endTime'] as int?;
      final isChargingActive = sessionInfo['isChargingActive'] as bool? ?? false;
      final startBatteryLevel = sessionInfo['startBatteryLevel'] as double?;
      final endBatteryLevel = sessionInfo['endBatteryLevel'] as double?;
      final chargingType = sessionInfo['chargingType'] as String?;
      
      if (startTime == null && endTime == null && !isChargingActive) {
        // 세션 정보가 없으면 null 반환
        return null;
      }
      
      return ChargingSessionInfo(
        startTime: startTime != null ? DateTime.fromMillisecondsSinceEpoch(startTime) : null,
        endTime: endTime != null ? DateTime.fromMillisecondsSinceEpoch(endTime) : null,
        isChargingActive: isChargingActive,
        startBatteryLevel: startBatteryLevel,
        endBatteryLevel: endBatteryLevel,
        chargingType: chargingType,
      );
    } catch (e) {
      debugPrint('충전 세션 정보 가져오기 실패: $e');
      return null;
    }
  }

  /// 충전 세션 정보 저장 (SharedPreferences에 쓰기)
  /// 앱에서 감지한 정확한 세션 정보를 네이티브에 저장하여 백그라운드 복구 시 사용
  static Future<void> saveChargingSessionInfo(ChargingSessionInfo info) async {
    try {
      debugPrint('네이티브 충전 세션 정보 저장 요청: $info');
      
      final Map<String, dynamic> sessionInfo = {
        'startTime': info.startTime?.millisecondsSinceEpoch,
        'endTime': info.endTime?.millisecondsSinceEpoch,
        'isChargingActive': info.isChargingActive,
        'startBatteryLevel': info.startBatteryLevel,
        'endBatteryLevel': info.endBatteryLevel,
        'chargingType': info.chargingType,
      };
      
      await _channel.invokeMethod('saveChargingSessionInfo', sessionInfo);
      debugPrint('네이티브 충전 세션 정보 저장 완료');
    } catch (e) {
      debugPrint('충전 세션 정보 저장 실패: $e');
    }
  }
}

/// 충전 세션 정보 모델
class ChargingSessionInfo {
  final DateTime? startTime;
  final DateTime? endTime;
  final bool isChargingActive;
  final double? startBatteryLevel;
  final double? endBatteryLevel;
  final String? chargingType;

  ChargingSessionInfo({
    this.startTime,
    this.endTime,
    required this.isChargingActive,
    this.startBatteryLevel,
    this.endBatteryLevel,
    this.chargingType,
  });

  @override
  String toString() {
    return 'ChargingSessionInfo('
        'startTime: $startTime, '
        'endTime: $endTime, '
        'isChargingActive: $isChargingActive, '
        'startBatteryLevel: $startBatteryLevel, '
        'endBatteryLevel: $endBatteryLevel, '
        'chargingType: $chargingType)';
  }
}
