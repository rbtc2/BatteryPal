import 'package:flutter/material.dart';
import 'dart:async';
import '../../services/settings_service.dart';
import '../../services/battery_service.dart';
import '../../widgets/home/controllers/charging_monitor_controller.dart';
import '../../widgets/settings/dialogs/charging_complete_notification_dialog.dart';
import '../../widgets/settings/dialogs/charging_percent_notification_dialog.dart';
import '../../models/models.dart';
import '../../utils/charging_graph_theme_colors.dart';

/// Features 탭
/// 충전 모니터 및 배터리 알림 기능을 주력 기능으로 제시
class FeaturesTab extends StatefulWidget {
  final bool isProUser;
  final VoidCallback onProToggle;

  const FeaturesTab({
    super.key,
    required this.isProUser,
    required this.onProToggle,
  });

  @override
  State<FeaturesTab> createState() => _FeaturesTabState();
}

class _FeaturesTabState extends State<FeaturesTab> {
  final SettingsService _settingsService = SettingsService();
  final BatteryService _batteryService = BatteryService();
  final ChargingMonitorController _monitorController = ChargingMonitorController();
  
  StreamSubscription<BatteryInfo>? _batteryInfoSubscription;
  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    _monitorController.addListener(_onMonitorControllerChanged);
    _setupBatteryStreamListener();
    _startUpdateTimer();
  }

  @override
  void dispose() {
    _batteryInfoSubscription?.cancel();
    _updateTimer?.cancel();
    _monitorController.removeListener(_onMonitorControllerChanged);
    _monitorController.dispose();
    super.dispose();
  }

  void _onMonitorControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _setupBatteryStreamListener() {
    _batteryInfoSubscription?.cancel();
    _batteryInfoSubscription = _batteryService.batteryInfoStream.listen((batteryInfo) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _startUpdateTimer() {
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('기능'),
        elevation: 0,
      ),
      body: ListenableBuilder(
        listenable: _settingsService,
        builder: (context, child) {
          return ListenableBuilder(
            listenable: _monitorController,
            builder: (context, child) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 충전 모니터 설정 섹션
                    _buildChargingMonitorSection(context),
                    
                    const SizedBox(height: 24),
                    
                    // 배터리 알림 설정 섹션
                    _buildBatteryNotificationSection(context),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// 충전 모니터 설정 섹션
  Widget _buildChargingMonitorSection(BuildContext context) {
    final displayMode = _settingsService.appSettings.chargingMonitorDisplayMode;
    final graphTheme = _settingsService.appSettings.chargingGraphTheme;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.monitor_heart,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '충전 모니터',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '실시간 충전 상태 모니터링',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // 실시간 미리보기
            _buildChargingMonitorPreview(context, displayMode, graphTheme),
            
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            
            // 표시 방식 설정 (인라인 선택)
            _buildDisplayModeSelector(context, displayMode),
            
            const SizedBox(height: 20),
            
            // 그래프 테마 설정 (시각적 미리보기)
            _buildGraphThemeSelector(context, graphTheme),
          ],
        ),
      ),
    );
  }

  /// 충전 모니터 실시간 미리보기
  Widget _buildChargingMonitorPreview(
    BuildContext context,
    ChargingMonitorDisplayMode displayMode,
    ChargingGraphTheme graphTheme,
  ) {
    final lineColor = ChargingGraphThemeColors.getGraphColor(graphTheme);
    final backgroundColor = ChargingGraphThemeColors.getBackgroundColor(graphTheme);
    final batteryInfo = _batteryService.currentBatteryInfo;
    final isCharging = batteryInfo?.isCharging ?? false;
    final currentMa = batteryInfo?.chargingCurrent ?? 0;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '실시간 미리보기',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              if (isCharging)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.bolt,
                        size: 12,
                        color: Colors.green.shade700,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '충전 중',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '대기 중',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          
          // 충전 전류 표시
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '충전 전류',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${currentMa}mA',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: lineColor,
                    ),
                  ),
                ],
              ),
              
              // 지속 시간 표시 (표시 방식에 따라)
              if (displayMode == ChargingMonitorDisplayMode.currentWithDuration)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '지속 시간',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDuration(_monitorController.calculateElapsedDuration()),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // 그래프 미리보기 (간단한 바)
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: backgroundColor.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: (currentMa / 3000).clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: lineColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 배터리 알림 설정 섹션
  Widget _buildBatteryNotificationSection(BuildContext context) {
    final settings = _settingsService.appSettings;
    final isNotificationsEnabled = settings.batteryNotificationsEnabled;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.notifications_active,
                    color: Theme.of(context).colorScheme.secondary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            '배터리 알림',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (!widget.isProUser) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.amber.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: Colors.amber.withValues(alpha: 0.5),
                                  width: 1,
                                ),
                              ),
                              child: const Text(
                                'Pro',
                                style: TextStyle(
                                  color: Colors.amber,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '스마트 배터리 알림 관리',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // 알림 활성화 스위치
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '배터리 알림 활성화',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '모든 배터리 알림 기능 사용',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: isNotificationsEnabled,
                    onChanged: widget.isProUser
                        ? (value) {
                            _settingsService.updateBatteryNotifications(value);
                          }
                        : null,
                  ),
                ],
              ),
            ),
            
            if (!widget.isProUser) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.amber.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Colors.amber.shade700,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Pro 기능입니다. 업그레이드하여 모든 알림 기능을 사용하세요.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.amber.shade700,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: widget.onProToggle,
                      child: const Text('업그레이드'),
                    ),
                  ],
                ),
              ),
            ],
            
            if (isNotificationsEnabled && widget.isProUser) ...[
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              
              // 알림 상태 요약
              _buildNotificationStatusSummary(context, settings),
              
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              
              // 충전 완료 알림 설정
              _buildSettingItem(
                context,
                icon: Icons.battery_charging_full,
                title: '충전 완료 알림',
                subtitle: _getChargingCompleteStatus(settings),
                onTap: () => ChargingCompleteNotificationDialog.show(context, _settingsService),
              ),
              
              const SizedBox(height: 12),
              
              // 충전 퍼센트 알림 설정
              _buildSettingItem(
                context,
                icon: Icons.battery_std,
                title: '충전 퍼센트 알림',
                subtitle: _getChargingPercentStatus(settings),
                onTap: () => ChargingPercentNotificationDialog.show(context, _settingsService),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 알림 상태 요약
  Widget _buildNotificationStatusSummary(BuildContext context, AppSettings settings) {
    final chargingCompleteEnabled = settings.chargingCompleteNotificationEnabled;
    final overchargeProtectionEnabled = settings.overchargeProtectionEnabled;
    final chargingPercentEnabled = settings.chargingPercentNotificationEnabled;
    
    int activeCount = 0;
    if (chargingCompleteEnabled) activeCount++;
    if (overchargeProtectionEnabled) activeCount++;
    if (chargingPercentEnabled) activeCount++;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                '알림 상태 요약',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatusItem(
                context,
                '활성 알림',
                '$activeCount개',
                Colors.green,
              ),
              const SizedBox(width: 16),
              _buildStatusItem(
                context,
                '비활성',
                '${3 - activeCount}개',
                Colors.grey,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem(BuildContext context, String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 설정 항목 위젯
  Widget _buildSettingItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  // 헬퍼 메서드들

  String _getChargingCompleteStatus(AppSettings settings) {
    if (!settings.chargingCompleteNotificationEnabled) {
      return '비활성화됨';
    }
    
    final parts = <String>[];
    if (settings.chargingCompleteNotifyOnFastCharging) {
      parts.add('고속 충전');
    }
    if (settings.chargingCompleteNotifyOnNormalCharging) {
      parts.add('일반 충전');
    }
    
    if (parts.isEmpty) {
      return '활성화됨 (타입 미선택)';
    }
    
    String result = parts.join(', ');
    if (settings.overchargeProtectionEnabled) {
      result += ' • 과충전 방지';
    }
    
    return result;
  }

  String _getChargingPercentStatus(AppSettings settings) {
    if (!settings.chargingPercentNotificationEnabled) {
      return '비활성화됨';
    }
    
    final thresholds = settings.chargingPercentThresholds;
    if (thresholds.isEmpty) {
      return '활성화됨 (퍼센트 미설정)';
    }
    
    return '${thresholds.length}개 퍼센트 설정됨';
  }

  /// 표시 방식 선택 위젯 (인라인)
  Widget _buildDisplayModeSelector(
    BuildContext context,
    ChargingMonitorDisplayMode currentMode,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.display_settings,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            const Text(
              '표시 방식',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SegmentedButton<ChargingMonitorDisplayMode>(
          segments: const [
            ButtonSegment<ChargingMonitorDisplayMode>(
              value: ChargingMonitorDisplayMode.currentOnly,
              label: Text('충전 속도만'),
              icon: Icon(Icons.speed, size: 18),
            ),
            ButtonSegment<ChargingMonitorDisplayMode>(
              value: ChargingMonitorDisplayMode.currentWithDuration,
              label: Text('속도 + 시간'),
              icon: Icon(Icons.access_time, size: 18),
            ),
          ],
          selected: {currentMode},
          onSelectionChanged: (Set<ChargingMonitorDisplayMode> newSelection) {
            if (newSelection.isNotEmpty) {
              _settingsService.updateChargingMonitorDisplayMode(newSelection.first);
            }
          },
          style: SegmentedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _getDisplayModeDescription(currentMode),
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  /// 그래프 테마 선택 위젯 (시각적 미리보기)
  Widget _buildGraphThemeSelector(
    BuildContext context,
    ChargingGraphTheme currentTheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.palette,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            const Text(
              '그래프 테마',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // 테마 미리보기 그리드
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.5,
          ),
          itemCount: ChargingGraphTheme.values.length,
          itemBuilder: (context, index) {
            final theme = ChargingGraphTheme.values[index];
            final isSelected = theme == currentTheme;
            final themeColor = ChargingGraphThemeColors.getGraphColor(theme);
            
            return InkWell(
              onTap: () {
                _settingsService.updateChargingGraphTheme(theme);
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? themeColor.withValues(alpha: 0.1)
                      : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? themeColor
                        : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    // 색상 미리보기
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: themeColor,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: themeColor.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _getGraphThemeName(theme),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              color: isSelected
                                  ? themeColor
                                  : Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _getGraphThemeDescription(theme),
                            style: TextStyle(
                              fontSize: 10,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check_circle,
                        size: 20,
                        color: themeColor,
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  String _getDisplayModeDescription(ChargingMonitorDisplayMode mode) {
    switch (mode) {
      case ChargingMonitorDisplayMode.currentOnly:
        return '현재 충전 전류만 실시간으로 표시합니다.';
      case ChargingMonitorDisplayMode.currentWithDuration:
        return '충전 전류와 함께 이 세션의 충전 지속 시간을 표시합니다.';
    }
  }

  String _getGraphThemeName(ChargingGraphTheme theme) {
    switch (theme) {
      case ChargingGraphTheme.ecg:
        return '심전도';
      case ChargingGraphTheme.wave:
        return '파도/웨이브';
      case ChargingGraphTheme.spectrum:
        return '스펙트럼';
      case ChargingGraphTheme.aurora:
        return '오로라';
    }
  }

  String _getGraphThemeDescription(ChargingGraphTheme theme) {
    switch (theme) {
      case ChargingGraphTheme.ecg:
        return '심전도 스타일';
      case ChargingGraphTheme.wave:
        return '파도 애니메이션';
      case ChargingGraphTheme.spectrum:
        return '스펙트럼 분석기';
      case ChargingGraphTheme.aurora:
        return '북극광 스타일';
    }
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) {
      return '0분 0초';
    }
    
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    
    if (minutes > 0) {
      return '$minutes분 $seconds초';
    } else {
      return '$seconds초';
    }
  }
}

