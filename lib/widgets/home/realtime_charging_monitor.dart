import 'package:flutter/material.dart';
import '../../services/last_charging_info_service.dart';
import '../../services/settings_service.dart';
import '../../models/models.dart';
import 'components/last_charging_info_view.dart';
import 'components/realtime_charging_view.dart';
import 'controllers/charging_monitor_controller.dart';

/// 실시간 충전 모니터 위젯
/// 충전 중일 때 심전도 그래프처럼 충전 속도를 실시간으로 표시
class RealtimeChargingMonitor extends StatefulWidget {
  final BatteryInfo? batteryInfo;

  const RealtimeChargingMonitor({
    super.key,
    this.batteryInfo,
  });

  @override
  State<RealtimeChargingMonitor> createState() => _RealtimeChargingMonitorState();
}

class _RealtimeChargingMonitorState extends State<RealtimeChargingMonitor> {
  // ==================== 상수 ====================
  
  /// 그래프 높이
  static const double _graphHeight = 180.0;
  
  /// 충전 정보 행 높이
  static const double _chargingInfoRowHeight = 60.0;
  
  // ==================== 컨트롤러 및 서비스 ====================
  
  late final ChargingMonitorController _controller;
  final LastChargingInfoService _lastChargingInfoService = LastChargingInfoService();
  final SettingsService _settingsService = SettingsService();

  @override
  void initState() {
    super.initState();
    _controller = ChargingMonitorController();
    _controller.addListener(_onControllerChanged);
    
    // 네이티브에서 저장한 충전 세션 정보 복구 (앱 재시작 후 지속 시간 복구)
    _controller.restoreSessionFromNative().then((_) {
      // 충전 중일 때만 모니터링 시작
      if (mounted && widget.batteryInfo?.isCharging == true) {
        _controller.handleChargingStart();
        
        // 앱 재시작 후 충전 중인 경우를 대비해 세션 시작 시간 재확인
        // (세션이 나중에 시작될 수 있으므로)
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted && widget.batteryInfo?.isCharging == true) {
            _controller.checkAndUpdateSessionStartTime();
            // 네이티브 세션 정보도 다시 확인 (동기화)
            _controller.restoreSessionFromNative();
          }
        });
      }
    });
    
    // 마지막 충전 정보 로드
    _controller.loadLastChargingInfo();
  }
  
  /// 컨트롤러 상태 변경 핸들러
  void _onControllerChanged() {
    if (mounted) {
      setState(() {
        // 컨트롤러의 상태 변경을 UI에 반영
      });
    }
  }

  @override
  void didUpdateWidget(RealtimeChargingMonitor oldWidget) {
    super.didUpdateWidget(oldWidget);
    _handleChargingStateChange(oldWidget);
  }
  
  /// 충전 상태 변화 처리
  void _handleChargingStateChange(RealtimeChargingMonitor oldWidget) {
    final wasCharging = oldWidget.batteryInfo?.isCharging ?? false;
    final isCharging = widget.batteryInfo?.isCharging ?? false;

    if (!wasCharging && isCharging) {
      // 충전 시작 시 네이티브 세션 정보 복구 후 처리
      _controller.restoreSessionFromNative().then((_) {
        if (mounted) {
          _controller.handleChargingStart();
        }
      });
    } else if (wasCharging && !isCharging) {
      _controller.handleChargingEnd();
    } else if (isCharging) {
      _controller.handleChargingUpdate();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _settingsService,
      builder: (context, child) {
        return ListenableBuilder(
          listenable: _controller,
          builder: (context, child) {
            return _buildChargingMonitor(context);
          },
        );
      },
    );
  }

  /// 충전 모니터 UI 빌드
  Widget _buildChargingMonitor(BuildContext context) {
    final isCharging = widget.batteryInfo?.isCharging ?? false;
    
    if (!isCharging) {
      return LastChargingInfoView(
        lastChargingInfo: _controller.lastChargingInfo,
        lastChargingInfoService: _lastChargingInfoService,
      );
    } else {
      final current = widget.batteryInfo?.chargingCurrent ?? 0;
      final currentAbs = current.abs();
      final displayMode = _settingsService.appSettings.chargingMonitorDisplayMode;
      final elapsedDuration = _controller.calculateElapsedDuration();
      
      // 데이터 포인트에서 마지막 값 또는 현재 값 사용
      final dataPoints = _controller.dataPoints;
      final currentValue = dataPoints.isNotEmpty 
          ? dataPoints.last.toInt() 
          : currentAbs;
      
      return RealtimeChargingView(
        dataPoints: dataPoints,
        currentValue: currentValue,
        displayMode: displayMode,
        elapsedDuration: elapsedDuration,
        graphHeight: _graphHeight,
        infoRowHeight: _chargingInfoRowHeight,
      );
    }
  }

  @override
  void dispose() {
    // 컨트롤러 리스너 제거
    _controller.removeListener(_onControllerChanged);
    // 컨트롤러 dispose (타이머 정리 포함)
    _controller.dispose();
    super.dispose();
  }
}
