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
                
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                
                // 과충전 방지 설정
                const Text(
                  '과충전 방지 알림',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('과충전 방지 알림 활성화'),
                  subtitle: const Text('100% 도달 후 과충전 경고 알림 받기'),
                  value: settingsService.appSettings.overchargeProtectionEnabled,
                  onChanged: (value) {
                    settingsService.updateOverchargeProtection(value);
                    setState(() {});
                  },
                  contentPadding: EdgeInsets.zero,
                ),
                
                // 알림 속도 설정 (과충전 방지 활성화 시에만 표시)
                if (settingsService.appSettings.overchargeProtectionEnabled) ...[
                  const SizedBox(height: 8),
                  const Text(
                    '알림 속도',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment<String>(
                        value: 'fast',
                        label: Text('빠름'),
                        tooltip: '기본값의 50% (더 빠른 알림)',
                      ),
                      ButtonSegment<String>(
                        value: 'normal',
                        label: Text('보통'),
                        tooltip: '기본값 (권장)',
                      ),
                      ButtonSegment<String>(
                        value: 'slow',
                        label: Text('느림'),
                        tooltip: '기본값의 150% (더 느린 알림)',
                      ),
                    ],
                    selected: {settingsService.appSettings.overchargeAlertSpeed},
                    onSelectionChanged: (Set<String> newSelection) {
                      if (newSelection.isNotEmpty) {
                        settingsService.updateOverchargeAlertSpeed(newSelection.first);
                        setState(() {});
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  // 설명 텍스트
                  Text(
                    _getSpeedDescription(settingsService.appSettings.overchargeAlertSpeed),
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  SwitchListTile(
                    title: const Text('온도 기반 알림 조정'),
                    subtitle: const Text('온도 40°C 이상 시 알림 타이밍 50% 단축'),
                    value: settingsService.appSettings.temperatureBasedAdjustment,
                    onChanged: (value) {
                      settingsService.updateTemperatureBasedAdjustment(value);
                      setState(() {});
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
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
  
  /// 알림 속도 설명 텍스트 가져오기
  String _getSpeedDescription(String speed) {
    switch (speed) {
      case 'fast':
        return '기본값의 50% (더 빠른 알림)';
      case 'slow':
        return '기본값의 150% (더 느린 알림)';
      case 'normal':
      default:
        return '기본값 (권장)';
    }
  }
}

