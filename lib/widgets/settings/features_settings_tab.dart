import 'package:flutter/material.dart';
import '../../services/settings_service.dart';
import '../../widgets/settings/settings_widgets.dart';
import '../../widgets/common/common_widgets.dart';
import 'dialogs/battery_display_settings_dialog.dart';
import 'dialogs/charging_complete_notification_dialog.dart';
import 'dialogs/charging_percent_notification_dialog.dart';
import 'dialogs/charging_monitor_display_dialog.dart';
import 'dialogs/charging_graph_theme_dialog.dart';
import 'dialogs/battery_optimization_dialog.dart';
import 'features_settings_subtitle_helper.dart';

/// 기능 설정 탭 위젯
class FeaturesSettingsTab extends StatelessWidget {
  final SettingsService settingsService;
  final bool isProUser;
  final VoidCallback onProToggle;

  const FeaturesSettingsTab({
    super.key,
    required this.settingsService,
    required this.isProUser,
    required this.onProToggle,
  });

  FeaturesSettingsSubtitleHelper get _subtitleHelper => FeaturesSettingsSubtitleHelper(settingsService);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settingsService,
      builder: (context, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // 화면 표시 설정 (배터리 정보 + 충전 모니터 통합)
              _buildFeatureSettingsCard(
                context,
                '화면 표시 설정',
                Icons.display_settings,
                '홈 화면의 배터리 정보 및 충전 모니터 표시 방식 설정',
                [
                  SettingsActionItem(
                    title: '배터리 정보 표시 방식',
                    subtitle: _subtitleHelper.getBatteryDisplaySubtitle(),
                    icon: Icons.smartphone,
                    onTap: () => BatteryDisplaySettingsDialog.show(context, settingsService),
                  ),
                  SettingsActionItem(
                    title: '충전 모니터 표시 방식',
                    subtitle: _subtitleHelper.getChargingMonitorDisplaySubtitle(),
                    icon: Icons.monitor_heart,
                    onTap: () => ChargingMonitorDisplayDialog.show(
                      context,
                      settingsService.appSettings.chargingMonitorDisplayMode,
                      (mode) => settingsService.updateChargingMonitorDisplayMode(mode),
                    ),
                  ),
                  SettingsActionItem(
                    title: '충전 그래프 테마',
                    subtitle: _subtitleHelper.getChargingGraphThemeSubtitle(),
                    icon: Icons.palette,
                    onTap: () => ChargingGraphThemeDialog.show(
                      context,
                      settingsService.appSettings.chargingGraphTheme,
                      (theme) => settingsService.updateChargingGraphTheme(theme),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // 배터리 알림 설정 (Pro 기능)
              _buildFeatureSettingsCard(
                context,
                '배터리 알림',
                Icons.notifications_active,
                '배터리 상태에 따른 알림 설정',
                [
                  SettingsSwitchItem(
                    title: '배터리 알림 활성화',
                    subtitle: '배터리 부족 시 알림 받기',
                    value: settingsService.appSettings.batteryNotificationsEnabled,
                    onChanged: settingsService.updateBatteryNotifications,
                  ),
                  SettingsActionItem(
                    title: '충전 완료 알림 설정',
                    subtitle: _subtitleHelper.getChargingCompleteNotificationSubtitle(),
                    icon: Icons.battery_charging_full,
                    onTap: () => ChargingCompleteNotificationDialog.show(context, settingsService),
                  ),
                  SettingsActionItem(
                    title: '충전 퍼센트 알림 설정',
                    subtitle: _subtitleHelper.getChargingPercentNotificationSubtitle(),
                    icon: Icons.battery_std,
                    onTap: () => ChargingPercentNotificationDialog.show(context, settingsService),
                  ),
                ],
                isProFeature: true,
                isProUser: isProUser,
              ),
              
              const SizedBox(height: 16),
              
              // Phase 4: 백그라운드 데이터 수집 설정
              _buildFeatureSettingsCard(
                context,
                '백그라운드 데이터 수집',
                Icons.cloud_download,
                '앱이 꺼져 있을 때도 충전 데이터 수집',
                [
                  SettingsSwitchItem(
                    title: '백그라운드 데이터 수집',
                    subtitle: '앱이 꺼져 있어도 충전 데이터 수집',
                    value: settingsService.appSettings.backgroundDataCollectionEnabled,
                    onChanged: settingsService.updateBackgroundDataCollection,
                  ),
                  SettingsActionItem(
                    title: '배터리 최적화 설정',
                    subtitle: _subtitleHelper.getBatteryOptimizationSubtitle(),
                    icon: Icons.battery_saver,
                    onTap: () => BatteryOptimizationDialog.show(context),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFeatureSettingsCard(
    BuildContext context,
    String title,
    IconData icon,
    String description,
    List<Widget> items, {
    bool isProFeature = false,
    bool isProUser = false,
  }) {
    return CustomCard(
      elevation: 2,
      borderRadius: BorderRadius.circular(12),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              if (isProFeature) ...[
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
            description,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          ...items,
        ],
      ),
    );
  }
}

