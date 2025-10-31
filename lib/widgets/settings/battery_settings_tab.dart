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
                  SettingsActionItem(
                    title: '충전 완료 알림 설정',
                    subtitle: _getChargingCompleteNotificationSubtitle(),
                    icon: Icons.battery_charging_full,
                    onTap: () => _showChargingCompleteNotificationDialog(context),
                  ),
                  SettingsActionItem(
                    title: '충전 퍼센트 알림 설정',
                    subtitle: _getChargingPercentNotificationSubtitle(),
                    icon: Icons.battery_std,
                    onTap: () => _showChargingPercentNotificationDialog(context),
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

  String _getChargingCompleteNotificationSubtitle() {
    final enabled = settingsService.appSettings.chargingCompleteNotificationEnabled;
    if (!enabled) return '비활성화';
    
    final fast = settingsService.appSettings.chargingCompleteNotifyOnFastCharging;
    final normal = settingsService.appSettings.chargingCompleteNotifyOnNormalCharging;
    
    if (fast && normal) return '모든 충전 타입';
    if (fast) return '고속 충전만';
    if (normal) return '일반 충전만';
    return '설정 필요';
  }

  String _getChargingPercentNotificationSubtitle() {
    final enabled = settingsService.appSettings.chargingPercentNotificationEnabled;
    if (!enabled) return '비활성화';
    
    final thresholds = settingsService.appSettings.chargingPercentThresholds;
    if (thresholds.isEmpty) return '알림 퍼센트 없음';
    if (thresholds.length == 1) return '${thresholds.first.toInt()}% 알림';
    return '${thresholds.length}개 퍼센트 알림';
  }

  void _showChargingCompleteNotificationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.battery_charging_full),
              SizedBox(width: 8),
              Text('충전 완료 알림 설정'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 활성화 스위치
                SwitchListTile(
                  title: const Text('충전 완료 알림 활성화'),
                  subtitle: const Text('100% 충전 완료 시 알림 받기'),
                  value: settingsService.appSettings.chargingCompleteNotificationEnabled,
                  onChanged: (value) {
                    settingsService.updateChargingCompleteNotification(value);
                    setState(() {});
                  },
                  contentPadding: EdgeInsets.zero,
                ),
                
                const SizedBox(height: 16),
                
                // 충전 타입 필터 (활성화 시에만 표시)
                if (settingsService.appSettings.chargingCompleteNotificationEnabled) ...[
                  const Text(
                    '충전 타입 선택',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    title: const Text('고속 충전 (AC)'),
                    subtitle: const Text('AC 충전 시에만 알림 받기'),
                    value: settingsService.appSettings.chargingCompleteNotifyOnFastCharging,
                    onChanged: (value) {
                      settingsService.updateChargingCompleteNotifyOnFastCharging(value ?? false);
                      setState(() {});
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                  CheckboxListTile(
                    title: const Text('일반 충전 (USB/Wireless)'),
                    subtitle: const Text('USB 또는 무선 충전 시에만 알림 받기'),
                    value: settingsService.appSettings.chargingCompleteNotifyOnNormalCharging,
                    onChanged: (value) {
                      settingsService.updateChargingCompleteNotifyOnNormalCharging(value ?? false);
                      setState(() {});
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                  // 둘 다 체크되지 않은 경우 안내
                  if (!settingsService.appSettings.chargingCompleteNotifyOnFastCharging &&
                      !settingsService.appSettings.chargingCompleteNotifyOnNormalCharging)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '최소 하나의 충전 타입을 선택해야 합니다.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ],
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

  void _showChargingPercentNotificationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.battery_std),
              SizedBox(width: 8),
              Text('충전 퍼센트 알림 설정'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 활성화 스위치
                SwitchListTile(
                  title: const Text('충전 퍼센트 알림 활성화'),
                  subtitle: const Text('설정한 퍼센트 도달 시 알림 받기'),
                  value: settingsService.appSettings.chargingPercentNotificationEnabled,
                  onChanged: (value) {
                    settingsService.updateChargingPercentNotification(value);
                    setState(() {});
                  },
                  contentPadding: EdgeInsets.zero,
                ),
                
                const SizedBox(height: 16),
                
                // 알림 받을 퍼센트 설정 (활성화 시에만 표시)
                if (settingsService.appSettings.chargingPercentNotificationEnabled) ...[
                  const Text(
                    '알림 받을 퍼센트',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // 기본 퍼센트 옵션 (70, 80, 90, 100)
                  ...([70.0, 80.0, 90.0, 100.0].map((percent) {
                    final isSelected = settingsService.appSettings.chargingPercentThresholds.contains(percent);
                    return CheckboxListTile(
                      title: Text('${percent.toInt()}%'),
                      subtitle: Text('${percent.toInt()}% 충전 시 알림 받기'),
                      value: isSelected,
                      onChanged: (value) {
                        if (value == true) {
                          settingsService.addChargingPercentThreshold(percent);
                        } else {
                          settingsService.removeChargingPercentThreshold(percent);
                        }
                        setState(() {});
                      },
                      contentPadding: EdgeInsets.zero,
                    );
                  })),
                  
                  const SizedBox(height: 8),
                  
                  // 커스텀 퍼센트 추가 버튼
                  OutlinedButton.icon(
                    onPressed: () => _showAddCustomPercentDialog(context, setState),
                    icon: const Icon(Icons.add),
                    label: const Text('커스텀 퍼센트 추가'),
                  ),
                  
                  // 선택된 퍼센트 목록 표시
                  if (settingsService.appSettings.chargingPercentThresholds.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      '선택된 퍼센트',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: settingsService.appSettings.chargingPercentThresholds.map((percent) {
                        return Chip(
                          label: Text('${percent.toInt()}%'),
                          onDeleted: () {
                            settingsService.removeChargingPercentThreshold(percent);
                            setState(() {});
                          },
                        );
                      }).toList(),
                    ),
                  ],
                  
                  const SizedBox(height: 16),
                  
                  // 충전 타입 필터 (선택사항)
                  const Text(
                    '충전 타입 필터 (선택사항)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    title: const Text('고속 충전 시에만 알림'),
                    subtitle: const Text('AC 충전 시에만 알림 받기'),
                    value: settingsService.appSettings.chargingPercentNotifyOnFastCharging,
                    onChanged: (value) {
                      settingsService.updateChargingPercentNotifyOnFastCharging(value ?? false);
                      setState(() {});
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                  CheckboxListTile(
                    title: const Text('일반 충전 시에만 알림'),
                    subtitle: const Text('USB/Wireless 충전 시에만 알림 받기'),
                    value: settingsService.appSettings.chargingPercentNotifyOnNormalCharging,
                    onChanged: (value) {
                      settingsService.updateChargingPercentNotifyOnNormalCharging(value ?? false);
                      setState(() {});
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ],
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

  void _showAddCustomPercentDialog(BuildContext context, StateSetter setState) {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('커스텀 퍼센트 추가'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '퍼센트 (10-100)',
                hintText: '예: 75',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              final percent = double.tryParse(controller.text);
              if (percent != null && percent >= 10 && percent <= 100) {
                settingsService.addChargingPercentThreshold(percent);
                Navigator.of(context).pop();
                setState(() {}); // 외부 다이얼로그 상태 업데이트
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('10-100 사이의 숫자를 입력해주세요.'),
                  ),
                );
              }
            },
            child: const Text('추가'),
          ),
        ],
      ),
    );
  }
}
