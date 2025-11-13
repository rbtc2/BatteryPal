import 'package:flutter/material.dart';
import '../../models/models.dart';

/// 배터리 정보 검증을 담당하는 클래스
/// 
/// 배터리 정보의 유효성을 검증하고, 업데이트 간격을 관리합니다.
class BatteryInfoValidator {
  /// 배터리 정보 검증을 위한 최소 업데이트 간격 (밀리초)
  static const int minUpdateInterval = 1000; // 1초

  /// 마지막 업데이트 시간
  DateTime? _lastUpdateTime;

  /// 배터리 정보가 유효한지 검증
  /// 
  /// [info]: 검증할 배터리 정보
  /// 
  /// Returns: 유효한 경우 true, 그렇지 않으면 false
  bool isValidBatteryInfo(BatteryInfo info) {
    // 기본 범위 검증
    if (info.level < 0 || info.level > 100) {
      debugPrint('배터리 레벨이 유효하지 않음: ${info.level}%');
      return false;
    }
    
    // 온도 검증 (일반적인 범위)
    if (info.temperature != -1.0 && (info.temperature < -50 || info.temperature > 100)) {
      debugPrint('배터리 온도가 유효하지 않음: ${info.temperature}°C');
      return false;
    }
    
    // 전압 검증 (일반적인 범위)
    if (info.voltage != -1 && (info.voltage < 3000 || info.voltage > 5000)) {
      debugPrint('배터리 전압이 유효하지 않음: ${info.voltage}mV');
      return false;
    }
    
    // 충전 전류 검증 (일반적인 범위)
    if (info.chargingCurrent != -1 && info.chargingCurrent.abs() > 10000) {
      debugPrint('충전 전류가 유효하지 않음: ${info.chargingCurrent}mA');
      return false;
    }
    
    return true;
  }

  /// 업데이트 간격 검증
  /// 
  /// 최소 업데이트 간격이 지났는지 확인합니다.
  /// 
  /// Returns: 업데이트 가능한 경우 true, 그렇지 않으면 false
  bool shouldUpdate() {
    if (_lastUpdateTime == null) return true;
    
    final now = DateTime.now();
    final timeDiff = now.difference(_lastUpdateTime!).inMilliseconds;
    
    return timeDiff >= minUpdateInterval;
  }

  /// 마지막 업데이트 시간 설정
  /// 
  /// [time]: 업데이트 시간
  void setLastUpdateTime(DateTime time) {
    _lastUpdateTime = time;
  }

  /// 마지막 업데이트 시간 초기화
  void resetLastUpdateTime() {
    _lastUpdateTime = null;
  }

  /// 마지막 업데이트 시간 가져오기
  DateTime? get lastUpdateTime => _lastUpdateTime;
}

