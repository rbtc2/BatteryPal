import 'dart:async';
import 'dart:math';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/material.dart';
import 'native_battery_service.dart';
import '../models/app_models.dart';
import 'notification_service.dart';
import 'settings_service.dart';
import 'battery_history_database_service.dart';

/// 배터리 정보를 관리하는 서비스 클래스
class BatteryService {
  static final BatteryService _instance = BatteryService._internal();
  factory BatteryService() => _instance;
  BatteryService._internal();

  final Battery _battery = Battery();
  StreamSubscription<BatteryState>? _batteryStateSubscription;
  
  // 배터리 정보 스트림
  StreamController<BatteryInfo>? _batteryInfoController;
  
  // 충전 전류 전용 모니터링 타이머
  Timer? _chargingCurrentTimer;
  
  // 적응형 충전 전류 모니터링 간격 (밀리초)
  int _chargingCurrentInterval = 1000; // 기본 1초
  
  // 충전 전류 안정성 추적
  final List<int> _recentChargingCurrents = <int>[];
  static const int _stabilityCheckCount = 5; // 최근 5회 측정값으로 안정성 판단
  
  // 충전 완료 알림 관련
  SettingsService? _settingsService;
  bool _hasNotifiedChargingComplete = false; // 중복 알림 방지
  
  // 충전 퍼센트 알림 관련
  final Map<double, bool> _chargingPercentNotified = {}; // 각 퍼센트별 알림 여부 추적
  
  // 충전 전류 데이터 저장을 위한 데이터베이스 서비스
  final BatteryHistoryDatabaseService _databaseService = BatteryHistoryDatabaseService();
  bool _isDatabaseInitialized = false;
  
  // 충전 전류 저장을 위한 배치 버퍼 (성능 최적화)
  final List<Map<String, dynamic>> _chargingCurrentBuffer = [];
  Timer? _chargingCurrentSaveTimer;
  
  /// SettingsService 설정 (선택적)
  void setSettingsService(SettingsService? settingsService) {
    _settingsService = settingsService;
  }
  
  Stream<BatteryInfo> get batteryInfoStream {
    if (_batteryInfoController == null || _batteryInfoController!.isClosed) {
      _batteryInfoController = StreamController<BatteryInfo>.broadcast();
      _debugLog('배터리 서비스: 새로운 스트림 컨트롤러 생성');
    }
    return _batteryInfoController!.stream;
  }
  
  /// 배터리 정보 모델
  BatteryInfo? _currentBatteryInfo;
  BatteryInfo? get currentBatteryInfo => _currentBatteryInfo;
  
  /// 안정화된 충전 전류 가져오기 (이동 평균 사용)
  int getStableChargingCurrent() {
    if (_recentChargingCurrents.isEmpty) {
      return _currentBatteryInfo?.chargingCurrent ?? -1;
    }
    
    // 최근 측정값들의 평균 사용 (이동 평균)
    final average = _recentChargingCurrents.reduce((a, b) => a + b) / _recentChargingCurrents.length;
    return average.round();
  }
  
  /// 중앙값 충전 전류 가져오기 (극값의 영향을 줄임)
  int getMedianChargingCurrent() {
    if (_recentChargingCurrents.isEmpty) {
      return _currentBatteryInfo?.chargingCurrent ?? -1;
    }
    
    final sorted = List<int>.from(_recentChargingCurrents)..sort();
    final middle = sorted.length ~/ 2;
    
    if (sorted.length % 2 == 1) {
      return sorted[middle];
    } else {
      return ((sorted[middle - 1] + sorted[middle]) / 2).round();
    }
  }
  
  /// 충전 전류 안정성 상태 확인
  bool isChargingCurrentStable() {
    return _isChargingCurrentStable();
  }
  
  /// 최근 충전 전류 측정값 개수
  int get recentChargingCurrentCount => _recentChargingCurrents.length;
  
  /// 성능 최적화를 위한 로그 레벨 관리
  static const bool _enableDebugLogs = false; // 릴리즈 빌드에서는 false
  
  void _debugLog(String message) {
    if (_enableDebugLogs) {
      debugPrint(message);
    }
  }
  
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
  
