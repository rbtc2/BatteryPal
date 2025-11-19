import 'package:flutter/material.dart';
import '../../services/settings_service.dart';
import '../../services/system_settings_service.dart';
import '../../services/battery_optimization_helper.dart';
import '../../services/permission_helper.dart';
import '../../widgets/settings/settings_widgets.dart';
import '../../widgets/settings/pro_settings_widgets.dart';
import '../../widgets/settings/dialogs/developer_mode_dialog.dart';
import '../../widgets/settings/dialogs/data_deletion_dialog.dart';
import '../../utils/dialog_utils.dart';
import '../../constants/app_constants.dart';

/// 일반 설정 탭 위젯
class GeneralSettingsTab extends StatelessWidget {
  final SettingsService settingsService;
  final bool isProUser;
  final VoidCallback onProToggle;

  const GeneralSettingsTab({
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
              // Pro 업그레이드 카드 (무료 사용자용)
              if (!isProUser) ProUpgradeCard(onUpgrade: onProToggle),
              
              const SizedBox(height: 24),
              
              // 기본 설정
              SettingsSection(
                title: '기본 설정',
                items: [
                  SettingsItem(
                    title: '알림 설정',
                    icon: Icons.notifications,
                    subtitle: settingsService.appSettings.notificationsEnabled ? '켜짐' : '꺼짐',
                    onTap: () => settingsService.toggleNotifications(),
                  ),
                  SettingsItem(
                    title: '테마 설정',
                    icon: Icons.dark_mode,
                    subtitle: settingsService.appSettings.darkModeEnabled ? '다크 모드' : '라이트 모드',
                    onTap: () => settingsService.toggleTheme(),
                  ),
                  SettingsItem(
                    title: '언어 설정',
                    icon: Icons.language,
                    subtitle: settingsService.appSettings.selectedLanguage,
                    onTap: () => _showLanguageDialog(context),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Pro 설정 (Pro 사용자용)
              if (isProUser) const ProSettingsSection(),
              
              const SizedBox(height: 24),
              
              // 권한 관리
              _buildPermissionsSection(context),
              
              const SizedBox(height: 24),
              
              // 개발자 모드
              SettingsSection(
                title: '개발자',
                items: [
                  SettingsItem(
                    title: '개발자 모드',
                    icon: Icons.developer_mode,
                    subtitle: '알림 테스트 및 개발 기능',
                    onTap: () => _showDeveloperModeDialog(context),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // 데이터 관리
              SettingsSection(
                title: '데이터 관리',
                items: [
                  SettingsItem(
                    title: '저장된 데이터 삭제',
                    icon: Icons.delete_outline,
                    subtitle: '충전 현황, 충전 분석 등',
                    onTap: () => _showDataDeletionDialog(context),
                  ),
                  SettingsItem(
                    title: '설정 초기화',
                    icon: Icons.restore,
                    subtitle: '모든 설정을 기본값으로 복원',
                    onTap: () => _showResetSettingsDialog(context),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // 앱 정보
              SettingsSection(
                title: '앱 정보',
                items: [
                  SettingsItem(
                    title: '버전 정보',
                    icon: Icons.info,
                    subtitle: AppConstants.appVersion,
                    onTap: () => DialogUtils.showDefaultAppInfoDialog(context),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Pro 구독 관리 (Pro 사용자용)
              if (isProUser) const ProSubscriptionCard(),
            ],
          ),
        );
      },
    );
  }

  void _showLanguageDialog(BuildContext context) {
    DialogUtils.showLanguageSelectionDialog(
      context,
      currentLanguage: settingsService.appSettings.selectedLanguage,
      onLanguageChanged: (language) {
        settingsService.updateLanguage(language);
      },
    );
  }

  void _showDeveloperModeDialog(BuildContext context) {
    DeveloperModeDialog.show(context, settingsService);
  }

  void _showDataDeletionDialog(BuildContext context) {
    DataDeletionDialog.show(context);
  }

  void _showResetSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.restore,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 8),
            const Text('설정 초기화'),
          ],
        ),
        content: const Text(
          '모든 설정을 기본값으로 복원하시겠습니까?\n\n'
          '이 작업은 되돌릴 수 없습니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              settingsService.resetToDefaults();
              Navigator.of(context).pop();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('설정이 기본값으로 복원되었습니다.'),
                    duration: const Duration(seconds: 2),
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('초기화'),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionsSection(BuildContext context) {
    return FutureBuilder<Map<String, bool>>(
      future: _checkPermissions(),
      builder: (context, snapshot) {
        final hasNotificationPermission = snapshot.data?['notification'] ?? false;
        final hasBatteryOptimization = snapshot.data?['batteryOptimization'] ?? false;
        
        return SettingsSection(
          title: '권한 관리',
          items: [
            SettingsItem(
              title: '알림 권한',
              icon: hasNotificationPermission ? Icons.notifications_active : Icons.notifications_off,
              subtitle: hasNotificationPermission 
                ? '✓ 허용됨' 
                : '⚠ 허용 필요 (앱이 꺼진 상태에서도 알림을 받으려면 필요)',
              onTap: () => _handleNotificationPermission(context),
            ),
            SettingsItem(
              title: '배터리 최적화 예외',
              icon: hasBatteryOptimization ? Icons.battery_saver : Icons.battery_alert,
              subtitle: hasBatteryOptimization 
                ? '✓ 설정됨' 
                : '⚠ 설정 필요 (앱이 꺼진 상태에서도 충전 감지하려면 필요)',
              onTap: () => _handleBatteryOptimization(context),
            ),
          ],
        );
      },
    );
  }

  Future<Map<String, bool>> _checkPermissions() async {
    final systemSettings = SystemSettingsService();
    final hasNotification = await systemSettings.hasNotificationPermission() ?? false;
    final hasBatteryOptimization = await BatteryOptimizationHelper.isIgnoringBatteryOptimizations();
    
    return {
      'notification': hasNotification,
      'batteryOptimization': hasBatteryOptimization,
    };
  }

  Future<void> _handleNotificationPermission(BuildContext context) async {
    final systemSettings = SystemSettingsService();
    final hasPermission = await systemSettings.hasNotificationPermission() ?? false;
    
    if (hasPermission) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('알림 권한이 이미 허용되어 있습니다.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }
    
    // 권한 요청
    if (!context.mounted) return;
    final granted = await PermissionHelper.requestNotificationPermission(context);
    
    if (!context.mounted) return;
    if (granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('알림 권한이 허용되었습니다.'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('알림 권한이 거부되었습니다. 설정에서 수동으로 허용해주세요.'),
          duration: Duration(seconds: 3),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _handleBatteryOptimization(BuildContext context) async {
    final isIgnoring = await BatteryOptimizationHelper.isIgnoringBatteryOptimizations();
    
    if (isIgnoring) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('배터리 최적화 예외가 이미 설정되어 있습니다.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }
    
    // 배터리 최적화 예외 요청
    if (!context.mounted) return;
    await BatteryOptimizationHelper.requestBatteryOptimizationException(context);
    
    // 사용자가 설정 화면에서 돌아온 후 상태 재확인
    if (!context.mounted) return;
    // 잠시 후 상태 재확인 (설정 화면에서 돌아올 때까지 대기)
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (!context.mounted) return;
    final newStatus = await BatteryOptimizationHelper.isIgnoringBatteryOptimizations();
    
    if (!context.mounted) return;
    if (newStatus) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('배터리 최적화 예외가 설정되었습니다.'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}
