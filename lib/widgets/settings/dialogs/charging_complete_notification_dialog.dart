import 'package:flutter/material.dart';
import '../../../services/settings_service.dart';

/// 충전 완료 알림 설정 다이얼로그
class ChargingCompleteNotificationDialog extends StatelessWidget {
  final SettingsService settingsService;

  const ChargingCompleteNotificationDialog({
    super.key,
    required this.settingsService,
  });

  static void show(BuildContext context, SettingsService settingsService) {
    showDialog(
      context: context,
      builder: (context) => ChargingCompleteNotificationDialog(
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
    );
  }
}

