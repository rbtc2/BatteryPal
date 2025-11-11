import 'package:flutter/material.dart';
import '../../services/settings_service.dart';
import '../../widgets/settings/settings_widgets.dart';
import '../../widgets/common/common_widgets.dart';
import '../../models/app_models.dart';
import '../../screens/analysis/widgets/optimization/widgets/auto_optimization_card.dart';

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

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settingsService,
      builder: (context, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // 자동 최적화 설정
              const AutoOptimizationCard(),
              
              const SizedBox(height: 16),
              
              // 배터리 정보 표시 방식 설정
              _buildFeatureSettingsCard(
                context,
                '배터리 정보 표시 방식',
                Icons.smartphone,
                '배터리 정보 표시 및 전환 방식 설정',
                [
                  SettingsActionItem(
                    title: '배터리 정보 표시 방식',
                    subtitle: _getBatteryDisplaySubtitle(),
                    icon: Icons.display_settings,
                    onTap: () => _showBatteryDisplaySettingsDialog(context),
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

  String _getBatteryDisplaySubtitle() {
    final speed = settingsService.appSettings.batteryDisplayCycleSpeed;
    if (speed == BatteryDisplayCycleSpeed.off) {
      return '자동 순환 끄기';
    }
    final speedText = speed.displayName;
    final enabledCount = [
      settingsService.appSettings.showChargingCurrent,
      settingsService.appSettings.showBatteryPercentage,
      settingsService.appSettings.showBatteryTemperature,
    ].where((e) => e).length;
    return '$speedText 속도, $enabledCount개 정보 표시';
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

