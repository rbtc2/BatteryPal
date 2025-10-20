import 'dart:async';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/material.dart';
import 'native_battery_service.dart';
import '../models/app_models.dart';

/// 배터리 정보를 관리하는 서비스 클래스
class BatteryService {
  static final BatteryService _instance = BatteryService._internal();
  factory BatteryService() => _instance;
  BatteryService._internal();

  final Battery _battery = Battery();
  StreamSubscription<BatteryState>? _batteryStateSubscription;
  
  // 배터리 정보 스트림
  StreamController<BatteryInfo>? _batteryInfoController;
  
  Stream<BatteryInfo> get batteryInfoStream {
    if (_batteryInfoController == null || _batteryInfoController!.isClosed) {
      _batteryInfoController = StreamController<BatteryInfo>.broadcast();
    }
    return _batteryInfoController!.stream;
  }
  
  /// 배터리 정보 모델
  BatteryInfo? _currentBatteryInfo;
  BatteryInfo? get currentBatteryInfo => _currentBatteryInfo;
  
  /// 서비스가 dispose되었는지 확인하는 플래그
  bool _isDisposed = false;

  /// 안전하게 스트림에 이벤트 추가
  void _safeAddEvent(BatteryInfo batteryInfo) {
    if (!_isDisposed && _batteryInfoController != null && !_batteryInfoController!.isClosed) {
      try {
        _batteryInfoController!.add(batteryInfo);
      } catch (e) {
        debugPrint('스트림에 이벤트 추가 실패: $e');
      }
    } else {
      debugPrint('스트림이 닫혔거나 서비스가 dispose됨, 이벤트 추가 건너뜀');
    }
  }

  /// 배터리 모니터링 시작
  Future<void> startMonitoring() async {
    if (_isDisposed) {
      debugPrint('서비스가 이미 dispose됨, 모니터링 시작 건너뜀');
      return;
    }
    
    try {
      // 초기 배터리 정보 가져오기
      await _updateBatteryInfo();
      
      // 배터리 상태 변화 감지
      _batteryStateSubscription = _battery.onBatteryStateChanged.listen(
        (BatteryState state) async {
          if (!_isDisposed) {
            await _updateBatteryInfo();
          }
        },
      );
    } catch (e) {
      debugPrint('배터리 모니터링 시작 실패: $e');
    }
  }

  /// 배터리 모니터링 중지
  void stopMonitoring() {
    _batteryStateSubscription?.cancel();
    _batteryStateSubscription = null;
  }

