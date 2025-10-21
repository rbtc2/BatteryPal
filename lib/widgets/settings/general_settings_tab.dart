import 'package:flutter/material.dart';
import '../../services/settings_service.dart';
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
}
