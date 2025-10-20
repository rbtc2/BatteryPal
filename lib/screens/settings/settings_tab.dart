import 'package:flutter/material.dart';
import '../../models/app_models.dart';
import '../../widgets/common/common_widgets.dart';
import '../../utils/dialog_utils.dart';
import '../../constants/app_constants.dart';

/// 설정 탭 화면
/// 일반 설정과 배터리 설정을 탭으로 분리
class SettingsTab extends StatefulWidget {
  final bool isProUser;
  final VoidCallback onProToggle;

  const SettingsTab({
    super.key,
    required this.isProUser,
    required this.onProToggle,
  });

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  // 앱 설정 데이터
  AppSettings _appSettings = AppSettings(
    notificationsEnabled: true,
    batteryNotificationsEnabled: true,
    darkModeEnabled: true,
    selectedLanguage: '한국어',
    powerSaveModeEnabled: false,
    autoOptimizationEnabled: true,
    batteryProtectionEnabled: true,
    batteryThreshold: 20.0,
    smartChargingEnabled: false,
    backgroundAppRestriction: false,
    lastUpdated: DateTime.now(),
  );

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('설정'),
          backgroundColor: Theme.of(context).colorScheme.surface,
          elevation: 0,
          bottom: TabBar(
            tabs: const [
              Tab(
                icon: Icon(Icons.settings),
                text: '일반',
              ),
              Tab(
                icon: Icon(Icons.battery_std),
                text: '배터리',
              ),
            ],
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            indicatorColor: Theme.of(context).colorScheme.primary,
          ),
        ),
        body: TabBarView(
          children: [
            _buildGeneralSettingsTab(),
            _buildBatterySettingsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Pro 업그레이드 카드 (무료 사용자용)
          if (!widget.isProUser) _buildProUpgradeCard(),
          
          const SizedBox(height: 24),
          
          // 기본 설정
          _buildSettingsSection('기본 설정', [
            _buildSettingsItem(
              '알림 설정',
              Icons.notifications,
              _appSettings.notificationsEnabled ? '켜짐' : '꺼짐',
              () => _toggleNotifications(),
            ),
            _buildSettingsItem(
              '테마 설정',
              Icons.dark_mode,
              _appSettings.darkModeEnabled ? '다크 모드' : '라이트 모드',
              () => _toggleTheme(),
            ),
            _buildSettingsItem(
              '언어 설정',
              Icons.language,
              _appSettings.selectedLanguage,
              () => _showLanguageDialog(),
            ),
          ]),
          
          const SizedBox(height: 24),
          
          // Pro 설정 (Pro 사용자용)
          if (widget.isProUser) _buildProSettingsSection(),
          
          const SizedBox(height: 24),
          
          // 앱 정보
          _buildSettingsSection('앱 정보', [
            _buildSettingsItem(
              '버전 정보',
              Icons.info,
              AppConstants.appVersion,
              () => DialogUtils.showDefaultAppInfoDialog(context),
            ),
            _buildSettingsItem(
              '라이선스',
              Icons.description,
              AppConstants.license,
              () => DialogUtils.showInfoDialog(
                context,
                title: '라이선스',
                content: '${AppConstants.appName}은 ${AppConstants.license} 하에 배포됩니다.',
              ),
            ),
            _buildSettingsItem(
              '개발자 정보',
              Icons.person,
              AppConstants.developerName,
              () => DialogUtils.showInfoDialog(
                context,
                title: '개발자 정보',
                content: '${AppConstants.appName}은 ${AppConstants.developerName}에서 개발되었습니다.',
              ),
            ),
          ]),
          
          const SizedBox(height: 24),
          
          // Pro 구독 관리 (Pro 사용자용)
          if (widget.isProUser) _buildProSubscriptionCard(),
        ],
      ),
    );
  }

  Widget _buildBatterySettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 배터리 관리 설정
          _buildBatteryManagementSection(),
        ],
      ),
    );
  }

  Widget _buildProUpgradeCard() {
    return CustomCard(
      elevation: 4,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    Icons.star,
                    color: Colors.amber,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Pro 업그레이드',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                '무제한 배터리 부스트와 고급 분석 기능을 사용하세요',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => DialogUtils.showSettingsProUpgradeDialog(
                        context,
                        onUpgrade: widget.onProToggle,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Pro로 업그레이드',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> items) {
    return CustomCard(
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          ...items,
        ],
      ),
    );
  }

  Widget _buildSettingsItem(String title, IconData icon, String subtitle, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _buildProSettingsSection() {
    return _buildSettingsSection('Pro 설정', [
      _buildSettingsItem(
        '자동 최적화',
        Icons.auto_awesome,
        '켜짐',
        () {},
      ),
      _buildSettingsItem(
        '고급 알림',
        Icons.notifications_active,
        '켜짐',
        () {},
      ),
      _buildSettingsItem(
        '데이터 백업',
        Icons.cloud_sync,
        '켜짐',
        () {},
      ),
      _buildSettingsItem(
        '위젯 설정',
        Icons.widgets,
        '홈 화면 위젯',
        () {},
      ),
    ]);
  }

  Widget _buildProSubscriptionCard() {
    return CustomCard(
      elevation: 2,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.star,
                color: Colors.amber,
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                'Pro 구독 관리',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            '연간 구독 (2024.12.31까지)',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '월 ${AppConstants.proMonthlyPrice.toInt()}원',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              TextButton(
                onPressed: () => DialogUtils.showSubscriptionDialog(context),
                child: const Text('관리'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _toggleNotifications() {
    setState(() {
      _appSettings = _appSettings.copyWith(
        notificationsEnabled: !_appSettings.notificationsEnabled,
        lastUpdated: DateTime.now(),
      );
    });
  }

  void _toggleTheme() {
    setState(() {
      _appSettings = _appSettings.copyWith(
        darkModeEnabled: !_appSettings.darkModeEnabled,
        lastUpdated: DateTime.now(),
      );
    });
  }

  void _showLanguageDialog() {
    DialogUtils.showLanguageSelectionDialog(
      context,
      currentLanguage: _appSettings.selectedLanguage,
      onLanguageChanged: (language) {
        setState(() {
          _appSettings = _appSettings.copyWith(
            selectedLanguage: language,
            lastUpdated: DateTime.now(),
          );
        });
      },
    );
  }

  Widget _buildBatteryManagementSection() {
    return Column(
      children: [
        // 절전 모드 설정
        _buildBatterySettingsCard(
          '절전 모드',
          Icons.power_settings_new,
          '배터리 수명을 연장하기 위한 절전 모드',
          [
            _buildSwitchItem(
              '절전 모드 활성화',
              _appSettings.powerSaveModeEnabled,
              (value) => setState(() {
                _appSettings = _appSettings.copyWith(
                  powerSaveModeEnabled: value,
                  lastUpdated: DateTime.now(),
                );
              }),
              '화면 밝기 감소, 백그라운드 앱 제한',
            ),
            _buildSwitchItem(
              '백그라운드 앱 제한',
              _appSettings.backgroundAppRestriction,
              (value) => setState(() {
                _appSettings = _appSettings.copyWith(
                  backgroundAppRestriction: value,
                  lastUpdated: DateTime.now(),
                );
              }),
              '사용하지 않는 앱의 백그라운드 활동 제한',
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // 배터리 알림 설정
        _buildBatterySettingsCard(
          '배터리 알림',
          Icons.notifications_active,
          '배터리 상태에 따른 알림 설정',
          [
            _buildSwitchItem(
              '배터리 알림 활성화',
              _appSettings.batteryNotificationsEnabled,
              (value) => setState(() {
                _appSettings = _appSettings.copyWith(
                  batteryNotificationsEnabled: value,
                  lastUpdated: DateTime.now(),
                );
              }),
              '배터리 부족 시 알림 받기',
            ),
            _buildSliderItem(
              '알림 임계값',
              _appSettings.batteryThreshold,
              (value) => setState(() {
                _appSettings = _appSettings.copyWith(
                  batteryThreshold: value,
                  lastUpdated: DateTime.now(),
                );
              }),
              '${_appSettings.batteryThreshold.toStringAsFixed(0)}%',
              '배터리가 이 수준 이하로 떨어지면 알림',
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // 자동 최적화 설정
        _buildBatterySettingsCard(
          '자동 최적화',
          Icons.auto_fix_high,
          '자동으로 배터리를 최적화하는 기능',
          [
            _buildSwitchItem(
              '자동 최적화 활성화',
              _appSettings.autoOptimizationEnabled,
              (value) => setState(() {
                _appSettings = _appSettings.copyWith(
                  autoOptimizationEnabled: value,
                  lastUpdated: DateTime.now(),
                );
              }),
              '배터리 사용량이 높은 앱 자동 제한',
            ),
            _buildSwitchItem(
              '스마트 충전',
              _appSettings.smartChargingEnabled,
              (value) => setState(() {
                _appSettings = _appSettings.copyWith(
                  smartChargingEnabled: value,
                  lastUpdated: DateTime.now(),
                );
              }),
              '배터리 건강도를 고려한 충전 관리',
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // 배터리 보호 설정
        _buildBatterySettingsCard(
          '배터리 보호',
          Icons.shield,
          '배터리 건강도를 보호하는 설정',
          [
            _buildSwitchItem(
              '배터리 보호 활성화',
              _appSettings.batteryProtectionEnabled,
              (value) => setState(() {
                _appSettings = _appSettings.copyWith(
                  batteryProtectionEnabled: value,
                  lastUpdated: DateTime.now(),
                );
              }),
              '과충전 방지 및 온도 모니터링',
            ),
            _buildActionItem(
              '배터리 보정',
              Icons.refresh,
              '배터리 수치 보정',
              () => DialogUtils.showBatteryCalibrationStartDialog(context),
            ),
            _buildActionItem(
              '배터리 진단',
              Icons.health_and_safety,
              '배터리 상태 진단',
              () => DialogUtils.showBatteryDiagnosticDialog(context),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBatterySettingsCard(String title, IconData icon, String description, List<Widget> items) {
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

  Widget _buildSwitchItem(String title, bool value, ValueChanged<bool> onChanged, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildSliderItem(String title, double value, ValueChanged<double> onChanged, String valueText, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              Text(
                valueText,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          Text(
            subtitle,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Slider(
            value: value,
            min: AppConstants.batteryThresholdMin,
            max: AppConstants.batteryThresholdMax,
            divisions: 9,
            onChanged: onChanged,
            activeColor: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem(String title, IconData icon, String subtitle, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 18,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
