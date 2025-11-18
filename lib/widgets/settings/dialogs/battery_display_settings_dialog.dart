import 'package:flutter/material.dart';
import '../../../services/settings_service.dart';
import '../../../models/models.dart';

/// 배터리 정보 표시 방식 설정 다이얼로그
class BatteryDisplaySettingsDialog extends StatelessWidget {
  final SettingsService settingsService;

  const BatteryDisplaySettingsDialog({
    super.key,
    required this.settingsService,
  });

  static void show(BuildContext context, SettingsService settingsService) {
    showDialog(
      context: context,
      builder: (context) => BatteryDisplaySettingsDialog(
        settingsService: settingsService,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(
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
                      settingsService.updateBatteryDisplayCycleSpeed(BatteryDisplayCycleSpeed.normal);
                    } else {
                      settingsService.updateBatteryDisplayCycleSpeed(BatteryDisplayCycleSpeed.off);
                    }
                    setState(() {});
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
                                  setState(() {});
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
                _buildInfoCheckbox(
                  context,
                  setState,
                  '충전 전류 표시',
                  '충전 중일 때 전류 정보 표시',
                  settingsService.appSettings.showChargingCurrent,
                  (value) => settingsService.updateShowChargingCurrent(value ?? false),
                ),
                _buildInfoCheckbox(
                  context,
                  setState,
                  '배터리 퍼센트 표시',
                  '배터리 잔량 퍼센트 표시',
                  settingsService.appSettings.showBatteryPercentage,
                  (value) => settingsService.updateShowBatteryPercentage(value ?? false),
                ),
                _buildInfoCheckbox(
                  context,
                  setState,
                  '배터리 온도 표시',
                  '배터리 온도 정보 표시',
                  settingsService.appSettings.showBatteryTemperature,
                  (value) => settingsService.updateShowBatteryTemperature(value ?? false),
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
                _buildGestureCheckbox(
                  context,
                  setState,
                  '탭으로 전환',
                  '화면을 탭하여 정보 전환',
                  settingsService.appSettings.enableTapToSwitch,
                  (value) {
                    if (value == true) {
                      settingsService.updateEnableTapToSwitch(true);
                      settingsService.updateEnableSwipeToSwitch(false);
                    } else {
                      settingsService.updateEnableTapToSwitch(false);
                    }
                    setState(() {});
                  },
                ),
                _buildGestureCheckbox(
                  context,
                  setState,
                  '스와이프로 전환',
                  '좌우 스와이프로 정보 전환',
                  settingsService.appSettings.enableSwipeToSwitch,
                  (value) {
                    if (value == true) {
                      settingsService.updateEnableTapToSwitch(false);
                      settingsService.updateEnableSwipeToSwitch(true);
                    } else {
                      settingsService.updateEnableSwipeToSwitch(false);
                    }
                    setState(() {});
                  },
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
    );
  }

  Widget _buildInfoCheckbox(
    BuildContext context,
    StateSetter setState,
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool?> onChanged,
  ) {
    final isDisabled = settingsService.appSettings.batteryDisplayCycleSpeed == BatteryDisplayCycleSpeed.off;
    final disabledStyle = TextStyle(
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
    );

    return CheckboxListTile(
      title: Text(title, style: isDisabled ? disabledStyle : null),
      subtitle: Text(subtitle, style: isDisabled ? disabledStyle : null),
      value: value,
      onChanged: isDisabled ? null : (value) {
        onChanged(value);
        setState(() {});
      },
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildGestureCheckbox(
    BuildContext context,
    StateSetter setState,
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool?> onChanged,
  ) {
    final isDisabled = settingsService.appSettings.batteryDisplayCycleSpeed == BatteryDisplayCycleSpeed.off;
    final disabledStyle = TextStyle(
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
    );

    return CheckboxListTile(
      title: Text(title, style: isDisabled ? disabledStyle : null),
      subtitle: Text(subtitle, style: isDisabled ? disabledStyle : null),
      value: value,
      onChanged: isDisabled ? null : onChanged,
      contentPadding: EdgeInsets.zero,
    );
  }
}