  /// 배터리 레벨에 따른 적응형 모니터링 간격 계산
  int _getAdaptiveMonitoringInterval() {
    if (_currentBatteryInfo == null) return 1000; // 기본 1초
    
    final batteryLevel = _currentBatteryInfo!.level;
    
    if (batteryLevel >= 80) {
      return 2000; // 80% 이상: 2초 간격 (충전 속도 감소)
    } else if (batteryLevel >= 50) {
      return 1000; // 50-80%: 1초 간격
    } else {
      return 500;  // 50% 미만: 0.5초 간격 (빠른 충전)
    }
  }
  
  /// 충전 전류 안정성 확인
  bool _isChargingCurrentStable() {
    if (_recentChargingCurrents.length < _stabilityCheckCount) {
      return false; // 충분한 데이터가 없으면 불안정으로 간주
    }
    
    // 최근 측정값들의 표준편차 계산
    final average = _recentChargingCurrents.reduce((a, b) => a + b) / _recentChargingCurrents.length;
    final variance = _recentChargingCurrents.map((x) => (x - average) * (x - average)).reduce((a, b) => a + b) / _recentChargingCurrents.length;
    final standardDeviation = sqrt(variance);
    
    // 표준편차가 평균의 10% 미만이면 안정적
    return standardDeviation < (average * 0.1);
  }
  
  /// 충전 전류 안정성에 따른 간격 조정
  void _adjustMonitoringInterval() {
    final adaptiveInterval = _getAdaptiveMonitoringInterval();
    final stabilityFactor = _isChargingCurrentStable() ? 1.5 : 1.0; // 안정적이면 간격 늘리기
    
    _chargingCurrentInterval = (adaptiveInterval * stabilityFactor).round();
    
    debugPrint('모니터링 간격 조정: ${_chargingCurrentInterval}ms (적응형: ${adaptiveInterval}ms, 안정성: ${_isChargingCurrentStable()})');
  }
  
  /// 충전 전류 전용 모니터링 시작 (적응형 간격)
  void _startChargingCurrentMonitoring() {
    if (_chargingCurrentTimer != null) {
      debugPrint('충전 전류 모니터링이 이미 실행 중입니다');
      return;
    }
    
    // 초기 간격 설정
    _adjustMonitoringInterval();
    
    debugPrint('충전 전류 전용 모니터링 시작 (${_chargingCurrentInterval}ms 간격)');
    
    _chargingCurrentTimer = Timer.periodic(
      Duration(milliseconds: _chargingCurrentInterval),
      (timer) async {
        if (!_isDisposed && _currentBatteryInfo?.isCharging == true) {
          await _updateChargingCurrentOnly();
          
          // 간격 동적 조정 (매 5회마다)
          if (_recentChargingCurrents.length % 5 == 0) {
            _adjustMonitoringInterval();
            // 타이머 재시작 (새로운 간격으로)
            _restartChargingCurrentTimer();
          }
        }
      },
    );
  }
  
  /// 충전 전류 모니터링 타이머 재시작 (새로운 간격으로)
  void _restartChargingCurrentTimer() {
    _chargingCurrentTimer?.cancel();
    _chargingCurrentTimer = null;
    
    if (_currentBatteryInfo?.isCharging == true) {
      debugPrint('충전 전류 모니터링 재시작 (${_chargingCurrentInterval}ms 간격)');
      
      _chargingCurrentTimer = Timer.periodic(
        Duration(milliseconds: _chargingCurrentInterval),
        (timer) async {
          if (!_isDisposed && _currentBatteryInfo?.isCharging == true) {
            await _updateChargingCurrentOnly();
            
            // 간격 동적 조정 (매 5회마다)
            if (_recentChargingCurrents.length % 5 == 0) {
              _adjustMonitoringInterval();
              _restartChargingCurrentTimer();
            }
          }
        },
      );
    }
  }
  
  /// 충전 전류 전용 모니터링 중지
  void _stopChargingCurrentMonitoring() {
    debugPrint('충전 전류 전용 모니터링 중지');
    _chargingCurrentTimer?.cancel();
    _chargingCurrentTimer = null;
  }
  
