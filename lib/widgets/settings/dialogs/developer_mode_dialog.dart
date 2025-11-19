import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../services/settings_service.dart';
import '../../../services/notification_service.dart';
import '../../../services/system_settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 헤더
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.developer_mode,
                    size: 28,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '개발자 모드',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '앱 기능 테스트 및 디버깅',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ],
              ),
            ),
            
            // 탭 컨텐츠
            Expanded(
              child: _DeveloperModeDialogContent(settingsService: settingsService),
            ),
          ],
        ),
      ),
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

class _DeveloperModeDialogContentState extends State<_DeveloperModeDialogContent> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // 테스트용 상태 변수들
  bool completeFastCharging = true;
  bool completeNormalCharging = true;
  bool percentFastCharging = true;
  bool percentNormalCharging = true;
  final Set<int> selectedPercentTestValues = {70, 80, 90};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 탭 바
        Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            indicatorColor: Theme.of(context).colorScheme.primary,
            tabs: const [
              Tab(
                icon: Icon(Icons.power, size: 20),
                text: '백그라운드 감지',
              ),
              Tab(
                icon: Icon(Icons.notifications, size: 20),
                text: '알림 테스트',
              ),
            ],
          ),
        ),
        
        // 탭 뷰
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _BackgroundDetectionTab(settingsService: widget.settingsService),
              _NotificationTestTab(
                settingsService: widget.settingsService,
                completeFastCharging: completeFastCharging,
                completeNormalCharging: completeNormalCharging,
                percentFastCharging: percentFastCharging,
                percentNormalCharging: percentNormalCharging,
                selectedPercentTestValues: selectedPercentTestValues,
                onCompleteFastChanged: (value) => setState(() => completeFastCharging = value),
                onCompleteNormalChanged: (value) => setState(() => completeNormalCharging = value),
                onPercentFastChanged: (value) => setState(() => percentFastCharging = value),
                onPercentNormalChanged: (value) => setState(() => percentNormalCharging = value),
                onPercentValuesChanged: (values) => setState(() {
                  selectedPercentTestValues.clear();
                  selectedPercentTestValues.addAll(values);
                }),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 백그라운드 감지 탭
class _BackgroundDetectionTab extends StatelessWidget {
  final SettingsService settingsService;

  const _BackgroundDetectionTab({
    required this.settingsService,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 설명 카드
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '백그라운드 충전 감지',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '앱이 완전히 종료된 상태에서도 충전기 연결/분리를 감지할 수 있습니다. '
                  '토글을 활성화하고 앱을 종료한 후 충전기를 연결/분리해보세요.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // 토글 설정
          ListenableBuilder(
            listenable: settingsService,
            builder: (context, _) {
              final isEnabled = settingsService.appSettings.developerModeChargingTestEnabled;
              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isEnabled
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                    width: isEnabled ? 2 : 1,
                  ),
                ),
                child: SwitchListTile(
                  title: const Text('백그라운드 충전 감지 테스트'),
                  subtitle: Text(
                    isEnabled
                        ? '앱이 꺼져있어도 충전 상태 변화 시 알림을 받습니다'
                        : '알림을 받지 않습니다',
                  ),
                  value: isEnabled,
                  onChanged: (value) {
                    settingsService.toggleDeveloperModeChargingTest();
                  },
                  secondary: Icon(
                    isEnabled ? Icons.power : Icons.power_off,
                    color: isEnabled
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: 24),
          
          // 디버깅 정보
          _DebugInfoWidget(settingsService: settingsService),
        ],
      ),
    );
  }
}

/// 알림 테스트 탭
class _NotificationTestTab extends StatelessWidget {
  final SettingsService settingsService;
  final bool completeFastCharging;
  final bool completeNormalCharging;
  final bool percentFastCharging;
  final bool percentNormalCharging;
  final Set<int> selectedPercentTestValues;
  final ValueChanged<bool> onCompleteFastChanged;
  final ValueChanged<bool> onCompleteNormalChanged;
  final ValueChanged<bool> onPercentFastChanged;
  final ValueChanged<bool> onPercentNormalChanged;
  final ValueChanged<Set<int>> onPercentValuesChanged;

