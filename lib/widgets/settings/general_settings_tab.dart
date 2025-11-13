import 'package:flutter/material.dart';
import '../../services/settings_service.dart';
import '../../widgets/settings/settings_widgets.dart';
import '../../widgets/settings/pro_settings_widgets.dart';
import '../../utils/dialog_utils.dart';
import '../../constants/app_constants.dart';
import '../../services/notification_service.dart';
import '../../services/battery_history_database_service.dart';

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
              
              // 데이터 관리
              SettingsSection(
                title: '데이터 관리',
                items: [
                  SettingsItem(
                    title: '저장된 데이터 삭제',
                    icon: Icons.delete_outline,
                    subtitle: '충전 현황, 충전 분석 등',
                    onTap: () => _showDataDeletionDialog(context),
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

  void _showDeveloperModeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        // 테스트용 상태 변수들 (StatefulBuilder 내부에서 관리)
        return _DeveloperModeDialogContent(settingsService: settingsService);
      },
    );
  }

  void _showDataDeletionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _DataDeletionDialogContent(),
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

// 데이터 삭제 다이얼로그 내용 위젯
class _DataDeletionDialogContent extends StatefulWidget {
  const _DataDeletionDialogContent();

  @override
  State<_DataDeletionDialogContent> createState() => _DataDeletionDialogContentState();
}

class _DataDeletionDialogContentState extends State<_DataDeletionDialogContent> {
  final BatteryHistoryDatabaseService _databaseService = BatteryHistoryDatabaseService();
  
  // 선택된 데이터 타입
  bool _deleteChargingHistory = false; // 충전 현황 데이터 (충전 전류)
  bool _deleteChargingAnalysis = false; // 충전 분석 데이터 (충전 세션)
  bool _deleteBatteryHistory = false; // 배터리 히스토리 데이터
  
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.delete_outline, size: 24),
          SizedBox(width: 8),
          Text('저장된 데이터 삭제'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '삭제할 데이터를 선택하세요. 이 작업은 되돌릴 수 없습니다.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            
            // 충전 현황 데이터
            CheckboxListTile(
              title: const Text('충전 현황 데이터'),
              subtitle: const Text('충전 전류 기록 등'),
              value: _deleteChargingHistory,
              onChanged: _isDeleting ? null : (value) {
                setState(() {
                  _deleteChargingHistory = value ?? false;
                });
              },
              contentPadding: EdgeInsets.zero,
            ),
            
            // 충전 분석 데이터
            CheckboxListTile(
              title: const Text('충전 분석 데이터'),
              subtitle: const Text('충전 세션 기록 등'),
              value: _deleteChargingAnalysis,
              onChanged: _isDeleting ? null : (value) {
                setState(() {
                  _deleteChargingAnalysis = value ?? false;
                });
              },
              contentPadding: EdgeInsets.zero,
            ),
            
            // 배터리 히스토리 데이터
            CheckboxListTile(
              title: const Text('배터리 히스토리 데이터'),
              subtitle: const Text('배터리 레벨, 온도 등 전체 기록'),
              value: _deleteBatteryHistory,
              onChanged: _isDeleting ? null : (value) {
                setState(() {
                  _deleteBatteryHistory = value ?? false;
                });
              },
              contentPadding: EdgeInsets.zero,
            ),
            
            const SizedBox(height: 8),
            
            // 경고 메시지
            if (_deleteChargingHistory || _deleteChargingAnalysis || _deleteBatteryHistory)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.error.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Theme.of(context).colorScheme.error,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '선택한 데이터가 영구적으로 삭제됩니다.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isDeleting ? null : () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: (_isDeleting || 
                     (!_deleteChargingHistory && !_deleteChargingAnalysis && !_deleteBatteryHistory))
              ? null
              : () => _confirmAndDelete(context),
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          child: _isDeleting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('삭제'),
        ),
      ],
    );
  }

  Future<void> _confirmAndDelete(BuildContext context) async {
    // 확인 다이얼로그
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('데이터 삭제 확인'),
        content: const Text(
          '정말로 선택한 데이터를 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isDeleting = true;
    });

    try {
      final deletedItems = <String>[];

      // 충전 현황 데이터 삭제
      if (_deleteChargingHistory) {
        try {
          final count = await _databaseService.deleteAllChargingCurrentData();
          if (count > 0) {
            deletedItems.add('충전 현황 데이터 ($count개)');
          }
        } catch (e) {
          debugPrint('충전 현황 데이터 삭제 실패: $e');
        }
      }

      // 충전 분석 데이터 삭제
      if (_deleteChargingAnalysis) {
        try {
          final count = await _databaseService.deleteAllChargingSessions();
          if (count > 0) {
            deletedItems.add('충전 분석 데이터 ($count개)');
          }
        } catch (e) {
          debugPrint('충전 분석 데이터 삭제 실패: $e');
        }
      }

      // 배터리 히스토리 데이터 삭제
      if (_deleteBatteryHistory) {
        try {
          final count = await _databaseService.deleteAllBatteryData();
          if (count > 0) {
            deletedItems.add('배터리 히스토리 데이터 ($count개)');
          }
        } catch (e) {
          debugPrint('배터리 히스토리 데이터 삭제 실패: $e');
        }
      }

      if (!context.mounted) return;

      // 성공 메시지
      Navigator.of(context).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            deletedItems.isEmpty
                ? '삭제할 데이터가 없습니다.'
                : '${deletedItems.join(', ')} 삭제 완료',
          ),
          duration: const Duration(seconds: 3),
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      setState(() {
        _isDeleting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('데이터 삭제 실패: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}