  /// 충전 전류만 빠르게 업데이트 (안정성 추적 포함)
  Future<void> _updateChargingCurrentOnly() async {
    if (_isDisposed) {
      debugPrint('서비스가 이미 dispose됨, 충전 전류 업데이트 건너뜀');
      return;
    }
    
    try {
      debugPrint('충전 전류만 업데이트 시작...');
      
      // 네이티브에서 충전 전류만 빠르게 가져오기
      final chargingCurrent = await NativeBatteryService.getChargingCurrentOnly();
      
      if (chargingCurrent >= 0 && _currentBatteryInfo != null) {
        // 충전 전류 안정성 추적을 위한 데이터 수집
        _recentChargingCurrents.add(chargingCurrent);
        if (_recentChargingCurrents.length > _stabilityCheckCount) {
          _recentChargingCurrents.removeAt(0); // 오래된 데이터 제거
        }
        
        // 기존 배터리 정보의 충전 전류만 업데이트
        final updatedBatteryInfo = _currentBatteryInfo!.copyWith(
          chargingCurrent: chargingCurrent,
          timestamp: DateTime.now(),
        );
        
        // 충전 전류가 실제로 변경된 경우에만 업데이트 및 저장
        if (_currentBatteryInfo!.chargingCurrent != chargingCurrent) {
          debugPrint('충전 전류 변화 감지: ${_currentBatteryInfo!.chargingCurrent}mA → ${chargingCurrent}mA');
          
          _currentBatteryInfo = updatedBatteryInfo;
          _safeAddEvent(updatedBatteryInfo);
          
          // 충전 전류 데이터를 데이터베이스에 저장 (배치 처리)
          await _saveChargingCurrentToDatabase(chargingCurrent);
          
          debugPrint('충전 전류 업데이트 완료: ${chargingCurrent}mA');
        }
      }
      
    } catch (e) {
      debugPrint('충전 전류 업데이트 실패: $e');
    }
  }
  
