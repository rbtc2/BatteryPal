import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../services/battery_service.dart';
import '../../../services/last_charging_info_service.dart';
import '../../../services/settings_service.dart';
import '../../../services/native_battery_service.dart';
import '../../../models/models.dart';
// 분석 탭 제거로 인해 주석 처리 (backup/analysis/)
// import '../../../screens/analysis/widgets/charging_patterns/services/charging_session_service.dart';
// import '../../../screens/analysis/widgets/charging_patterns/services/session_state_manager.dart';

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
  // 분석 탭 제거로 인해 주석 처리 (backup/analysis/)
  // final ChargingSessionService _sessionService = ChargingSessionService();
  final SettingsService _settingsService = SettingsService();
  
  // ==================== 상태 변수 ====================
  
  /// 데이터 포인트 리스트
  final List<double> _dataPoints = [];
  List<double> get dataPoints => List.unmodifiable(_dataPoints);
  
  /// 충전 속도 업데이트 타이머
  Timer? _updateTimer;
  
  /// 지속 시간 업데이트 타이머
  Timer? _durationUpdateTimer;
  
  /// 배터리 정보 스트림 구독
  StreamSubscription<BatteryInfo>? _batteryInfoSubscription;
  
  /// 세션 상태 스트림 구독 (ChargingSessionService의 세션 활성 상태)
  StreamSubscription<bool>? _sessionStateSubscription;
  
  /// 이전 충전 상태 (충전 시작/종료 감지용)
  bool _wasCharging = false;
  
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
    
    // 배터리 스트림 리스너 설정 (충전 상태 변화 자동 감지)
    _setupBatteryStreamListener();
    
    // 세션 상태 스트림 리스너 설정 (세션 활성/비활성 상태 직접 감지)
    // 분석 탭 제거로 인해 주석 처리 (backup/analysis/)
    // _setupSessionStateStreamListener();
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

  /// 배터리 스트림 리스너 설정
  /// 충전 상태 변화를 자동으로 감지하여 세션 시작 시간을 관리합니다
  /// PHASE 5: 세션 상태 스트림과의 중복 처리 방지 - 세션 상태 스트림을 우선시
  void _setupBatteryStreamListener() {
    _batteryInfoSubscription?.cancel();
    
    _batteryInfoSubscription = _batteryService.batteryInfoStream.listen((batteryInfo) {
      final isCharging = batteryInfo.isCharging;
      
      // PHASE 5: 세션 상태 스트림이 활성화되어 있으면 세션 상태 스트림을 우선시
      // 배터리 스트림은 실시간 업데이트만 처리하고, 세션 시작 시간은 세션 상태 스트림에서 관리
      if (!_wasCharging && isCharging) {
        // 충전 시작: 세션 상태 스트림이 처리할 때까지 대기하거나, 네이티브 정보만 확인
        // 세션 상태 스트림이 더 정확하므로 여기서는 실시간 업데이트만 시작
        _handleChargingStartFromStream(batteryInfo);
      } else if (_wasCharging && !isCharging) {
        // 충전 종료: 세션 상태 스트림이 처리할 때까지 대기
        _handleChargingEndFromStream();
      }
      
      _wasCharging = isCharging;
    });
    
    // 초기 충전 상태 설정
    final currentInfo = _batteryService.currentBatteryInfo;
    if (currentInfo != null) {
      _wasCharging = currentInfo.isCharging;
    }
    
    debugPrint('ChargingMonitorController: 배터리 스트림 리스너 설정 완료');
  }

  /// 세션 상태 스트림 리스너 설정
  // 분석 탭 제거로 인해 _setupSessionStateStreamListener 메서드 제거됨 (backup/analysis/)

  /// 세션 활성화 처리
  /// 세션 서비스에서 세션이 활성화되었을 때 호출됩니다
  /// PHASE 2: ending 상태에서 재활성화된 경우 세션 시작 시간 복구
  /// PHASE 4: 다른 충전기 감지 후 새 세션 시작 시 즉시 동기화
  /// PHASE 5: 세션 시작 시간 동기화 로직 최적화 및 중복 처리 방지
  /// PHASE 6-1: 완전 종료 후 새 세션 감지 로직 추가 - 이전 세션 시간이 남아있지 않도록 보장
  /// FIX: 새 세션이 시작될 때 항상 0분 0초부터 시작하도록 보장
  /// 분석 탭 제거로 인해 주석 처리 (backup/analysis/)
  void _handleSessionActivated() {
    // 분석 탭 제거로 인해 주석 처리 (backup/analysis/)
    // // 세션 서비스의 시작 시간과 동기화
    // final sessionStartTime = _sessionService.sessionStartTime;
    // final sessionState = _sessionService.sessionState;
    return; // 분석 탭 제거로 인해 비활성화
    
    // 분석 탭 제거로 인해 주석 처리 (backup/analysis/)
    // 아래 코드는 모두 주석 처리됨
    /*
    if (sessionStartTime == null) {
      debugPrint('ChargingMonitorController: 세션 활성화되었지만 시작 시간이 없음');
      return;
    }
    
    // FIX: 새 세션인지 재활성화인지 명확히 구분
    final isNewSession = _sessionStartTime == null;
    
    bool isNewSessionAfterCompleteEnd = false;
    Duration? timeDiff;
    
    if (_sessionStartTime != null && sessionStartTime.isAfter(_sessionStartTime!)) {
      timeDiff = sessionStartTime.difference(_sessionStartTime!);
      isNewSessionAfterCompleteEnd = true;
      debugPrint('ChargingMonitorController: 새 세션 감지 (세션 서비스 시간이 더 최신) - 이전: $_sessionStartTime, 새: $sessionStartTime, 차이: ${timeDiff.inSeconds}초');
    }
    
    if (isNewSession || isNewSessionAfterCompleteEnd) {
      final previousTime = _sessionStartTime;
      _sessionStartTime = sessionStartTime;
      
      if (isNewSession) {
        debugPrint('ChargingMonitorController: ✅ 새 세션 시작 (완전 종료 후) - 시작 시간: $_sessionStartTime (0분 0초부터 시작)');
      } else {
        debugPrint('ChargingMonitorController: ✅ 새 세션 시작 (완전 종료 후 재시작, 이전 시간 무시) - 이전: $previousTime, 새: $sessionStartTime, 차이: ${timeDiff!.inSeconds}초 (0분 0초부터 시작)');
      }
      
      notifyListeners();
      _updateDurationTimerBasedOnSettings();
    } else if (_sessionStartTime != sessionStartTime) {
      final timeDiff = _sessionStartTime!.difference(sessionStartTime);
      
      if (timeDiff.isNegative) {
        _sessionStartTime = sessionStartTime;
        debugPrint('ChargingMonitorController: 세션 활성화 - 시작 시간 동기화: $_sessionStartTime');
        notifyListeners();
        _updateDurationTimerBasedOnSettings();
      } else {
        debugPrint('ChargingMonitorController: 세션 재활성화 - 시작 시간 복구: $_sessionStartTime (차이: ${timeDiff.inSeconds}초)');
      }
    } else {
      if (sessionState == SessionState.active) {
        debugPrint('ChargingMonitorController: 세션 활성화 - 시작 시간 이미 동기화됨: $_sessionStartTime');
      } else {
        debugPrint('ChargingMonitorController: 세션 재활성화 - 시작 시간 복구: $_sessionStartTime');
      }
    }
    
    if (!_isActive) {
      startRealTimeUpdate();
    }
    */
  }

  /// 세션 비활성화 처리
  /// 세션 서비스에서 세션이 완전히 종료되었을 때 호출됩니다 (5초 대기 완료 후 또는 다른 충전기 감지 시)
  /// PHASE 3: 완전 종료 시 모든 상태를 리프레시하여 새 세션이 0초부터 시작되도록 함
  /// PHASE 4: 다른 충전기 감지 시 즉시 종료되는 경우도 처리
  /// PHASE 5: 불필요한 업데이트 방지 및 에러 처리 개선
  /// PHASE 6-2: 세션 시작 시간 리셋 보장 - 항상 null로 설정하여 완전 종료 확실히 처리
  /// PHASE 8-2: 세션 시작 시간 리셋 보장 강화 - 더 확실한 리셋 및 검증 로직 추가
  /// 분석 탭 제거로 인해 주석 처리 (backup/analysis/)
  void _handleSessionDeactivated() {
    // 분석 탭 제거로 인해 주석 처리 (backup/analysis/)
    debugPrint('ChargingMonitorController: 세션 비활성화 처리 (분석 탭 제거로 인해 비활성화)');
    return; // 분석 탭 제거로 인해 비활성화
    
    // 분석 탭 제거로 인해 주석 처리 (backup/analysis/)
    // 아래 코드는 모두 주석 처리됨
    /*
    try {
      final sessionState = _sessionService.sessionState;
      final sessionStartTime = _sessionService.sessionStartTime;
      final isImmediateEnd = sessionState == SessionState.idle;
      
      debugPrint('ChargingMonitorController: 세션 상태 확인 - sessionState: ${sessionState.name}, sessionStartTime: $sessionStartTime');
      
      if (isImmediateEnd) {
        debugPrint('ChargingMonitorController: 세션 즉시 종료 (다른 충전기 감지 또는 5초 대기 완료)');
      } else {
        debugPrint('ChargingMonitorController: 세션 완전 종료 (5초 대기 완료)');
      }
      
      final hadSessionTime = _sessionStartTime != null;
      final previousSessionStartTime = _sessionStartTime;
      
      if (sessionStartTime != null && sessionState == SessionState.idle) {
        debugPrint('ChargingMonitorController: ⚠️ 경고 - 세션 서비스가 idle 상태인데 시작 시간이 남아있음: $sessionStartTime');
      }
      
      _sessionStartTime = null;
      
      if (hadSessionTime) {
        debugPrint('ChargingMonitorController: ✅ 세션 완전 종료 - 세션 시작 시간 리셋 완료 (이전: $previousSessionStartTime → null)');
      } else {
        debugPrint('ChargingMonitorController: 세션 완전 종료 - 세션 시작 시간 이미 null (이중 리셋 방지)');
      }
      
      _stopDurationUpdateTimer();
      
      if (_isActive) {
        debugPrint('ChargingMonitorController: 실시간 업데이트 중지');
        stopRealTimeUpdate();
      }
      
      loadLastChargingInfo();
      
      if (_sessionStartTime != null) {
        debugPrint('ChargingMonitorController: ⚠️ 경고 - 세션 시작 시간 리셋 실패! 강제로 null 설정');
        _sessionStartTime = null;
      }
      
      notifyListeners();
      
      debugPrint('ChargingMonitorController: ✅ 세션 완전 종료 처리 완료 - 모든 상태 리프레시됨 (세션 시작 시간: $_sessionStartTime)');
      debugPrint('ChargingMonitorController: ========== 세션 비활성화 감지 완료 ==========');
    } catch (e, stackTrace) {
      debugPrint('ChargingMonitorController: ⚠️ 세션 비활성화 처리 중 오류 - $e');
      debugPrint('스택 트레이스: $stackTrace');
      _sessionStartTime = null;
      _stopDurationUpdateTimer();
      if (_isActive) {
        stopRealTimeUpdate();
      }
      notifyListeners();
      debugPrint('ChargingMonitorController: 에러 발생 후 기본 정리 작업 완료 (세션 시작 시간: $_sessionStartTime)');
    }
    */
  }

  /// 스트림에서 충전 시작 감지 시 처리
  /// 네이티브에서 저장한 세션 정보를 우선적으로 사용합니다
  /// PHASE 3: 5초 이후 재시작 시 새 세션이 0초부터 시작되도록 처리
  /// PHASE 5: 세션 상태 스트림과의 중복 처리 방지 - 세션 상태 스트림이 처리할 때까지 대기
  /// PHASE 6-2: 안전장치 추가 - idle 상태에서 세션 시작 시간이 남아있으면 강제 리셋
  Future<void> _handleChargingStartFromStream(BatteryInfo batteryInfo) async {
    try {
      debugPrint('ChargingMonitorController: 스트림에서 충전 시작 감지');
      
      // 분석 탭 제거로 인해 주석 처리 (backup/analysis/)
      // // PHASE 5: 세션 상태 스트림이 활성화되어 있으면 세션 상태 스트림을 우선시
      // // 세션 상태 스트림이 더 정확하므로, 여기서는 네이티브 정보만 확인하고
      // // 세션 시작 시간은 세션 상태 스트림의 _handleSessionActivated()에서 처리
      // final sessionState = _sessionService.sessionState;
      // 
      // // PHASE 8-3: 안전장치 강화 - idle 상태에서 세션 시작 시간이 남아있으면 강제 리셋
      // // 완전 종료 후 재시작 시 이전 세션 시간이 남아있지 않도록 보장
      // if (sessionState == SessionState.idle && _sessionStartTime != null) {
      //   debugPrint('ChargingMonitorController: ⚠️ 안전장치 - idle 상태에서 이전 세션 시간 발견, 강제 리셋 (이전: $_sessionStartTime)');
      //   _sessionStartTime = null;
      //   _stopDurationUpdateTimer();
      // }
      // 
      // // 세션 상태 스트림이 이미 처리했거나 처리 중이면 여기서는 실시간 업데이트만 시작
      // if (sessionState == SessionState.active || sessionState == SessionState.ending) {
      //   // 세션 상태 스트림이 이미 처리했으므로 실시간 업데이트만 시작
      //   if (!_isActive) {
      //     startRealTimeUpdate();
      //   }
      //   return;
      // }
      // 
      // // PHASE 3: idle 상태에서 새 세션이 시작되는 경우 (5초 이후 재시작)
      // // 세션 시작 시간이 이미 null로 리셋되어 있으므로 새로 시작
      // if (sessionState == SessionState.idle && _sessionStartTime == null) {
      
      // 세션 서비스 없이 네이티브 정보만 사용
      final sessionInfo = await NativeBatteryService.getChargingSessionInfo();
      
      if (sessionInfo != null && 
          sessionInfo.isChargingActive && 
          sessionInfo.startTime != null) {
        _sessionStartTime = sessionInfo.startTime;
        debugPrint('ChargingMonitorController: 네이티브 세션 시작 시간 사용 - $_sessionStartTime');
      } else if (_sessionStartTime == null) {
        // 새 세션 시작 (0초부터 카운팅)
        _sessionStartTime = DateTime.now();
        debugPrint('ChargingMonitorController: 새 세션 시작 - $_sessionStartTime');
      }
      
      notifyListeners();
      _updateDurationTimerBasedOnSettings();
      
      // 실시간 업데이트 시작
      if (!_isActive) {
        startRealTimeUpdate();
      }
    } catch (e) {
      debugPrint('ChargingMonitorController: 충전 시작 처리 실패 - $e');
      // 에러가 발생해도 실시간 업데이트는 시작 (세션 시작 시간은 세션 상태 스트림에서 처리)
      if (!_isActive) {
        startRealTimeUpdate();
      }
    }
  }

  /// 스트림에서 충전 종료 감지 시 처리
  /// PHASE 2: ending 상태일 때는 세션 시작 시간을 유지합니다
  /// 세션이 완전히 종료되면 (PHASE 3에서) 세션 상태 스트림을 통해 리셋됩니다
  /// PHASE 8-3: idle 상태에서 세션 시작 시간 리셋 보장 강화
  void _handleChargingEndFromStream() {
    debugPrint('ChargingMonitorController: 스트림에서 충전 종료 감지');
    
    // 분석 탭 제거로 인해 주석 처리 (backup/analysis/)
    // // 세션 서비스의 상태 확인
    // final sessionState = _sessionService.sessionState;
    // final sessionStartTime = _sessionService.sessionStartTime;
    
    // 세션 서비스 없이 기본 동작만 수행
    stopRealTimeUpdate();
    return;
    
    // 분석 탭 제거로 인해 주석 처리 (backup/analysis/)
    // 아래 코드는 모두 주석 처리됨
    /*
    debugPrint('ChargingMonitorController: 충전 종료 감지 - sessionState: ${sessionState.name}, sessionStartTime: $sessionStartTime');
    
    if (sessionState == SessionState.ending) {
      debugPrint('ChargingMonitorController: 세션 ending 상태 - 세션 시작 시간 유지 (5초 대기 중)');
      stopRealTimeUpdate();
      notifyListeners();
    } else if (sessionState == SessionState.idle) {
      if (_sessionStartTime != null) {
        debugPrint('ChargingMonitorController: ⚠️ 안전장치 - idle 상태에서 세션 시작 시간 발견, 강제 리셋 (이전: $_sessionStartTime)');
        _sessionStartTime = null;
        _stopDurationUpdateTimer();
        notifyListeners();
      }
      
      if (sessionStartTime != null) {
        debugPrint('ChargingMonitorController: ⚠️ 경고 - 세션 서비스가 idle 상태인데 시작 시간이 남아있음: $sessionStartTime');
      }
      
      stopRealTimeUpdate();
      debugPrint('ChargingMonitorController: 세션 idle 상태 - 완전 종료 확인됨 (세션 시작 시간: $_sessionStartTime)');
    } else {
      debugPrint('ChargingMonitorController: 충전 종료 감지했지만 세션 상태가 active - 비정상 상태');
      stopRealTimeUpdate();
    }
    */
  }
  
  /// 세션 시작 시간 확인 및 업데이트
  /// 세션이 나중에 시작될 수 있으므로 주기적으로 확인 필요
  /// PHASE 6-4: 완전 종료 후에는 업데이트하지 않도록 안전장치 추가
  /// PHASE 8-3: 안전장치 강화 - idle 상태에서 세션 시작 시간 리셋 보장
  void checkAndUpdateSessionStartTime() {
    // 분석 탭 제거로 인해 주석 처리 (backup/analysis/)
    return; // 분석 탭 제거로 인해 비활성화
    
    // 분석 탭 제거로 인해 주석 처리 (backup/analysis/)
    // 아래 코드는 모두 주석 처리됨
    /*
    final sessionState = _sessionService.sessionState;
    if (sessionState == SessionState.idle) {
      if (_sessionStartTime != null) {
        debugPrint('ChargingMonitorController: ⚠️ 안전장치 - idle 상태에서 세션 시작 시간 발견, 강제 리셋 (이전: $_sessionStartTime)');
        _sessionStartTime = null;
        _stopDurationUpdateTimer();
        notifyListeners();
      }
      return;
    }
    
    final currentSessionStartTime = _sessionService.sessionStartTime;
    if (currentSessionStartTime != _sessionStartTime) {
      updateSessionStartTime();
    }
    */
  }
  
  /// 세션 시작 시간 업데이트
  /// PHASE 6-4: 완전 종료 후에는 업데이트하지 않도록 안전장치 추가
  /// PHASE 8-3: 안전장치 강화 - idle 상태에서 세션 시작 시간 리셋 보장
  void updateSessionStartTime() {
    // 분석 탭 제거로 인해 주석 처리 (backup/analysis/)
    return; // 분석 탭 제거로 인해 비활성화
    
    // 분석 탭 제거로 인해 주석 처리 (backup/analysis/)
    // 아래 코드는 모두 주석 처리됨
    /*
    try {
      final sessionState = _sessionService.sessionState;
      if (sessionState == SessionState.idle) {
        if (_sessionStartTime != null) {
          debugPrint('ChargingMonitorController: ⚠️ 안전장치 - idle 상태에서 세션 시작 시간 발견, 강제 리셋 (이전: $_sessionStartTime)');
          _sessionStartTime = null;
          _stopDurationUpdateTimer();
          notifyListeners();
        }
        return;
      }
      
      final sessionStartTime = _sessionService.sessionStartTime;
      if (_sessionStartTime != sessionStartTime) {
        if (_sessionStartTime != null && 
            sessionStartTime != null && 
            sessionStartTime.isAfter(_sessionStartTime!)) {
          final timeDiff = sessionStartTime.difference(_sessionStartTime!);
          if (timeDiff.inSeconds >= 10) {
            debugPrint('ChargingMonitorController: 새 세션 감지 (시간 차이: ${timeDiff.inSeconds}초) - 이전 시간 무시');
            _sessionStartTime = sessionStartTime;
            notifyListeners();
            _updateDurationTimerBasedOnSettings();
            return;
          }
        }
        
        _sessionStartTime = sessionStartTime;
        notifyListeners();
        _updateDurationTimerBasedOnSettings();
      }
    } catch (e) {
      debugPrint('ChargingMonitorController: 세션 시작 시간 업데이트 실패 - $e');
    }
    */
  }

  /// 네이티브에서 저장한 충전 세션 정보 복구
  /// 앱 재시작 후에도 지속 시간을 정확히 표시하기 위해 사용
  /// PHASE 9-4: ChargingSessionService의 세션 시작 시간과 동기화 우선
  Future<void> restoreSessionFromNative() async {
    // 분석 탭 제거로 인해 주석 처리 (backup/analysis/)
    // 네이티브 정보만 사용
    try {
      final sessionInfo = await NativeBatteryService.getChargingSessionInfo();
      
      if (sessionInfo == null) {
        debugPrint('ChargingMonitorController: 네이티브 세션 정보 없음');
        return;
      }
      
      debugPrint('ChargingMonitorController: 네이티브 세션 정보 복구 - $sessionInfo');
      
      // 네이티브 정보만 사용
      if (sessionInfo.isChargingActive && sessionInfo.startTime != null) {
        if (_sessionStartTime == null || 
            sessionInfo.startTime!.isBefore(_sessionStartTime!)) {
          _sessionStartTime = sessionInfo.startTime;
          debugPrint('ChargingMonitorController: 네이티브에서 세션 시작 시간 복구됨 - $_sessionStartTime');
          notifyListeners();
          _updateDurationTimerBasedOnSettings();
        }
      } else if (!sessionInfo.isChargingActive) {
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
  /// PHASE 2: ending 상태일 때도 지속 시간 타이머는 계속 동작 (재연결 시 지속 시간 표시를 위해)
  void _updateDurationTimerBasedOnSettings() {
    final displayMode = _settingsService.appSettings.chargingMonitorDisplayMode;
    // 분석 탭 제거로 인해 주석 처리 (backup/analysis/)
    // final sessionState = _sessionService.sessionState;
    
    // 세션 서비스 없이 기본 동작만 수행
    final shouldRunTimer = displayMode == ChargingMonitorDisplayMode.currentWithDuration &&
        _sessionStartTime != null;
    
    if (shouldRunTimer) {
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
  /// PHASE 5: 성능 최적화 - 불필요한 UI 업데이트 방지
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
          final currentDisplayMode = _settingsService.appSettings.chargingMonitorDisplayMode;
          // 분석 탭 제거로 인해 주석 처리 (backup/analysis/)
          // final sessionState = _sessionService.sessionState;
          // 
          // // 세션 시작 시간이 변경되었을 수 있으므로 재확인
          // final currentSessionStartTime = _sessionService.sessionStartTime;
          // final sessionTimeChanged = currentSessionStartTime != _sessionStartTime;
          // 
          // // PHASE 2: ending 상태일 때도 지속 시간은 업데이트 (재연결 시 지속 시간 표시를 위해)
          // final shouldUpdate = sessionTimeChanged ||
          //     (_sessionStartTime != null &&
          //      currentDisplayMode == ChargingMonitorDisplayMode.currentWithDuration &&
          //      (sessionState == SessionState.active || sessionState == SessionState.ending));
          
          // 세션 서비스 없이 기본 동작만 수행
          final shouldUpdate = _sessionStartTime != null &&
              currentDisplayMode == ChargingMonitorDisplayMode.currentWithDuration;
          
          if (shouldUpdate) {
            // PHASE 5: 1초마다 업데이트하므로 항상 UI 업데이트 (지속 시간이 변경되므로)
            notifyListeners();
          }
          
          // 세션이 없거나 설정이 변경되었으면 타이머 중지
          if (_sessionStartTime == null ||
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
  /// 주의: 세션 시작 시간은 스트림 리스너에서 자동으로 설정됩니다.
  /// 이 메서드는 외부에서 명시적으로 호출될 때 사용됩니다.
  void handleChargingStart() {
    // 세션 시작 시간이 없으면 현재 시간으로 설정
    if (_sessionStartTime == null) {
      _sessionStartTime = DateTime.now();
      debugPrint('ChargingMonitorController: handleChargingStart - 세션 시작 시간 설정 - $_sessionStartTime');
      notifyListeners();
      _updateDurationTimerBasedOnSettings();
    }
    
    // 실시간 업데이트 시작
    startRealTimeUpdate();
  }
  
  /// 충전 종료 처리
  /// 주의: 세션 시작 시간은 스트림 리스너에서 자동으로 리셋됩니다.
  /// 이 메서드는 외부에서 명시적으로 호출될 때 사용됩니다.
  void handleChargingEnd() {
    // 세션 시작 시간 리셋
    _sessionStartTime = null;
    debugPrint('ChargingMonitorController: handleChargingEnd - 세션 시작 시간 리셋');
    
    // 실시간 업데이트 중지
    stopRealTimeUpdate();
    
    // 마지막 충전 정보 로드
    loadLastChargingInfo();
    
    notifyListeners();
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

  /// 강제 세션 리셋 (개발자 모드용)
  /// 세션 시작 시간을 null로 설정하고 모든 타이머를 중지합니다.
  /// 새 세션이 시작되면 0분 0초부터 시작하도록 보장합니다.
  void forceResetSession() {
    debugPrint('ChargingMonitorController: ========== 강제 세션 리셋 시작 ==========');
    
    try {
      // 세션 시작 시간 강제 리셋
      final hadSessionTime = _sessionStartTime != null;
      final previousSessionStartTime = _sessionStartTime;
      _sessionStartTime = null;
      
      if (hadSessionTime) {
        debugPrint('ChargingMonitorController: ✅ 강제 리셋 - 세션 시작 시간 리셋 완료 (이전: $previousSessionStartTime → null)');
      } else {
        debugPrint('ChargingMonitorController: 강제 리셋 - 세션 시작 시간 이미 null');
      }
      
      // 지속 시간 타이머 중지
      _stopDurationUpdateTimer();
      
      // 실시간 업데이트 중지
      if (_isActive) {
        debugPrint('ChargingMonitorController: 강제 리셋 - 실시간 업데이트 중지');
        stopRealTimeUpdate();
      }
      
      // 데이터 포인트 초기화
      _dataPoints.clear();
      
      // UI 업데이트
      notifyListeners();
      
      debugPrint('ChargingMonitorController: ✅ 강제 세션 리셋 완료 - 모든 상태 초기화됨');
      debugPrint('ChargingMonitorController: ========== 강제 세션 리셋 완료 ==========');
    } catch (e, stackTrace) {
      debugPrint('ChargingMonitorController: ⚠️ 강제 세션 리셋 중 오류 - $e');
      debugPrint('스택 트레이스: $stackTrace');
      // 에러 발생 시에도 기본 정리 작업 수행
      _sessionStartTime = null;
      _stopDurationUpdateTimer();
      if (_isActive) {
        stopRealTimeUpdate();
      }
      notifyListeners();
      debugPrint('ChargingMonitorController: 에러 발생 후 기본 정리 작업 완료');
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
    
    // 배터리 스트림 구독 정리
    _batteryInfoSubscription?.cancel();
    _batteryInfoSubscription = null;
    
    // 세션 상태 스트림 구독 정리
    _sessionStateSubscription?.cancel();
    _sessionStateSubscription = null;
    
    // 타이머 정리
    _updateTimer?.cancel();
    _durationUpdateTimer?.cancel();
    
    super.dispose();
  }
}

