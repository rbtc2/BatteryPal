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
    // await로 완료될 때까지 기다려야 합니다
    _controller.restoreSessionFromNative().then((_) {
      // 현재 충전 중이면 실시간 업데이트 시작
      if (mounted && widget.batteryInfo?.isCharging == true) {
        // 세션 시작 시간이 아직 설정되지 않았으면 설정
        if (_controller.sessionStartTime == null) {
          // 네이티브에서 복구하지 못했으면 현재 시간 사용
          _controller.handleChargingStart();
        } else {
          // 네이티브에서 복구했으면 실시간 업데이트만 시작
          _controller.startRealTimeUpdate();
        }
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
  /// 주의: 스트림 리스너가 자동으로 충전 시작/종료를 감지하므로,
  /// 여기서는 UI 업데이트만 처리합니다.
  void _handleChargingStateChange(RealtimeChargingMonitor oldWidget) {
    final isCharging = widget.batteryInfo?.isCharging ?? false;

    // 스트림 리스너가 자동으로 처리하므로, 여기서는 추가 처리만 수행
    if (isCharging) {
      // 충전 중일 때는 업데이트만 처리
      _controller.handleChargingUpdate();
    }
    // 충전 시작/종료는 스트림 리스너에서 자동 처리됨
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
