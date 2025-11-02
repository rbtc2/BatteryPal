import 'package:flutter/material.dart';
import '../../services/settings_service.dart';
import '../../models/app_models.dart';
import '../../widgets/settings/settings_widgets.dart';
import '../../widgets/settings/pro_settings_widgets.dart';
import '../../utils/dialog_utils.dart';
import '../../constants/app_constants.dart';
import '../../services/notification_service.dart';

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
                // 자동 순환
                Text(
                  '자동 순환',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('자동 순환 활성화'),
                  subtitle: const Text('배터리 정보를 자동으로 전환'),
                  value: settingsService.appSettings.batteryDisplayCycleSpeed != BatteryDisplayCycleSpeed.off,
                  onChanged: (enabled) {
                    if (enabled) {
                      // 켜기를 선택하면 기본값(보통) 적용
                      settingsService.updateBatteryDisplayCycleSpeed(BatteryDisplayCycleSpeed.normal);
                    } else {
                      settingsService.updateBatteryDisplayCycleSpeed(BatteryDisplayCycleSpeed.off);
                    }
                    setState(() {}); // 다이얼로그 상태 업데이트
                  },
                  contentPadding: EdgeInsets.zero,
                ),
                
                // 속도 선택 (켜기일 때만 표시)
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: settingsService.appSettings.batteryDisplayCycleSpeed != BatteryDisplayCycleSpeed.off
                    ? Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '순환 속도',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            SegmentedButton<BatteryDisplayCycleSpeed>(
                              segments: [
                                ButtonSegment<BatteryDisplayCycleSpeed>(
                                  value: BatteryDisplayCycleSpeed.slow,
                                  label: const Text('느림'),
                                  tooltip: '5초마다 전환',
                                ),
                                ButtonSegment<BatteryDisplayCycleSpeed>(
                                  value: BatteryDisplayCycleSpeed.normal,
                                  label: const Text('보통'),
                                  tooltip: '3초마다 전환',
                                ),
                                ButtonSegment<BatteryDisplayCycleSpeed>(
                                  value: BatteryDisplayCycleSpeed.fast,
                                  label: const Text('빠름'),
                                  tooltip: '2초마다 전환',
                                ),
                              ],
                              selected: {settingsService.appSettings.batteryDisplayCycleSpeed},
                              onSelectionChanged: (Set<BatteryDisplayCycleSpeed> newSelection) {
                                if (newSelection.isNotEmpty) {
                                  settingsService.updateBatteryDisplayCycleSpeed(newSelection.first);
                                  setState(() {}); // 다이얼로그 상태 업데이트
                                }
                              },
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
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
                CheckboxListTile(
                  title: Text(
                    '배터리 온도 표시',
                    style: settingsService.appSettings.batteryDisplayCycleSpeed == BatteryDisplayCycleSpeed.off
                      ? TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                        )
                      : null,
                  ),
                  subtitle: Text(
                    '배터리 온도 정보 표시',
                    style: settingsService.appSettings.batteryDisplayCycleSpeed == BatteryDisplayCycleSpeed.off
                      ? TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                        )
                      : null,
                  ),
                  value: settingsService.appSettings.showBatteryTemperature,
                  onChanged: settingsService.appSettings.batteryDisplayCycleSpeed == BatteryDisplayCycleSpeed.off 
                    ? null 
                    : (value) {
                        settingsService.updateShowBatteryTemperature(value ?? false);
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
                        if (value == true) {
                          // 탭 활성화 → 스와이프 자동 비활성화
                          settingsService.updateEnableTapToSwitch(true);
                          settingsService.updateEnableSwipeToSwitch(false);
                        } else {
                          // 탭 비활성화 (둘 다 비활성화 가능)
                          settingsService.updateEnableTapToSwitch(false);
                        }
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
                        if (value == true) {
                          // 스와이프 활성화 → 탭 자동 비활성화
                          settingsService.updateEnableTapToSwitch(false);
                          settingsService.updateEnableSwipeToSwitch(true);
                        } else {
                          // 스와이프 비활성화 (둘 다 비활성화 가능)
                          settingsService.updateEnableSwipeToSwitch(false);
                        }
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

  void _showDeveloperModeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        // 테스트용 상태 변수들 (StatefulBuilder 내부에서 관리)
        return _DeveloperModeDialogContent(settingsService: settingsService);
      },
    );
  }
}