  const _NotificationTestTab({
    required this.settingsService,
    required this.completeFastCharging,
    required this.completeNormalCharging,
    required this.percentFastCharging,
    required this.percentNormalCharging,
    required this.selectedPercentTestValues,
    required this.onCompleteFastChanged,
    required this.onCompleteNormalChanged,
    required this.onPercentFastChanged,
    required this.onPercentNormalChanged,
    required this.onPercentValuesChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 현재 설정 상태 카드
          ListenableBuilder(
            listenable: settingsService,
            builder: (context, _) {
              final completeEnabled = settingsService.appSettings.chargingCompleteNotificationEnabled;
              final completeFast = settingsService.appSettings.chargingCompleteNotifyOnFastCharging;
              final completeNormal = settingsService.appSettings.chargingCompleteNotifyOnNormalCharging;
              final percentEnabled = settingsService.appSettings.chargingPercentNotificationEnabled;
              final percentThresholds = settingsService.appSettings.chargingPercentThresholds;
              
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.settings,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '현재 알림 설정',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
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
                    const SizedBox(height: 8),
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
          
          // 충전 완료 알림 테스트
          _buildNotificationTestSection(
            context,
            title: '충전 완료 알림 테스트',
            icon: Icons.battery_charging_full,
            description: '100% 충전 완료 알림을 테스트합니다.',
            children: [
              CheckboxListTile(
                title: const Text('고속 충전 (AC)'),
                subtitle: const Text('AC 충전 시 알림'),
                value: completeFastCharging,
                onChanged: (value) => onCompleteFastChanged(value ?? true),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              ),
              CheckboxListTile(
                title: const Text('일반 충전 (USB/Wireless)'),
                subtitle: const Text('USB 또는 무선 충전 시 알림'),
                value: completeNormalCharging,
                onChanged: (value) => onCompleteNormalChanged(value ?? true),
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
                            content: const Text('충전 완료 알림이 전송되었습니다.'),
                            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                            behavior: SnackBarBehavior.floating,
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
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.send),
                  label: const Text('알림 전송'),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // 충전 퍼센트 알림 테스트
          _buildNotificationTestSection(
            context,
            title: '충전 퍼센트 알림 테스트',
            icon: Icons.battery_std,
            description: '설정한 퍼센트 도달 시 알림을 테스트합니다.',
            children: [
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
                      final newValues = Set<int>.from(selectedPercentTestValues);
                      if (selected) {
                        newValues.add(percent);
                      } else {
                        newValues.remove(percent);
                      }
                      onPercentValuesChanged(newValues);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _showCustomPercentInputDialog(
                  context,
                  selectedPercentTestValues,
                  onPercentValuesChanged,
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('커스텀 퍼센트 입력'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 36),
                ),
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                title: const Text('고속 충전 (AC)'),
                subtitle: const Text('AC 충전 시 알림'),
                value: percentFastCharging,
                onChanged: (value) => onPercentFastChanged(value ?? true),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              ),
              CheckboxListTile(
                title: const Text('일반 충전 (USB/Wireless)'),
                subtitle: const Text('USB 또는 무선 충전 시 알림'),
                value: percentNormalCharging,
                onChanged: (value) => onPercentNormalChanged(value ?? true),
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
                                    '${sortedPercents.length}개의 퍼센트 알림이 전송되었습니다.',
                                  ),
                                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                  behavior: SnackBarBehavior.floating,
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
                                  behavior: SnackBarBehavior.floating,
                                  duration: const Duration(seconds: 3),
                                ),
                              );
                            }
                          }
                        },
                  icon: const Icon(Icons.send),
                  label: Text(
                    selectedPercentTestValues.isEmpty
                        ? '퍼센트를 선택해주세요'
                        : '선택한 퍼센트 알림 전송 (${selectedPercentTestValues.length}개)',
                  ),
                ),
              ),
            ],
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
          size: 18,
          color: isEnabled
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.error,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '$title: ${isEnabled ? "활성화" : "비활성화"}',
            style: TextStyle(
              fontSize: 13,
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
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
      ],
    );
  }

  Widget _buildNotificationTestSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required String description,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  void _showCustomPercentInputDialog(
    BuildContext context,
    Set<int> selectedPercentTestValues,
    ValueChanged<Set<int>> onChanged,
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
                final newValues = Set<int>.from(selectedPercentTestValues)..add(percent);
                onChanged(newValues);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$percent% 알림이 추가되었습니다.'),
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('10-100 사이의 숫자를 입력해주세요.'),
                    behavior: SnackBarBehavior.floating,
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

/// 디버깅 정보 위젯
class _DebugInfoWidget extends StatefulWidget {
  final SettingsService settingsService;

  const _DebugInfoWidget({
    required this.settingsService,
  });

  @override
  State<_DebugInfoWidget> createState() => _DebugInfoWidgetState();
}

class _DebugInfoWidgetState extends State<_DebugInfoWidget> {
  bool _isLoading = false;
  Map<String, String> _debugInfo = {};

  @override
  void initState() {
    super.initState();
    _loadDebugInfo();
  }

  Future<void> _loadDebugInfo() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final info = <String, String>{};

      // 1. Flutter 설정 값
      info['Flutter 설정 값'] = widget.settingsService.appSettings.developerModeChargingTestEnabled
          ? 'true'
          : 'false';

      // 2. SharedPreferences 직접 읽기
      final prefs = await SharedPreferences.getInstance();
      final prefsValue = prefs.getBool('developerModeChargingTestEnabled');
      info['SharedPreferences (Flutter)'] = prefsValue?.toString() ?? 'null';

      // 3. 네이티브에서 읽은 값
      final systemSettings = SystemSettingsService();
      final nativeValue = await systemSettings.getDeveloperModeChargingTestEnabled();
      info['네이티브에서 읽은 값'] = nativeValue?.toString() ?? 'null';

      // 4. 알림 권한 상태
      final notificationPermission = await Permission.notification.status;
      info['알림 권한'] = notificationPermission.isGranted ? '허용됨' : '거부됨';

      // 5. Flutter SharedPreferences 전체 (관련 키만)
      final allPrefs = await systemSettings.getAllFlutterSharedPreferences();
      if (allPrefs != null) {
        final developerKey = allPrefs['developerModeChargingTestEnabled'];
        info['네이티브 SharedPreferences'] = developerKey?.toString() ?? '키 없음';
        
        // 관련 키들도 표시
        final relatedKeys = allPrefs.entries
            .where((e) => e.key.toString().contains('developer') || 
                         e.key.toString().contains('charging') ||
                         e.key.toString().contains('notification'))
            .take(5)
            .map((e) => '${e.key}: ${e.value}')
            .join(', ');
        if (relatedKeys.isNotEmpty) {
          info['관련 키들'] = relatedKeys;
        }
      }

      setState(() {
        _debugInfo = info;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _debugInfo = {'오류': e.toString()};
        _isLoading = false;
      });
    }
  }

  String _formatDebugInfo() {
    final buffer = StringBuffer();
    buffer.writeln('=== BatteryPal 개발자 모드 디버깅 정보 ===');
    buffer.writeln('생성 시간: ${DateTime.now().toIso8601String()}');
    buffer.writeln('');
    
    for (final entry in _debugInfo.entries) {
      buffer.writeln('${entry.key}: ${entry.value}');
    }
    
    buffer.writeln('');
    buffer.writeln('=== 끝 ===');
    return buffer.toString();
  }

  Future<void> _copyToClipboard() async {
    final text = _formatDebugInfo();
    await Clipboard.setData(ClipboardData(text: text));
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('디버깅 정보가 클립보드에 복사되었습니다'),
            ],
          ),
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.bug_report,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '디버깅 정보',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.content_copy, size: 20),
                      onPressed: _debugInfo.isEmpty ? null : _copyToClipboard,
                      tooltip: '복사',
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 20),
                      onPressed: _loadDebugInfo,
                      tooltip: '새로고침',
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_debugInfo.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    '디버깅 정보를 불러올 수 없습니다',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              )
            else
              ..._debugInfo.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 160,
                        child: Text(
                          '${entry.key}:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                      Expanded(
                        child: SelectableText(
                          entry.value,
                          style: TextStyle(
                            fontSize: 12,
                            fontFamily: 'monospace',
                            color: _getValueColor(context, entry.key, entry.value),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Color _getValueColor(BuildContext context, String key, String value) {
    if (key.contains('권한') && value.contains('거부')) {
      return Theme.of(context).colorScheme.error;
    }
    if (key.contains('설정 값') || key.contains('SharedPreferences')) {
      if (value == 'true') {
        return Theme.of(context).colorScheme.primary;
      } else if (value == 'false' || value == 'null' || value.contains('없음')) {
        return Theme.of(context).colorScheme.error;
      }
    }
    return Theme.of(context).colorScheme.onSurface;
  }
}
