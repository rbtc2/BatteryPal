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
      debugPrint('배터리 서비스: 새로운 스트림 컨트롤러 생성');
    }
    return _batteryInfoController!.stream;
  }
  
  /// 배터리 정보 모델
  BatteryInfo? _currentBatteryInfo;
  BatteryInfo? get currentBatteryInfo => _currentBatteryInfo;
  
  /// 서비스가 dispose되었는지 확인하는 플래그
  bool _isDisposed = false;
  
  /// 마지막 업데이트 시간
  DateTime? _lastUpdateTime;
  
  /// 업데이트 중인지 확인하는 플래그 (중복 업데이트 방지)
  bool _isUpdating = false;
  
  /// 배터리 정보 검증을 위한 최소 업데이트 간격 (밀리초)
  static const int _minUpdateInterval = 1000; // 1초

  /// 배터리 정보가 유효한지 검증
  bool _isValidBatteryInfo(BatteryInfo info) {
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
  bool _shouldUpdate() {
    if (_lastUpdateTime == null) return true;
    
    final now = DateTime.now();
    final timeDiff = now.difference(_lastUpdateTime!).inMilliseconds;
    
    return timeDiff >= _minUpdateInterval;
  }
  
  /// 안전하게 스트림에 이벤트 추가
  void _safeAddEvent(BatteryInfo batteryInfo) {
    if (!_isDisposed && _batteryInfoController != null && !_batteryInfoController!.isClosed) {
      try {
        _batteryInfoController!.add(batteryInfo);
        debugPrint('배터리 정보 스트림에 추가됨: ${batteryInfo.formattedLevel}');
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
      debugPrint('배터리 모니터링 시작...');
      
      // 기존 구독 정리
      await _batteryStateSubscription?.cancel();
      _batteryStateSubscription = null;
      
      // 초기 배터리 정보 강제 업데이트
      await _updateBatteryInfo(forceUpdate: true);
      
      // 배터리 상태 변화 감지 (디바운싱 적용)
      _batteryStateSubscription = _battery.onBatteryStateChanged.listen(
        (BatteryState state) async {
          if (!_isDisposed && _shouldUpdate()) {
            debugPrint('배터리 상태 변화 감지: $state');
            await _updateBatteryInfo();
          }
        },
        onError: (error) {
          debugPrint('배터리 상태 변화 감지 오류: $error');
        },
      );
      
      debugPrint('배터리 모니터링 시작 완료');
    } catch (e, stackTrace) {
      debugPrint('배터리 모니터링 시작 실패: $e');
      debugPrint('스택 트레이스: $stackTrace');
      rethrow;
    }
  }

  /// 배터리 모니터링 중지
  void stopMonitoring() {
    _batteryStateSubscription?.cancel();
    _batteryStateSubscription = null;
  }

  /// 배터리 정보 업데이트
  Future<void> _updateBatteryInfo({bool forceUpdate = false}) async {
    if (_isDisposed) {
      debugPrint('서비스가 이미 dispose됨, 배터리 정보 업데이트 건너뜀');
      return;
    }
    
    // 중복 업데이트 방지
    if (_isUpdating && !forceUpdate) {
      debugPrint('이미 업데이트 중이므로 건너뜀');
      return;
    }
    
    // 업데이트 간격 검증 (강제 업데이트가 아닌 경우)
    if (!forceUpdate && !_shouldUpdate()) {
      debugPrint('업데이트 간격이 너무 짧아서 건너뜀');
      return;
    }
    
    _isUpdating = true;
    _lastUpdateTime = DateTime.now();
    
    try {
      debugPrint('배터리 정보 업데이트 시작... (강제: $forceUpdate)');
      
      // 네이티브 배터리 정보를 우선적으로 가져오기
      BatteryInfo? batteryInfo = await _getNativeBatteryInfo();
      
      // 네이티브 정보가 실패한 경우 플러그인 정보로 폴백
      if (batteryInfo == null) {
        debugPrint('네이티브 정보 실패, 플러그인 정보로 폴백');
        batteryInfo = await _getPluginBatteryInfo();
      }
      
      // 최종 검증 및 업데이트
      if (batteryInfo != null && _isValidBatteryInfo(batteryInfo)) {
        _currentBatteryInfo = batteryInfo;
        _safeAddEvent(batteryInfo);
        debugPrint('배터리 정보 업데이트 완료: ${batteryInfo.formattedLevel}');
      } else {
        debugPrint('배터리 정보가 유효하지 않아 업데이트 건너뜀');
      }
      
    } catch (e, stackTrace) {
      debugPrint('배터리 정보 업데이트 실패: $e');
      debugPrint('스택 트레이스: $stackTrace');
      
      // 최종 폴백: 최소한의 배터리 정보라도 표시
      await _fallbackToMinimalBatteryInfo();
    } finally {
      _isUpdating = false;
    }
  }
  
  /// 네이티브 배터리 정보 가져오기 (우선 사용)
  Future<BatteryInfo?> _getNativeBatteryInfo() async {
    try {
      debugPrint('네이티브 배터리 정보 수집 시작...');
      
      // 모든 네이티브 정보를 병렬로 가져오기
      final futures = await Future.wait([
        NativeBatteryService.getBatteryLevel(),
        NativeBatteryService.getBatteryTemperature(),
        NativeBatteryService.getBatteryVoltage(),
        NativeBatteryService.getBatteryCapacity(),
        NativeBatteryService.getBatteryHealth(),
        NativeBatteryService.getChargingInfo(),
      ]);
      
      final nativeLevel = futures[0] as double;
      final temperature = futures[1] as double;
      final voltage = futures[2] as int;
      final capacity = futures[3] as int;
      final health = futures[4] as int;
      final chargingInfo = futures[5] as Map<String, dynamic>;
      
      // 네이티브 레벨이 유효한지 확인
      if (nativeLevel < 0) {
        debugPrint('네이티브 레벨이 유효하지 않음: $nativeLevel');
        return null;
      }
      
      // 플러그인에서 기본 상태 정보 가져오기
      final batteryState = await _battery.batteryState;
      
      final batteryInfo = BatteryInfo(
        level: nativeLevel,
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
      
      debugPrint('네이티브 배터리 정보 수집 완료: ${batteryInfo.formattedLevel}');
      return batteryInfo;
      
    } catch (e) {
      debugPrint('네이티브 배터리 정보 수집 실패: $e');
      return null;
    }
  }
  
  /// 플러그인 배터리 정보 가져오기 (폴백)
  Future<BatteryInfo?> _getPluginBatteryInfo() async {
    try {
      debugPrint('플러그인 배터리 정보 수집 시작...');
      
      final batteryLevel = await _battery.batteryLevel;
      final batteryState = await _battery.batteryState;
      
      final batteryInfo = BatteryInfo(
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
      
      debugPrint('플러그인 배터리 정보 수집 완료: ${batteryInfo.formattedLevel}');
      return batteryInfo;
      
    } catch (e) {
      debugPrint('플러그인 배터리 정보 수집 실패: $e');
      return null;
    }
  }
  
  /// 최소한의 배터리 정보로 폴백
  Future<void> _fallbackToMinimalBatteryInfo() async {
    try {
      final batteryLevel = await _battery.batteryLevel;
      final batteryState = await _battery.batteryState;
      
      final batteryInfo = BatteryInfo(
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
      
      _currentBatteryInfo = batteryInfo;
      _safeAddEvent(batteryInfo);
      debugPrint('최소 배터리 정보로 폴백: ${batteryInfo.formattedLevel}');
      
    } catch (fallbackError) {
      debugPrint('최종 폴백도 실패: $fallbackError');
      // 완전히 실패한 경우에도 빈 정보라도 전송하여 UI가 업데이트되도록 함
      final batteryInfo = BatteryInfo(
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
      _currentBatteryInfo = batteryInfo;
      _safeAddEvent(batteryInfo);
    }
  }

  /// 수동으로 배터리 정보 새로고침
  Future<void> refreshBatteryInfo() async {
    if (_isDisposed) {
      debugPrint('서비스가 이미 dispose됨, 배터리 정보 새로고침 건너뜀');
      return;
    }
    
    debugPrint('수동 배터리 정보 새로고침 시작...');
    await _updateBatteryInfo(forceUpdate: true);
  }
  
  /// 배터리 서비스 상태 초기화 (앱 시작 시 호출)
  Future<void> resetService() async {
    debugPrint('배터리 서비스 상태 초기화...');
    
    // 기존 정보 초기화
    _currentBatteryInfo = null;
    _lastUpdateTime = null;
    _isUpdating = false;
    
    // 기존 구독 정리
    await _batteryStateSubscription?.cancel();
    _batteryStateSubscription = null;
    
    // 스트림 컨트롤러 재생성
    if (_batteryInfoController != null && !_batteryInfoController!.isClosed) {
      _batteryInfoController!.close();
    }
    _batteryInfoController = null;
    
    debugPrint('배터리 서비스 상태 초기화 완료');
  }

  /// 리소스 정리
  void dispose() {
    debugPrint('배터리 서비스 dispose 시작...');
    _isDisposed = true;
    stopMonitoring();
    
    if (_batteryInfoController != null && !_batteryInfoController!.isClosed) {
      _batteryInfoController!.close();
    }
    _batteryInfoController = null;
    
    _currentBatteryInfo = null;
    _lastUpdateTime = null;
    _isUpdating = false;
    
    debugPrint('배터리 서비스 dispose 완료');
  }
}