  /// 배터리 정보 업데이트
  Future<void> _updateBatteryInfo() async {
    if (_isDisposed) {
      debugPrint('서비스가 이미 dispose됨, 배터리 정보 업데이트 건너뜀');
      return;
    }
    
    try {
      debugPrint('배터리 정보 업데이트 시작...');
      
      // 기본 배터리 정보 먼저 가져오기 (안정적)
      final batteryLevel = await _battery.batteryLevel;
      final batteryState = await _battery.batteryState;
      debugPrint('기본 배터리 레벨: $batteryLevel%, 상태: $batteryState');
      
      // 네이티브에서 더 정확한 배터리 레벨 가져오기 (선택적)
      double preciseLevel = batteryLevel.toDouble();
      try {
        final nativeLevel = await NativeBatteryService.getBatteryLevel();
        debugPrint('네이티브 배터리 레벨: $nativeLevel');
        
        if (nativeLevel >= 0) {
          preciseLevel = nativeLevel;
          debugPrint('네이티브 레벨 사용: $preciseLevel%');
        } else {
          debugPrint('네이티브 레벨 실패, 기본 플러그인 레벨 사용: $preciseLevel%');
        }
      } catch (nativeError) {
        debugPrint('네이티브 레벨 가져오기 실패: $nativeError');
        debugPrint('기본 플러그인 레벨 사용: $preciseLevel%');
      }
      
      // 네이티브 배터리 정보 가져오기 (각각 독립적으로 처리, 실패해도 계속 진행)
      debugPrint('네이티브 배터리 정보 수집 시작...');
      
      double temperature = -1.0;
      int voltage = -1;
      int capacity = -1;
      int health = -1;
      Map<String, dynamic> chargingInfo = {
        'chargingType': 'Unknown',
        'chargingCurrent': -1,
        'isCharging': batteryState == BatteryState.charging, // 기본 플러그인 정보 사용
      };
      
      // 온도 정보 (선택적)
      try {
        temperature = await NativeBatteryService.getBatteryTemperature();
        debugPrint('네이티브 온도: $temperature°C');
      } catch (e) {
        debugPrint('온도 가져오기 실패: $e');
      }
      
      // 전압 정보 (선택적)
      try {
        voltage = await NativeBatteryService.getBatteryVoltage();
        debugPrint('네이티브 전압: $voltage mV');
      } catch (e) {
        debugPrint('전압 가져오기 실패: $e');
      }
      
      // 용량 정보 (선택적)
      try {
        capacity = await NativeBatteryService.getBatteryCapacity();
        debugPrint('네이티브 용량: $capacity mAh');
      } catch (e) {
        debugPrint('용량 가져오기 실패: $e');
      }
      
      // 건강도 정보 (선택적)
      try {
        health = await NativeBatteryService.getBatteryHealth();
        debugPrint('네이티브 건강도: $health');
      } catch (e) {
        debugPrint('건강도 가져오기 실패: $e');
      }
      
      // 충전 정보 (선택적)
      try {
        chargingInfo = await NativeBatteryService.getChargingInfo();
        debugPrint('네이티브 충전 정보: $chargingInfo');
      } catch (e) {
        debugPrint('충전 정보 가져오기 실패: $e');
        // 기본 플러그인 정보로 폴백
        chargingInfo = {
          'chargingType': 'Unknown',
          'chargingCurrent': -1,
          'isCharging': batteryState == BatteryState.charging,
        };
      }
      
      _currentBatteryInfo = BatteryInfo(
        level: preciseLevel,
        state: batteryState,
        timestamp: DateTime.now(),
        temperature: temperature,
        voltage: voltage,
        capacity: capacity,
        health: health,
        chargingType: chargingInfo['chargingType'] ?? 'Unknown',
        chargingCurrent: chargingInfo['chargingCurrent'] ?? -1,
        isCharging: chargingInfo['isCharging'] ?? (batteryState == BatteryState.charging),
      );
      
      _safeAddEvent(_currentBatteryInfo!);
      debugPrint('배터리 정보 업데이트 완료: ${preciseLevel.toStringAsFixed(2)}%, 상태: $batteryState, 온도: ${temperature.toStringAsFixed(1)}°C, 전압: ${voltage}mV, 용량: ${capacity}mAh, 건강도: $health');
    } catch (e, stackTrace) {
      debugPrint('배터리 정보 업데이트 실패: $e');
      debugPrint('스택 트레이스: $stackTrace');
      
      // 최종 폴백: 최소한의 배터리 정보라도 표시
      try {
        final batteryLevel = await _battery.batteryLevel;
        final batteryState = await _battery.batteryState;
        
        _currentBatteryInfo = BatteryInfo(
          level: batteryLevel.toDouble(),
          state: batteryState,
          timestamp: DateTime.now(),
          temperature: -1.0,
          voltage: -1,
          capacity: -1,
          health: -1,
          chargingType: 'Unknown',
          chargingCurrent: -1,
          isCharging: batteryState == BatteryState.charging,
        );
        
        _safeAddEvent(_currentBatteryInfo!);
        debugPrint('최소 배터리 정보로 폴백: $batteryLevel%, 상태: $batteryState');
      } catch (fallbackError) {
        debugPrint('최종 폴백도 실패: $fallbackError');
        // 완전히 실패한 경우에도 빈 정보라도 전송하여 UI가 업데이트되도록 함
        _currentBatteryInfo = BatteryInfo(
          level: 0.0,
          state: BatteryState.unknown,
          timestamp: DateTime.now(),
          temperature: -1.0,
          voltage: -1,
          capacity: -1,
          health: -1,
          chargingType: 'Unknown',
          chargingCurrent: -1,
          isCharging: false,
        );
        _safeAddEvent(_currentBatteryInfo!);
      }
    }
  }

  /// 수동으로 배터리 정보 새로고침
  Future<void> refreshBatteryInfo() async {
    if (_isDisposed) {
      debugPrint('서비스가 이미 dispose됨, 배터리 정보 새로고침 건너뜀');
      return;
    }
    await _updateBatteryInfo();
  }

  /// 리소스 정리
  void dispose() {
    _isDisposed = true;
    stopMonitoring();
    if (_batteryInfoController != null && !_batteryInfoController!.isClosed) {
      _batteryInfoController!.close();
    }
  }
}
