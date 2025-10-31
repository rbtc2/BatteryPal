import 'package:flutter/material.dart';
import '../../services/settings_service.dart';
import '../../widgets/settings/settings_widgets.dart';
import '../../widgets/common/common_widgets.dart';
import '../../utils/dialog_utils.dart';

/// 배터리 설정 탭 위젯
class BatterySettingsTab extends StatelessWidget {
  final SettingsService settingsService;
  final bool isProUser;
  final VoidCallback onProToggle;

  const BatterySettingsTab({
    super.key,
    required this.settingsService,
    required this.isProUser,
    required this.onProToggle,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settingsService,
      builder: (context, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // 절전 모드 설정
              _buildBatterySettingsCard(
                context,
                '절전 모드',
                Icons.power_settings_new,
                '배터리 수명을 연장하기 위한 절전 모드',
                [
                  SettingsSwitchItem(
                    title: '절전 모드 활성화',
                    subtitle: '화면 밝기 감소, 백그라운드 앱 제한',
                    value: settingsService.appSettings.powerSaveModeEnabled,
                    onChanged: settingsService.updatePowerSaveMode,
                  ),
                  SettingsSwitchItem(
                    title: '백그라운드 앱 제한',
                    subtitle: '사용하지 않는 앱의 백그라운드 활동 제한',
                    value: settingsService.appSettings.backgroundAppRestriction,
                    onChanged: settingsService.updateBackgroundAppRestriction,
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // 배터리 알림 설정 (Pro 기능)
              _buildBatterySettingsCard(
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
                  SettingsSwitchItem(
                    title: '충전 완료 알림',
                    subtitle: '충전 완료 시 알림 받기',
                    value: settingsService.appSettings.chargingCompleteNotificationEnabled,
                    onChanged: settingsService.updateChargingCompleteNotification,
                  ),
                ],
                isProFeature: true,
                isProUser: isProUser,
              ),
              
              const SizedBox(height: 16),
              
              // 자동 최적화 설정
              _buildBatterySettingsCard(
                context,
                '자동 최적화',
                Icons.auto_fix_high,
                '자동으로 배터리를 최적화하는 기능',
                [
                  SettingsSwitchItem(
                    title: '자동 최적화 활성화',
                    subtitle: '배터리 사용량이 높은 앱 자동 제한',
                    value: settingsService.appSettings.autoOptimizationEnabled,
                    onChanged: settingsService.updateAutoOptimization,
                  ),
                  SettingsSwitchItem(
                    title: '스마트 충전',
                    subtitle: '배터리 건강도를 고려한 충전 관리',
                    value: settingsService.appSettings.smartChargingEnabled,
                    onChanged: settingsService.updateSmartCharging,
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // 배터리 보호 설정
              _buildBatterySettingsCard(
                context,
                '배터리 보호',
                Icons.shield,
                '배터리 건강도를 보호하는 설정',
                [
                  SettingsSwitchItem(
                    title: '배터리 보호 활성화',
                    subtitle: '과충전 방지 및 온도 모니터링',
                    value: settingsService.appSettings.batteryProtectionEnabled,
                    onChanged: settingsService.updateBatteryProtection,
                  ),
                  SettingsActionItem(
                    title: '배터리 보정',
                    subtitle: '배터리 수치 보정',
                    icon: Icons.refresh,
                    onTap: () => DialogUtils.showBatteryCalibrationStartDialog(context),
                  ),
                  SettingsActionItem(
                    title: '배터리 진단',
                    subtitle: '배터리 상태 진단',
                    icon: Icons.health_and_safety,
                    onTap: () => DialogUtils.showBatteryDiagnosticDialog(context),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBatterySettingsCard(
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
