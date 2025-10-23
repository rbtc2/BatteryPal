import 'package:flutter/material.dart';
import '../../services/settings_service.dart';
import '../../models/app_models.dart';
import '../../widgets/settings/settings_widgets.dart';
import '../../widgets/settings/pro_settings_widgets.dart';
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
              
              // 화면 표시 설정
              SettingsSection(
                title: '화면 표시',
                items: [
                  SettingsItem(
                    title: '배터리 정보 표시 방식',
                    icon: Icons.smartphone,
                    subtitle: '자동 순환 및 표시 옵션',
                    onTap: () => _showBatteryDisplaySettingsDialog(context),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Pro 설정 (Pro 사용자용)
              if (isProUser) const ProSettingsSection(),
              
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
                  SettingsItem(
                    title: '라이선스',
                    icon: Icons.description,
                    subtitle: AppConstants.license,
                    onTap: () => DialogUtils.showInfoDialog(
                      context,
                      title: '라이선스',
                      content: '${AppConstants.appName}은 ${AppConstants.license} 하에 배포됩니다.',
                    ),
                  ),
                  SettingsItem(
                    title: '개발자 정보',
                    icon: Icons.person,
                    subtitle: AppConstants.developerName,
                    onTap: () => DialogUtils.showInfoDialog(
                      context,
                      title: '개발자 정보',
                      content: '${AppConstants.appName}은 ${AppConstants.developerName}에서 개발되었습니다.',
                    ),
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

  void _showBatteryDisplaySettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('배터리 정보 표시 방식'),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                // 자동 순환 속도
                Text(
                  '자동 순환 속도',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                RadioGroup<BatteryDisplayCycleSpeed>(
                  groupValue: settingsService.appSettings.batteryDisplayCycleSpeed,
                  onChanged: (value) {
                    if (value != null) {
                      settingsService.updateBatteryDisplayCycleSpeed(value);
                      setState(() {}); // 다이얼로그 상태 업데이트
                    }
                  },
                  child: Column(
                    children: BatteryDisplayCycleSpeed.values.map((speed) => 
                      RadioListTile<BatteryDisplayCycleSpeed>(
                        title: Text(speed.displayName),
                        subtitle: speed == BatteryDisplayCycleSpeed.off 
                          ? const Text('자동 순환 비활성화')
                          : Text('${speed.durationSeconds}초마다 전환'),
                        value: speed,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ).toList(),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // 표시할 정보 선택
                Text(
                  '표시할 정보 선택',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  title: Text(
                    '충전 전류 표시',
                    style: settingsService.appSettings.batteryDisplayCycleSpeed == BatteryDisplayCycleSpeed.off
                      ? TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                        )
                      : null,
                  ),
                  subtitle: Text(
                    '충전 중일 때 전류 정보 표시',
                    style: settingsService.appSettings.batteryDisplayCycleSpeed == BatteryDisplayCycleSpeed.off
                      ? TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                        )
                      : null,
                  ),
                  value: settingsService.appSettings.showChargingCurrent,
                  onChanged: settingsService.appSettings.batteryDisplayCycleSpeed == BatteryDisplayCycleSpeed.off 
                    ? null 
                    : (value) {
                        settingsService.updateShowChargingCurrent(value ?? false);
                        setState(() {}); // 다이얼로그 상태 업데이트
                      },
                  contentPadding: EdgeInsets.zero,
                ),
                CheckboxListTile(
                  title: Text(
                    '배터리 퍼센트 표시',
                    style: settingsService.appSettings.batteryDisplayCycleSpeed == BatteryDisplayCycleSpeed.off
                      ? TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                        )
                      : null,
                  ),
                  subtitle: Text(
                    '배터리 잔량 퍼센트 표시',
                    style: settingsService.appSettings.batteryDisplayCycleSpeed == BatteryDisplayCycleSpeed.off
                      ? TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                        )
                      : null,
                  ),
                  value: settingsService.appSettings.showBatteryPercentage,
                  onChanged: settingsService.appSettings.batteryDisplayCycleSpeed == BatteryDisplayCycleSpeed.off 
                    ? null 
                    : (value) {
                        settingsService.updateShowBatteryPercentage(value ?? false);
                        setState(() {}); // 다이얼로그 상태 업데이트
                      },
                  contentPadding: EdgeInsets.zero,
                ),
                
                const SizedBox(height: 16),
                
                // 제스처 설정
                Text(
                  '제스처 설정',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  title: Text(
                    '탭으로 전환',
                    style: settingsService.appSettings.batteryDisplayCycleSpeed == BatteryDisplayCycleSpeed.off
                      ? TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                        )
                      : null,
                  ),
                  subtitle: Text(
                    '화면을 탭하여 정보 전환',
                    style: settingsService.appSettings.batteryDisplayCycleSpeed == BatteryDisplayCycleSpeed.off
                      ? TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                        )
                      : null,
                  ),
                  value: settingsService.appSettings.enableTapToSwitch,
                  onChanged: settingsService.appSettings.batteryDisplayCycleSpeed == BatteryDisplayCycleSpeed.off 
                    ? null 
                    : (value) {
                        settingsService.updateEnableTapToSwitch(value ?? false);
                        setState(() {}); // 다이얼로그 상태 업데이트
                      },
                  contentPadding: EdgeInsets.zero,
                ),
                CheckboxListTile(
                  title: Text(
                    '스와이프로 전환',
                    style: settingsService.appSettings.batteryDisplayCycleSpeed == BatteryDisplayCycleSpeed.off
                      ? TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                        )
                      : null,
                  ),
                  subtitle: Text(
                    '좌우 스와이프로 정보 전환',
                    style: settingsService.appSettings.batteryDisplayCycleSpeed == BatteryDisplayCycleSpeed.off
                      ? TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                        )
                      : null,
                  ),
                  value: settingsService.appSettings.enableSwipeToSwitch,
                  onChanged: settingsService.appSettings.batteryDisplayCycleSpeed == BatteryDisplayCycleSpeed.off 
                    ? null 
                    : (value) {
                        settingsService.updateEnableSwipeToSwitch(value ?? false);
                        setState(() {}); // 다이얼로그 상태 업데이트
                      },
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
      ),
    );
  }
}
