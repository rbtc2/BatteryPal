import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../services/battery_service.dart';
import '../../../services/last_charging_info_service.dart';
import '../../../services/settings_service.dart';
import '../../../services/native_battery_service.dart';
import '../../../models/models.dart';
import '../../../screens/analysis/widgets/charging_patterns/services/charging_session_service.dart';
import '../../../models/charging_monitor_display_mode.dart';

/// 충전 모니터 컨트롤러
/// 타이머 및 상태 관리 로직을 담당하는 컨트롤러
class ChargingMonitorController extends ChangeNotifier {
  // ==================== 상수 ====================
  
  /// 최대 데이터 포인트 개수 (그래프에 표시할 최대 포인트 수)
  static const int maxDataPoints = 50;
  
  /// 충전 속도 업데이트 주기 (밀리초)
  static const Duration updateInterval = Duration(milliseconds: 200);
  
  /// 지속 시간 업데이트 주기 (초)
  static const Duration durationUpdateInterval = Duration(seconds: 1);
  
  /// 세션 시작 시간 재확인 딜레이 (앱 재시작 후 세션 확인용)
  static const Duration sessionRecheckDelay = Duration(seconds: 2);
  
  // ==================== 서비스 ====================
  
  final BatteryService _batteryService = BatteryService();
  final LastChargingInfoService _lastChargingInfoService = LastChargingInfoService();
  final ChargingSessionService _sessionService = ChargingSessionService();
  final SettingsService _settingsService = SettingsService();
  
  // ==================== 상태 변수 ====================
  
  /// 데이터 포인트 리스트
  final List<double> _dataPoints = [];
  List<double> get dataPoints => List.unmodifiable(_dataPoints);
  
  /// 충전 속도 업데이트 타이머
  Timer? _updateTimer;
  
  /// 지속 시간 업데이트 타이머
  Timer? _durationUpdateTimer;
  
  /// 마지막 충전 정보
  LastChargingInfo? _lastChargingInfo;
  LastChargingInfo? get lastChargingInfo => _lastChargingInfo;
  
  /// 현재 충전 세션 시작 시간
  DateTime? _sessionStartTime;
  DateTime? get sessionStartTime => _sessionStartTime;
  
  /// 마지막으로 확인한 설정 모드 (중복 체크 방지)
  ChargingMonitorDisplayMode? _lastDisplayMode;
  
  /// 컨트롤러가 활성화되어 있는지 여부
  bool _isActive = false;
  bool get isActive => _isActive;
  
  ChargingMonitorController() {
    // 설정 변경 리스너 등록
    _settingsService.addListener(_onSettingsChanged);
    _lastDisplayMode = _settingsService.appSettings.chargingMonitorDisplayMode;
  }
  
  /// 설정 변경 핸들러
  void _onSettingsChanged() {
    final currentDisplayMode = _settingsService.appSettings.chargingMonitorDisplayMode;
    
    // 설정 모드가 변경되었을 때만 타이머 재시작
    if (currentDisplayMode != _lastDisplayMode) {
      _lastDisplayMode = currentDisplayMode;
      _updateDurationTimerBasedOnSettings();
    }
  }
  
  /// 세션 시작 시간 확인 및 업데이트
  /// 세션이 나중에 시작될 수 있으므로 주기적으로 확인 필요
  void checkAndUpdateSessionStartTime() {
    final currentSessionStartTime = _sessionService.sessionStartTime;
    if (currentSessionStartTime != _sessionStartTime) {
      updateSessionStartTime();
    }
  }
  
  /// 세션 시작 시간 업데이트
  void updateSessionStartTime() {
    try {
      final sessionStartTime = _sessionService.sessionStartTime;
      if (_sessionStartTime != sessionStartTime) {
        _sessionStartTime = sessionStartTime;
        notifyListeners();
        
        // 지속 시간 타이머 업데이트 (설정에 따라 자동으로 시작/중지)
        _updateDurationTimerBasedOnSettings();
      }
    } catch (e) {
      // 세션 서비스 오류 시 조용히 처리
      debugPrint('ChargingMonitorController: 세션 시작 시간 업데이트 실패 - $e');
    }
  }

