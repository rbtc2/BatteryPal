import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/settings_service.dart';
import 'models/battery_display_models.dart';
import 'managers/battery_display_info_manager.dart';
import 'mixins/battery_status_animation_mixin.dart';
import 'components/circular_battery_gauge.dart';
import 'components/battery_status_info.dart';
import 'components/battery_metric_card.dart';

/// 배터리 상태 카드 위젯
/// 
/// 홈 탭에서 배터리 정보를 원형 게이지 형태로 표시하는 카드입니다.
/// 
/// 주요 기능:
/// - 배터리 레벨, 충전 전류, 온도 등의 정보를 순환 표시
/// - 충전 중일 때 회전 및 펄스 애니메이션
/// - 탭/스와이프 제스처로 정보 전환
/// - 설정에 따른 자동 순환 기능
class BatteryStatusCard extends StatefulWidget {
  /// 배터리 정보
  final BatteryInfo? batteryInfo;
  
  /// 설정 서비스
  final SettingsService? settingsService;

  const BatteryStatusCard({
    super.key,
    this.batteryInfo,
    this.settingsService,
  });

  @override
  State<BatteryStatusCard> createState() => _BatteryStatusCardState();
}

class _BatteryStatusCardState extends State<BatteryStatusCard>
    with TickerProviderStateMixin, BatteryStatusAnimationMixin {
  /// 현재 표시 중인 정보 인덱스
  int _currentDisplayIndex = 0;
  
  @override
  void initState() {
    super.initState();
    _initializeAnimation();
  }
  
  @override
  void didUpdateWidget(BatteryStatusCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _handleWidgetUpdate(oldWidget);
  }
  
  @override
  void dispose() {
    disposeBatteryStatusAnimation();
    super.dispose();
  }
  
  /// 애니메이션 초기화
  void _initializeAnimation() {
    initBatteryStatusAnimation(
      onNextDisplayInfo: _nextDisplayInfo,
      isChargingGetter: () => widget.batteryInfo?.isCharging ?? false,
      settingsGetter: () => widget.settingsService?.appSettings,
    );
  }
  
  /// 위젯 업데이트 처리
  void _handleWidgetUpdate(BatteryStatusCard oldWidget) {
    // 충전 상태 변경 처리
    final wasCharging = oldWidget.batteryInfo?.isCharging ?? false;
    final isCharging = widget.batteryInfo?.isCharging ?? false;
    
    if (isCharging != wasCharging) {
      handleChargingStateChanged(wasCharging, isCharging);
      if (!isCharging) {
        _currentDisplayIndex = 0; // 방전 시 기본 배터리 정보로 리셋
      }
    }
    
    // 설정 변경 처리
    if (widget.settingsService != oldWidget.settingsService) {
      handleSettingsChanged();
    }
  }
  
  /// 다음 정보로 전환 (자동 순환용)
  void _nextDisplayInfo() {
    _changeDisplayIndex(1, shouldPauseAutoCycle: true);
  }
  
  /// 표시 정보 전환
  /// 
  /// [increment] 전환 방향 (1: 다음, -1: 이전)
  /// [shouldPauseAutoCycle] 자동 순환 일시정지 여부
  void _changeDisplayIndex(int increment, {bool shouldPauseAutoCycle = false}) {
    final manager = _getDisplayInfoManager();
    
    setState(() {
      final availableInfoTypes = manager.getAvailableInfoTypes(
        widget.batteryInfo?.isCharging ?? false,
      );
      if (availableInfoTypes.isNotEmpty) {
        if (increment > 0) {
          _currentDisplayIndex = (_currentDisplayIndex + 1) % availableInfoTypes.length;
        } else {
          _currentDisplayIndex = (_currentDisplayIndex - 1 + availableInfoTypes.length) % availableInfoTypes.length;
        }
      }
    });
    
    // 자동 순환 일시정지 처리
    if (shouldPauseAutoCycle && isAutoCycleEnabled) {
      pauseAutoCycle();
    }
  }
  
  /// DisplayInfoManager 인스턴스 생성
  BatteryDisplayInfoManager _getDisplayInfoManager() {
    return BatteryDisplayInfoManager(
      batteryInfo: widget.batteryInfo,
      settings: widget.settingsService?.appSettings,
    );
  }
  
  /// 현재 표시할 정보 가져오기
  DisplayInfo _getCurrentDisplayInfo() {
    final manager = _getDisplayInfoManager();
    final availableInfoTypes = manager.getAvailableInfoTypes(
      widget.batteryInfo?.isCharging ?? false,
    );
    
    return manager.getCurrentDisplayInfo(_currentDisplayIndex, availableInfoTypes);
  }
  
  /// 탭 제스처가 활성화되어 있는지 확인
  bool _isTapToSwitchEnabled() {
    final settings = widget.settingsService?.appSettings;
    return settings?.enableTapToSwitch == true;
  }
  
  /// 스와이프 제스처가 활성화되어 있는지 확인
  bool _isSwipeToSwitchEnabled() {
    final settings = widget.settingsService?.appSettings;
    return settings?.enableSwipeToSwitch == true;
  }

  @override
  Widget build(BuildContext context) {
    final level = widget.batteryInfo?.level ?? 0;
    final isCharging = widget.batteryInfo?.isCharging ?? false;
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMainSection(context, level, isCharging, theme),
          const SizedBox(height: 20),
          _buildMetricsSection(context),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
  
  /// 메인 영역 빌드 (게이지 + 상태 정보)
  Widget _buildMainSection(
    BuildContext context,
    double level,
    bool isCharging,
    ThemeData theme,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: AspectRatio(
              aspectRatio: 1,
              child: CircularBatteryGauge(
                level: level,
                isCharging: isCharging,
                displayInfo: _getCurrentDisplayInfo(),
                cycleController: cycleController,
                rotationController: rotationController,
                pulseController: pulseController,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                onTap: _isTapToSwitchEnabled() ? () => _changeDisplayIndex(1) : null,
                onSwipeLeft: _isSwipeToSwitchEnabled() ? () => _changeDisplayIndex(1) : null,
                onSwipeRight: _isSwipeToSwitchEnabled() ? () => _changeDisplayIndex(-1) : null,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 1,
            child: BatteryStatusInfo(isCharging: isCharging),
          ),
        ],
      ),
    );
  }
  
  /// 메트릭 영역 빌드 (온도/전압)
  Widget _buildMetricsSection(BuildContext context) {
    final manager = _getDisplayInfoManager();
    final batteryInfo = widget.batteryInfo;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: BatteryMetricCard(
              icon: '🌡️',
              label: '온도',
              value: batteryInfo?.formattedTemperature ?? '--°C',
              color: manager.getTemperatureColor(batteryInfo?.temperature ?? 0),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: BatteryMetricCard(
              icon: '⚡',
              label: '전압',
              value: batteryInfo?.formattedVoltage ?? '--mV',
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }
}
