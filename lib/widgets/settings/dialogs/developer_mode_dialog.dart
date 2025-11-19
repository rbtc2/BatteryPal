import 'package:flutter/material.dart';
import '../../../services/settings_service.dart';
import '../../../services/notification_service.dart';

/// 개발자 모드 다이얼로그
class DeveloperModeDialog extends StatelessWidget {
  final SettingsService settingsService;

  const DeveloperModeDialog({
    super.key,
    required this.settingsService,
  });

  static void show(BuildContext context, SettingsService settingsService) {
    showDialog(
      context: context,
      builder: (context) => DeveloperModeDialog(settingsService: settingsService),
    );
  }

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
      content: _DeveloperModeDialogContent(settingsService: settingsService),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('닫기'),
        ),
      ],
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
    return SingleChildScrollView(
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
          
          // 백그라운드 충전 감지 테스트 섹션
          const Text(
            '🔋 백그라운드 충전 감지 테스트',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '앱이 꺼져있어도 충전기 연결/분리 시 알림을 받을 수 있습니다. 토글을 켜고 앱을 완전히 종료한 후 충전기를 연결/분리해보세요.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          ListenableBuilder(
            listenable: widget.settingsService,
            builder: (context, _) {
              return SwitchListTile(
                title: const Text('백그라운드 충전 감지 테스트'),
                subtitle: Text(
                  widget.settingsService.appSettings.developerModeChargingTestEnabled
                      ? '앱이 꺼져있어도 충전 상태 변화 시 알림을 받습니다'
                      : '알림을 받지 않습니다',
                ),
                value: widget.settingsService.appSettings.developerModeChargingTestEnabled,
                onChanged: (value) {
                  widget.settingsService.toggleDeveloperModeChargingTest();
                },
                contentPadding: EdgeInsets.zero,
                secondary: Icon(
                  widget.settingsService.appSettings.developerModeChargingTestEnabled
                      ? Icons.power
                      : Icons.power_off,
                  color: widget.settingsService.appSettings.developerModeChargingTestEnabled
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
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