  /// 네이티브에서 저장한 충전 세션 정보 복구
  /// 앱 재시작 후에도 지속 시간을 정확히 표시하기 위해 사용
  Future<void> restoreSessionFromNative() async {
    try {
      final sessionInfo = await NativeBatteryService.getChargingSessionInfo();
      
      if (sessionInfo == null) {
        debugPrint('ChargingMonitorController: 네이티브 세션 정보 없음');
        return;
      }
      
      debugPrint('ChargingMonitorController: 네이티브 세션 정보 복구 - $sessionInfo');
      
      // 충전 중이고 세션 시작 시간이 있으면 복구
      if (sessionInfo.isChargingActive && sessionInfo.startTime != null) {
        // 네이티브에서 저장한 시작 시간이 더 이전이면 사용
        // (앱이 꺼진 상태에서 충전이 시작되었을 수 있음)
        if (_sessionStartTime == null || 
            sessionInfo.startTime!.isBefore(_sessionStartTime!)) {
          _sessionStartTime = sessionInfo.startTime;
          debugPrint('ChargingMonitorController: 세션 시작 시간 복구됨 - $_sessionStartTime');
          notifyListeners();
          
          // 지속 시간 타이머 업데이트
          _updateDurationTimerBasedOnSettings();
        }
      } else if (!sessionInfo.isChargingActive) {
        // 충전이 종료된 상태면 세션 시작 시간 초기화
        if (_sessionStartTime != null) {
          _sessionStartTime = null;
          debugPrint('ChargingMonitorController: 충전 종료 상태로 세션 시작 시간 초기화');
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('ChargingMonitorController: 네이티브 세션 정보 복구 실패 - $e');
    }
  }
  
  /// 설정에 따라 지속 시간 타이머 업데이트
  /// 중복 시작 방지를 위해 단일 진입점으로 사용
  void _updateDurationTimerBasedOnSettings() {
    final displayMode = _settingsService.appSettings.chargingMonitorDisplayMode;
    
    if (displayMode == ChargingMonitorDisplayMode.currentWithDuration &&
        _isActive &&
        _sessionStartTime != null) {
      // 타이머가 없거나 중지된 경우에만 시작
      if (_durationUpdateTimer == null || !_durationUpdateTimer!.isActive) {
        _startDurationUpdateTimer();
      }
    } else {
      // 조건을 만족하지 않으면 타이머 중지
      _stopDurationUpdateTimer();
    }
  }
  
  /// 지속 시간 업데이트 타이머 시작
  /// 중복 시작 방지: 이미 실행 중인 타이머가 있으면 시작하지 않음
  void _startDurationUpdateTimer() {
    try {
      // 이미 실행 중인 타이머가 있으면 중복 시작 방지
      if (_durationUpdateTimer != null && _durationUpdateTimer!.isActive) {
        return;
      }
      
      // 기존 타이머가 있으면 취소 (비활성 상태일 수 있음)
      _durationUpdateTimer?.cancel();
      
      // 설정 모드 확인
      final displayMode = _settingsService.appSettings.chargingMonitorDisplayMode;
      if (displayMode != ChargingMonitorDisplayMode.currentWithDuration) {
        // 지속 시간 표시 모드가 아니면 타이머 시작하지 않음
        return;
      }
      
      // 세션 시작 시간이 없으면 타이머 시작하지 않음
      if (_sessionStartTime == null) {
        return;
      }
      
      _durationUpdateTimer = Timer.periodic(durationUpdateInterval, (timer) {
        try {
          // 충전 중이고 세션 시작 시간이 있으면 UI 업데이트
          final batteryInfo = _batteryService.currentBatteryInfo;
          final currentDisplayMode = _settingsService.appSettings.chargingMonitorDisplayMode;
          
          // 세션 시작 시간이 변경되었을 수 있으므로 재확인
          final currentSessionStartTime = _sessionService.sessionStartTime;
          final sessionTimeChanged = currentSessionStartTime != _sessionStartTime;
          
          // 상태 변경이 필요한지 확인
          final shouldUpdate = sessionTimeChanged ||
              (batteryInfo != null && 
               batteryInfo.isCharging && 
               _sessionStartTime != null &&
               currentDisplayMode == ChargingMonitorDisplayMode.currentWithDuration);
          
          if (shouldUpdate) {
            // 세션 시작 시간이 변경되었으면 업데이트
            if (sessionTimeChanged) {
              _sessionStartTime = currentSessionStartTime;
            }
            
            // UI 업데이트
            notifyListeners();
          }
          
          // 충전 중이 아니거나 설정이 변경되었으면 타이머 중지
          if (batteryInfo == null || 
              !batteryInfo.isCharging || 
              _sessionStartTime == null ||
              currentDisplayMode != ChargingMonitorDisplayMode.currentWithDuration) {
            timer.cancel();
            _durationUpdateTimer = null;
          }
        } catch (e) {
          // 타이머 콜백에서 에러 발생 시 로그만 출력하고 계속 진행
          debugPrint('ChargingMonitorController: 지속 시간 타이머 콜백 에러 - $e');
        }
      });
    } catch (e) {
      // 타이머 시작 실패 시 에러 로그
      debugPrint('ChargingMonitorController: 지속 시간 타이머 시작 실패 - $e');
    }
  }
  
  /// 지속 시간 업데이트 타이머 중지
  void _stopDurationUpdateTimer() {
    _durationUpdateTimer?.cancel();
    _durationUpdateTimer = null;
  }

  /// 경과 시간 계산
  /// 세션 시작 시간으로부터 현재까지의 경과 시간을 반환
  Duration? calculateElapsedDuration() {
    if (_sessionStartTime == null) {
      return null;
    }
    
    final duration = DateTime.now().difference(_sessionStartTime!);
    
    // 음수 duration 방지 (시스템 시간 변경 등 엣지 케이스)
    if (duration.isNegative) {
      return null;
    }
    
    return duration;
  }

  /// 마지막 충전 정보 로드
  Future<void> loadLastChargingInfo() async {
    try {
      final info = await _lastChargingInfoService.getLastChargingInfo();
      if (_lastChargingInfo != info) {
        _lastChargingInfo = info;
        notifyListeners();
      }
    } catch (e) {
      // 에러 발생 시 조용히 처리 (UI는 기본값 표시)
      debugPrint('ChargingMonitorController: 마지막 충전 정보 로드 실패 - $e');
      if (_lastChargingInfo != null) {
        _lastChargingInfo = null;
        notifyListeners();
      }
    }
  }

  /// 충전 시작 처리
  void handleChargingStart() {
    updateSessionStartTime();
    startRealTimeUpdate();
  }
  
  /// 충전 종료 처리
  void handleChargingEnd() {
    stopRealTimeUpdate();
    _sessionStartTime = null;
    notifyListeners();
    loadLastChargingInfo();
  }
  
  /// 충전 중 업데이트 처리
  void handleChargingUpdate() {
    // 세션 시작 시간이 변경될 수 있으므로 확인
    checkAndUpdateSessionStartTime();
    
    // 설정 모드가 변경되었을 수 있으므로 타이머 업데이트
    _updateDurationTimerBasedOnSettings();
  }

  /// 실시간 업데이트 시작
  /// 중복 시작 방지 로직 포함
  void startRealTimeUpdate() {
    try {
      // 이미 실행 중인 타이머가 있으면 중복 시작 방지
      if (_updateTimer != null && _updateTimer!.isActive) {
        return;
      }
      
      _isActive = true;
      
      // 기존 타이머가 있으면 취소
      _updateTimer?.cancel();
      
      // 충전 속도 업데이트 타이머
      _updateTimer = Timer.periodic(updateInterval, (timer) {
        try {
          // BatteryService에서 현재 충전 전류 가져오기
          final batteryInfo = _batteryService.currentBatteryInfo;
          if (batteryInfo != null && batteryInfo.isCharging) {
            final current = batteryInfo.chargingCurrent.abs().toDouble();
            
            // 데이터 포인트 추가
            _dataPoints.add(current);
            if (_dataPoints.length > maxDataPoints) {
              _dataPoints.removeAt(0); // 오래된 데이터 제거
            }
            
            // UI 업데이트
            notifyListeners();
          } else {
            // 충전 중이 아니면 타이머 중지
            timer.cancel();
            _updateTimer = null;
            _isActive = false;
          }
        } catch (e) {
          // 타이머 콜백에서 에러 발생 시 로그만 출력하고 계속 진행
          debugPrint('ChargingMonitorController: 타이머 콜백 에러 - $e');
        }
      });

      // 지속 시간 업데이트 타이머 시작 (설정 모드에 따라 조건부)
      _updateDurationTimerBasedOnSettings();
    } catch (e) {
      // 타이머 시작 실패 시 에러 로그
      debugPrint('ChargingMonitorController: 실시간 업데이트 시작 실패 - $e');
    }
  }

  /// 실시간 업데이트 중지
  void stopRealTimeUpdate() {
    _updateTimer?.cancel();
    _updateTimer = null;
    _stopDurationUpdateTimer();
    _isActive = false;
    _dataPoints.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    // 설정 리스너 제거
    _settingsService.removeListener(_onSettingsChanged);
    
    // 타이머 정리
    _updateTimer?.cancel();
    _durationUpdateTimer?.cancel();
    
    super.dispose();
  }
}