  /// 충전 전류 데이터를 데이터베이스에 저장 (배치 처리)
  Future<void> _saveChargingCurrentToDatabase(int currentMa) async {
    try {
      // 데이터베이스 초기화 확인
      if (!_isDatabaseInitialized) {
        await _databaseService.initialize();
        _isDatabaseInitialized = true;
      }
      
      // 현재 시간과 충전 전류를 버퍼에 추가
      _chargingCurrentBuffer.add({
        'timestamp': DateTime.now(),
        'currentMa': currentMa,
      });
      
      // 배치 저장 타이머가 없으면 시작 (10초마다 저장)
      if (_chargingCurrentSaveTimer == null) {
        _chargingCurrentSaveTimer = Timer.periodic(Duration(seconds: 10), (timer) async {
          if (_chargingCurrentBuffer.isNotEmpty) {
            final pointsToSave = List<Map<String, dynamic>>.from(_chargingCurrentBuffer);
            _chargingCurrentBuffer.clear();
            
            try {
              await _databaseService.insertChargingCurrentPoints(pointsToSave);
              debugPrint('충전 전류 데이터 ${pointsToSave.length}개 배치 저장 완료');
            } catch (e) {
              debugPrint('충전 전류 데이터 배치 저장 실패: $e');
              // 실패 시 다시 버퍼에 추가
              _chargingCurrentBuffer.addAll(pointsToSave);
            }
          }
        });
      }
      
      // 버퍼가 너무 크면 (100개 이상) 즉시 저장
      if (_chargingCurrentBuffer.length >= 100) {
        final pointsToSave = List<Map<String, dynamic>>.from(_chargingCurrentBuffer);
        _chargingCurrentBuffer.clear();
        
        try {
          await _databaseService.insertChargingCurrentPoints(pointsToSave);
          debugPrint('충전 전류 데이터 ${pointsToSave.length}개 즉시 저장 완료 (버퍼 초과)');
        } catch (e) {
          debugPrint('충전 전류 데이터 즉시 저장 실패: $e');
          // 실패 시 다시 버퍼에 추가
          _chargingCurrentBuffer.addAll(pointsToSave);
        }
      }
    } catch (e) {
      debugPrint('충전 전류 데이터 저장 준비 실패: $e');
    }
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
      
      // 네이티브 배터리 상태 변화 리스너 초기화 (실시간 감지)
      NativeBatteryService.initializeBatteryStateListener(_handleNativeBatteryStateChange);
      
      // 초기 배터리 정보 강제 업데이트
      await _updateBatteryInfo(forceUpdate: true);
      
      // 배터리 상태 변화 감지 (디바운싱 적용)
      _batteryStateSubscription = _battery.onBatteryStateChanged.listen(
        (BatteryState state) async {
          if (!_isDisposed && _shouldUpdate()) {
            debugPrint('배터리 상태 변화 감지: $state');
            await _updateBatteryInfo();
            
            // 충전 상태 변화 시 충전 전류 모니터링 시작/중지
            if (state == BatteryState.charging) {
              _startChargingCurrentMonitoring();
            } else {
              _stopChargingCurrentMonitoring();
            }
          }
        },
        onError: (error) {
          debugPrint('배터리 상태 변화 감지 오류: $error');
        },
      );
      
      // 초기 충전 상태 확인하여 충전 전류 모니터링 시작
      if (_currentBatteryInfo?.isCharging == true) {
        _startChargingCurrentMonitoring();
      }
      
      debugPrint('배터리 모니터링 시작 완료');
    } catch (e, stackTrace) {
      debugPrint('배터리 모니터링 시작 실패: $e');
      debugPrint('스택 트레이스: $stackTrace');
      rethrow;
    }
  }

  /// 네이티브에서 오는 배터리 상태 변화 즉시 처리
  Future<void> _handleNativeBatteryStateChange(Map<String, dynamic> chargingInfo) async {
    if (_isDisposed) {
      debugPrint('서비스가 이미 dispose됨, 네이티브 배터리 상태 변화 처리 건너뜀');
      return;
    }
    
    try {
      debugPrint('네이티브 배터리 상태 변화 즉시 처리: $chargingInfo');
      
      // 기존 배터리 정보의 레벨을 유지하면서 충전 정보만 업데이트
      final wasCharging = _currentBatteryInfo?.isCharging ?? false;
      final currentLevel = _currentBatteryInfo?.level ?? 0.0;
      final currentTemperature = _currentBatteryInfo?.temperature ?? -1.0;
      final currentVoltage = _currentBatteryInfo?.voltage ?? -1;
      final currentCapacity = _currentBatteryInfo?.capacity ?? -1;
      final currentHealth = _currentBatteryInfo?.health ?? -1;
      
      // 충전 정보를 BatteryInfo로 변환하되 기존 정보 유지
      final batteryInfo = BatteryInfo.fromChargingInfoWithExistingData(
        chargingInfo,
        level: currentLevel,
        temperature: currentTemperature,
        voltage: currentVoltage,
        capacity: currentCapacity,
        health: currentHealth,
      );
      
      if (_isValidBatteryInfo(batteryInfo)) {
        final previousLevel = _currentBatteryInfo?.level ?? 0.0;
        _currentBatteryInfo = batteryInfo;
        
        // 즉시 스트림에 이벤트 추가 (디바운싱 없이)
        _safeAddEvent(batteryInfo);
        
        // 충전 상태 변화 감지하여 충전 전류 모니터링 시작/중지
        if (batteryInfo.isCharging && !wasCharging) {
          debugPrint('충전 시작 감지 - 충전 전류 모니터링 시작');
          _startChargingCurrentMonitoring();
          // 충전 시작 시 알림 플래그 리셋
          _hasNotifiedChargingComplete = false;
          _chargingPercentNotified.clear();
        } else if (!batteryInfo.isCharging && wasCharging) {
          debugPrint('충전 종료 감지 - 충전 전류 모니터링 중지');
          _stopChargingCurrentMonitoring();
          // 충전 종료 시 남은 데이터 저장
          await _flushChargingCurrentBuffer();
          // 충전 종료 시 알림 플래그 리셋
          _hasNotifiedChargingComplete = false;
          _chargingPercentNotified.clear();
        }
        
        // 충전 완료 알림 체크
        _checkChargingCompleteNotification(batteryInfo, previousLevel, wasCharging);
        
        // 충전 퍼센트 알림 체크
        _checkChargingPercentNotification(batteryInfo, previousLevel);
        
        debugPrint('네이티브 배터리 상태 변화 처리 완료: ${batteryInfo.formattedLevel}');
      } else {
        debugPrint('네이티브 배터리 정보가 유효하지 않아 처리 건너뜀');
      }
    } catch (e, stackTrace) {
      debugPrint('네이티브 배터리 상태 변화 처리 실패: $e');
      debugPrint('스택 트레이스: $stackTrace');
    }
  }

  /// 배터리 모니터링 중지
  void stopMonitoring() {
    _batteryStateSubscription?.cancel();
    _batteryStateSubscription = null;
    
    // 충전 전류 모니터링도 중지
    _stopChargingCurrentMonitoring();
    
    // 남은 충전 전류 데이터 저장
    _flushChargingCurrentBuffer();
  }
  
  /// 충전 전류 버퍼에 남은 데이터를 즉시 저장
  Future<void> _flushChargingCurrentBuffer() async {
    _chargingCurrentSaveTimer?.cancel();
    _chargingCurrentSaveTimer = null;
    
    if (_chargingCurrentBuffer.isNotEmpty) {
      final pointsToSave = List<Map<String, dynamic>>.from(_chargingCurrentBuffer);
      _chargingCurrentBuffer.clear();
      
      try {
        if (_isDatabaseInitialized) {
          await _databaseService.insertChargingCurrentPoints(pointsToSave);
          debugPrint('충전 전류 데이터 ${pointsToSave.length}개 최종 저장 완료');
        }
      } catch (e) {
        debugPrint('충전 전류 데이터 최종 저장 실패: $e');
      }
    }
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
        final wasCharging = _currentBatteryInfo?.isCharging ?? false;
        final previousLevel = _currentBatteryInfo?.level ?? 0.0;
        _currentBatteryInfo = batteryInfo;
        _safeAddEvent(batteryInfo);
        
        // 충전 상태 변화 감지하여 충전 전류 모니터링 시작/중지
        if (batteryInfo.isCharging && !wasCharging) {
          _startChargingCurrentMonitoring();
          // 충전 시작 시 알림 플래그 리셋
          _hasNotifiedChargingComplete = false;
        } else if (!batteryInfo.isCharging && wasCharging) {
          _stopChargingCurrentMonitoring();
          // 충전 종료 시 남은 데이터 저장
          await _flushChargingCurrentBuffer();
          // 충전 종료 시 알림 플래그 리셋
          _hasNotifiedChargingComplete = false;
        }
        
        // 충전 완료 알림 체크
        _checkChargingCompleteNotification(batteryInfo, previousLevel, wasCharging);
        
        // 충전 퍼센트 알림 체크
        _checkChargingPercentNotification(batteryInfo, previousLevel);
        
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
  
  /// 충전 타입이 알림 대상인지 확인
  bool _shouldNotifyForChargingType(
    String chargingType,
    bool notifyOnFastCharging,
    bool notifyOnNormalCharging,
  ) {
    // 둘 다 false면 알림 안 함
    if (!notifyOnFastCharging && !notifyOnNormalCharging) {
      return false;
    }
    
    // 둘 다 true면 모든 타입 알림
    if (notifyOnFastCharging && notifyOnNormalCharging) {
      return true;
    }
    
    // AC는 고속 충전, USB/Wireless는 일반 충전
    final isFastCharging = chargingType == 'AC';
    final isNormalCharging = chargingType == 'USB' || chargingType == 'Wireless';
    
    if (notifyOnFastCharging && isFastCharging) {
      return true;
    }
    
    if (notifyOnNormalCharging && isNormalCharging) {
      return true;
    }
    
    return false;
  }

  /// 충전 완료 알림 체크 및 표시
  Future<void> _checkChargingCompleteNotification(
    BatteryInfo batteryInfo,
    double previousLevel,
    bool wasCharging,
  ) async {
    // 설정이 없으면 알림 안 함
    if (_settingsService == null) {
      return;
    }
    
    // 충전 완료 알림이 비활성화되어 있으면 알림 안 함
    if (!_settingsService!.appSettings.chargingCompleteNotificationEnabled) {
      return;
    }
    
    // 충전 타입 필터 확인
    final shouldNotify = _shouldNotifyForChargingType(
      batteryInfo.chargingType,
      _settingsService!.appSettings.chargingCompleteNotifyOnFastCharging,
      _settingsService!.appSettings.chargingCompleteNotifyOnNormalCharging,
    );
    
    if (!shouldNotify) {
      return;
    }
    
    // 이미 알림을 보냈으면 다시 보내지 않음
    if (_hasNotifiedChargingComplete) {
      return;
    }
    
    // 조건 확인:
    // 1. 현재 충전 중이어야 함
    // 2. 배터리 레벨이 100%여야 함
    // 3. 이전 레벨이 100% 미만이어야 함 (100%에 도달한 순간 감지)
    if (batteryInfo.isCharging &&
        batteryInfo.level >= 100.0 &&
        previousLevel < 100.0) {
      try {
        await NotificationService().showChargingCompleteNotification();
        _hasNotifiedChargingComplete = true;
        debugPrint('충전 완료 알림 표시됨');
      } catch (e) {
        debugPrint('충전 완료 알림 표시 실패: $e');
      }
    }
    
    // 배터리 레벨이 100% 미만으로 떨어지면 알림 플래그 리셋 (다시 충전 시 알림 가능하도록)
    if (batteryInfo.level < 100.0) {
      _hasNotifiedChargingComplete = false;
    }
  }

  /// 충전 퍼센트 알림 체크 및 표시
  Future<void> _checkChargingPercentNotification(
    BatteryInfo batteryInfo,
    double previousLevel,
  ) async {
    // 설정이 없으면 알림 안 함
    if (_settingsService == null) {
      return;
    }
    
    // 충전 퍼센트 알림이 비활성화되어 있으면 알림 안 함
    if (!_settingsService!.appSettings.chargingPercentNotificationEnabled) {
      return;
    }
    
    // 충전 중이 아니면 알림 안 함
    if (!batteryInfo.isCharging) {
      // 충전 종료 시 알림 플래그 리셋
      _chargingPercentNotified.clear();
      return;
    }
    
    // 알림 받을 퍼센트 목록이 비어있으면 알림 안 함
    final thresholds = _settingsService!.appSettings.chargingPercentThresholds;
    if (thresholds.isEmpty) {
      return;
    }
    
    // 충전 타입 필터 확인
    final shouldNotify = _shouldNotifyForChargingType(
      batteryInfo.chargingType,
      _settingsService!.appSettings.chargingPercentNotifyOnFastCharging,
      _settingsService!.appSettings.chargingPercentNotifyOnNormalCharging,
    );
    
    if (!shouldNotify) {
      return;
    }
    
    // 각 임계값에 대해 확인
    for (final threshold in thresholds) {
      // 현재 레벨이 임계값 이상이고, 이전 레벨이 임계값 미만인 경우 알림
      if (batteryInfo.level >= threshold && previousLevel < threshold) {
        // 이미 알림을 보낸 퍼센트인지 확인
        if (!(_chargingPercentNotified[threshold] ?? false)) {
          try {
            await NotificationService().showChargingPercentNotification(threshold.toInt());
            _chargingPercentNotified[threshold] = true;
            debugPrint('충전 퍼센트 알림 표시됨: ${threshold.toInt()}%');
          } catch (e) {
            debugPrint('충전 퍼센트 알림 표시 실패: $e');
          }
        }
      }
      
      // 레벨이 임계값 미만으로 떨어지면 알림 플래그 리셋
      if (batteryInfo.level < threshold) {
        _chargingPercentNotified[threshold] = false;
      }
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
    
    // 충전 전류 안정성 추적 데이터 초기화
    _recentChargingCurrents.clear();
    _chargingCurrentInterval = 1000; // 기본값으로 리셋
    
    // 알림 플래그 초기화
    _hasNotifiedChargingComplete = false;
    _chargingPercentNotified.clear();
    
    // 기존 구독 정리
    await _batteryStateSubscription?.cancel();
    _batteryStateSubscription = null;
    
    // 충전 전류 모니터링 중지
    _stopChargingCurrentMonitoring();
    
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
    
    // 충전 전류 모니터링도 중지
    _stopChargingCurrentMonitoring();
    
    if (_batteryInfoController != null && !_batteryInfoController!.isClosed) {
      _batteryInfoController!.close();
    }
    _batteryInfoController = null;
    
    _currentBatteryInfo = null;
    _lastUpdateTime = null;
    _isUpdating = false;
    
    // 충전 전류 안정성 추적 데이터 정리
    _recentChargingCurrents.clear();
    
    // 알림 플래그 정리
    _chargingPercentNotified.clear();
    
    debugPrint('배터리 서비스 dispose 완료');
  }
}
