import 'package:flutter/material.dart';
import '../../../services/settings_service.dart';
import 'add_custom_percent_dialog.dart';

/// 충전 퍼센트 알림 설정 다이얼로그
class ChargingPercentNotificationDialog extends StatelessWidget {
  final SettingsService settingsService;

  const ChargingPercentNotificationDialog({
    super.key,
    required this.settingsService,
  });

  static void show(BuildContext context, SettingsService settingsService) {
    showDialog(
      context: context,
      builder: (context) => ChargingPercentNotificationDialog(
        settingsService: settingsService,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(
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
                  onPressed: () => AddCustomPercentDialog.show(
                    context,
                    settingsService,
                    () => setState(() {}),
                  ),
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
    );
  }
}