// 개발자 모드 다이얼로그 내용 위젯 (상태 관리용)
class _DeveloperModeDialogContent extends StatefulWidget {
  final SettingsService settingsService;

  const _DeveloperModeDialogContent({
    required this.settingsService,
  });

  @override
  State<_DeveloperModeDialogContent> createState() => _DeveloperModeDialogContentState();
}

class _DeveloperModeDialogContentState extends State<_DeveloperModeDialogContent> {
  // 테스트용 상태 변수들
  bool completeFastCharging = true;
  bool completeNormalCharging = true;
  bool percentFastCharging = true;
  bool percentNormalCharging = true;
  final Set<int> selectedPercentTestValues = {70, 80, 90};

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.developer_mode, size: 24),
          SizedBox(width: 8),
          Text('개발자 모드'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 현재 설정 상태 카드
            ListenableBuilder(
              listenable: widget.settingsService,
              builder: (context, _) {
                final completeEnabled = widget.settingsService.appSettings.chargingCompleteNotificationEnabled;
                final completeFast = widget.settingsService.appSettings.chargingCompleteNotifyOnFastCharging;
                final completeNormal = widget.settingsService.appSettings.chargingCompleteNotifyOnNormalCharging;
                final percentEnabled = widget.settingsService.appSettings.chargingPercentNotificationEnabled;
                final percentThresholds = widget.settingsService.appSettings.chargingPercentThresholds;
                
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '📊 현재 설정 상태',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildSettingStatusRow(
                        context,
                        '충전 완료 알림',
                        completeEnabled,
                        completeFast && completeNormal
                            ? '모든 충전 타입'
                            : completeFast
                                ? '고속 충전만'
                                : completeNormal
                                    ? '일반 충전만'
                                    : '설정 필요',
                      ),
                      const SizedBox(height: 4),
                      _buildSettingStatusRow(
                        context,
                        '충전 퍼센트 알림',
                        percentEnabled,
                        percentThresholds.isEmpty
                            ? '알림 퍼센트 없음'
                            : percentThresholds.length == 1
                                ? '${percentThresholds.first.toInt()}% 알림'
                                : '${percentThresholds.length}개 퍼센트 알림',
                      ),
                    ],
                  ),
                );
              },
            ),
            
            const SizedBox(height: 24),
            
            // 충전 완료 알림 테스트 섹션
            const Text(
              '📱 충전 완료 알림 테스트',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '100% 충전 완료 알림을 테스트합니다. 충전 타입을 선택하여 테스트할 수 있습니다.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            
            // 충전 타입 선택
            CheckboxListTile(
              title: const Text('고속 충전 (AC)'),
              subtitle: const Text('AC 충전 시 알림'),
              value: completeFastCharging,
              onChanged: (value) => setState(() {
                completeFastCharging = value ?? true;
              }),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
            ),
            CheckboxListTile(
              title: const Text('일반 충전 (USB/Wireless)'),
              subtitle: const Text('USB 또는 무선 충전 시 알림'),
              value: completeNormalCharging,
              onChanged: (value) => setState(() {
                completeNormalCharging = value ?? true;
              }),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  try {
                    await NotificationService().showChargingCompleteNotification();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '충전 완료 알림이 전송되었습니다.\n'
                            '(${completeFastCharging ? "고속 충전" : ""}'
                            '${completeFastCharging && completeNormalCharging ? ", " : ""}'
                            '${completeNormalCharging ? "일반 충전" : ""})',
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('알림 전송 실패: $e'),
                          backgroundColor: Theme.of(context).colorScheme.error,
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.battery_charging_full),
                label: const Text('충전 완료 알림 전송'),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 충전 퍼센트 알림 테스트 섹션
            const Text(
              '📊 충전 퍼센트 알림 테스트',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '설정한 퍼센트 도달 시 알림을 테스트합니다. 여러 퍼센트를 선택하여 테스트할 수 있습니다.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            
            // 퍼센트 선택 (Chip 버튼들)
            const Text(
              '테스트할 퍼센트 선택:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [70, 80, 90, 100].map((percent) {
                final isSelected = selectedPercentTestValues.contains(percent);
                return FilterChip(
                  label: Text('$percent%'),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        selectedPercentTestValues.add(percent);
                      } else {
                        selectedPercentTestValues.remove(percent);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            
            // 커스텀 퍼센트 입력
            OutlinedButton.icon(
              onPressed: () => _showCustomPercentInputDialog(
                context,
                selectedPercentTestValues,
              ),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('커스텀 퍼센트 입력'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 36),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // 충전 타입 선택 (퍼센트 알림용)
            CheckboxListTile(
              title: const Text('고속 충전 (AC)'),
              subtitle: const Text('AC 충전 시 알림'),
              value: percentFastCharging,
              onChanged: (value) => setState(() {
                percentFastCharging = value ?? true;
              }),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
            ),
            CheckboxListTile(
              title: const Text('일반 충전 (USB/Wireless)'),
              subtitle: const Text('USB 또는 무선 충전 시 알림'),
              value: percentNormalCharging,
              onChanged: (value) => setState(() {
                percentNormalCharging = value ?? true;
              }),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: selectedPercentTestValues.isEmpty
                    ? null
                    : () async {
                        try {
                          final sortedPercents = selectedPercentTestValues.toList()..sort();
                          for (final percent in sortedPercents) {
                            await NotificationService().showChargingPercentNotification(percent);
                            await Future.delayed(const Duration(milliseconds: 300));
                          }
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '${sortedPercents.length}개의 퍼센트 알림이 전송되었습니다.\n'
                                  '(${sortedPercents.join("%, ")}%)',
                                ),
                                duration: const Duration(seconds: 3),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('알림 전송 실패: $e'),
                                backgroundColor: Theme.of(context).colorScheme.error,
                                duration: const Duration(seconds: 3),
                              ),
                            );
                          }
                        }
                      },
                icon: const Icon(Icons.battery_std),
                label: Text(
                  selectedPercentTestValues.isEmpty
                      ? '퍼센트를 선택해주세요'
                      : '선택한 퍼센트 알림 전송 (${selectedPercentTestValues.length}개)',
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('닫기'),
        ),
      ],
    );
  }

  Widget _buildSettingStatusRow(
    BuildContext context,
    String title,
    bool isEnabled,
    String detail,
  ) {
    return Row(
      children: [
        Icon(
          isEnabled ? Icons.check_circle : Icons.cancel,
          size: 16,
          color: isEnabled
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.error,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '$title: ${isEnabled ? "활성화" : "비활성화"}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isEnabled
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.error,
            ),
          ),
        ),
        if (isEnabled && detail.isNotEmpty)
          Text(
            detail,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
      ],
    );
  }

  void _showCustomPercentInputDialog(
    BuildContext context,
    Set<int> selectedPercentTestValues,
  ) {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('커스텀 퍼센트 입력'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: '퍼센트 (10-100)',
            hintText: '예: 75',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              final percent = int.tryParse(controller.text);
              if (percent != null && percent >= 10 && percent <= 100) {
                Navigator.of(context).pop();
                setState(() {
                  selectedPercentTestValues.add(percent);
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$percent% 알림이 추가되었습니다.'),
                    duration: const Duration(seconds: 2),
                  ),
                );
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
