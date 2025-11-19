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
          
          // 단계별 진단 체크리스트
          _DiagnosticChecklistWidget(settingsService: settingsService),
          
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

/// 진단 단계 상태
enum DiagnosticStepStatus {
  pass,    // ✅ 통과
  fail,    // ❌ 실패
  warning, // ⚠️ 경고
  info,    // ℹ️ 정보
}

/// 진단 단계 모델
class DiagnosticStep {
  final String phase;
  final int step;
  final String name;
  final String description;
  final DiagnosticStepStatus status;
  final String details;
  final String? fixHint;

  DiagnosticStep({
    required this.phase,
    required this.step,
    required this.name,
    required this.description,
    required this.status,
    required this.details,
    this.fixHint,
  });
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
        // Flutter SharedPreferences는 "flutter." 접두사를 사용합니다
        final developerKey = allPrefs['flutter.developerModeChargingTestEnabled'] ?? 
                             allPrefs['developerModeChargingTestEnabled'];
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

/// 단계별 진단 체크리스트 위젯
class _DiagnosticChecklistWidget extends StatefulWidget {
  final SettingsService settingsService;

  const _DiagnosticChecklistWidget({
    required this.settingsService,
  });

  @override
  State<_DiagnosticChecklistWidget> createState() => _DiagnosticChecklistWidgetState();
}

class _DiagnosticChecklistWidgetState extends State<_DiagnosticChecklistWidget> {
  bool _isLoading = false;
  List<DiagnosticStep> _steps = [];
  String? _currentPhase;

  @override
  void initState() {
    super.initState();
    _runDiagnostics();
  }

  Future<void> _runDiagnostics() async {
    setState(() {
      _isLoading = true;
      _steps = [];
    });

    try {
      final steps = <DiagnosticStep>[];
      final systemSettings = SystemSettingsService();

      // Phase 1: 설정 확인
      final flutterValue = widget.settingsService.appSettings.developerModeChargingTestEnabled;
      steps.add(DiagnosticStep(
        phase: 'Phase 1: 설정 확인',
        step: 1,
        name: 'Flutter 설정 값',
        description: '앱 내부 설정이 활성화되어 있는지 확인',
        status: flutterValue ? DiagnosticStepStatus.pass : DiagnosticStepStatus.fail,
        details: flutterValue ? '활성화됨' : '비활성화됨',
        fixHint: !flutterValue ? '개발자 모드에서 "백그라운드 충전 감지 테스트" 토글을 켜주세요.' : null,
      ));

      final prefs = await SharedPreferences.getInstance();
      final prefsValue = prefs.getBool('developerModeChargingTestEnabled');
      steps.add(DiagnosticStep(
        phase: 'Phase 1: 설정 확인',
        step: 2,
        name: 'SharedPreferences 저장',
        description: '설정이 영구 저장소에 저장되었는지 확인',
        status: prefsValue == flutterValue ? DiagnosticStepStatus.pass : DiagnosticStepStatus.fail,
        details: prefsValue?.toString() ?? 'null',
        fixHint: prefsValue != flutterValue ? '설정 저장에 문제가 있습니다. 앱을 재시작해보세요.' : null,
      ));

      final nativeValue = await systemSettings.getDeveloperModeChargingTestEnabled();
      steps.add(DiagnosticStep(
        phase: 'Phase 1: 설정 확인',
        step: 3,
        name: '네이티브에서 읽기',
        description: '네이티브 코드에서 설정을 읽을 수 있는지 확인',
        status: nativeValue == flutterValue ? DiagnosticStepStatus.pass : DiagnosticStepStatus.fail,
        details: 'Flutter: $flutterValue, Native: $nativeValue',
        fixHint: nativeValue != flutterValue
            ? '네이티브에서 설정을 읽지 못했습니다. 앱을 재시작하거나 SharedPreferences 키를 확인해주세요.'
            : null,
      ));

      // Phase 2: 권한 확인
      final notificationPermission = await Permission.notification.status;
      steps.add(DiagnosticStep(
        phase: 'Phase 2: 권한 확인',
        step: 4,
        name: '알림 권한',
        description: '알림을 표시할 권한이 있는지 확인',
        status: notificationPermission.isGranted ? DiagnosticStepStatus.pass : DiagnosticStepStatus.fail,
        details: notificationPermission.isGranted ? '허용됨' : '거부됨',
        fixHint: !notificationPermission.isGranted
            ? '설정 → 앱 → BatteryPal → 알림에서 권한을 허용해주세요.'
            : null,
      ));

      final batteryOptimization = await systemSettings.isIgnoringBatteryOptimizations();
      steps.add(DiagnosticStep(
        phase: 'Phase 2: 권한 확인',
        step: 5,
        name: '배터리 최적화 예외',
        description: '배터리 최적화에서 제외되었는지 확인',
        status: batteryOptimization == true ? DiagnosticStepStatus.pass : DiagnosticStepStatus.warning,
        details: batteryOptimization == true ? '예외 설정됨' : '예외 설정 안됨',
        fixHint: batteryOptimization != true
            ? '배터리 최적화 예외를 설정하면 백그라운드 동작이 더 안정적입니다.'
            : null,
      ));

      // Phase 3: 시스템 구성 확인
      final isReceiverRegistered = await systemSettings.checkBatteryStateReceiverRegistered();
      steps.add(DiagnosticStep(
        phase: 'Phase 3: 시스템 구성',
        step: 7,
        name: 'BatteryStateReceiver 등록',
        description: 'AndroidManifest에 리시버가 등록되어 있는지 확인',
        status: isReceiverRegistered == true
            ? DiagnosticStepStatus.pass
            : isReceiverRegistered == false
                ? DiagnosticStepStatus.fail
                : DiagnosticStepStatus.info,
        details: isReceiverRegistered == true
            ? '등록됨'
            : isReceiverRegistered == false
                ? '등록 안됨'
                : '확인 불가',
        fixHint: isReceiverRegistered == false
            ? 'AndroidManifest.xml에 BatteryStateReceiver가 등록되어 있는지 확인해주세요.'
            : null,
      ));

      // Phase 4: 실제 동작 확인
      final lastEventInfo = await systemSettings.getLastChargingEventTime();
      final lastEventTime = lastEventInfo?['time'] as int?;
      final hasRecentEvent = lastEventTime != null &&
          (DateTime.now().millisecondsSinceEpoch - lastEventTime) < 3600000; // 1시간 이내

      steps.add(DiagnosticStep(
        phase: 'Phase 4: 실제 동작',
        step: 9,
        name: '최근 충전 이벤트',
        description: '최근 1시간 이내 충전 이벤트가 감지되었는지 확인',
        status: hasRecentEvent
            ? DiagnosticStepStatus.pass
            : lastEventTime != null
                ? DiagnosticStepStatus.warning
                : DiagnosticStepStatus.info,
        details: lastEventInfo?['formatted'] as String? ?? '이벤트 없음',
        fixHint: !hasRecentEvent
            ? '충전기를 연결/분리해보고 다시 확인해주세요. 앱이 완전히 종료된 상태에서 테스트해야 합니다.'
            : null,
      ));

      setState(() {
        _steps = steps;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _steps = [
          DiagnosticStep(
            phase: '오류',
            step: 0,
            name: '진단 실행 실패',
            description: '진단을 실행하는 중 오류가 발생했습니다',
            status: DiagnosticStepStatus.fail,
            details: e.toString(),
          ),
        ];
        _isLoading = false;
      });
    }
  }

  String _getStatusIcon(DiagnosticStepStatus status) {
    switch (status) {
      case DiagnosticStepStatus.pass:
        return '✅';
      case DiagnosticStepStatus.fail:
        return '❌';
      case DiagnosticStepStatus.warning:
        return '⚠️';
      case DiagnosticStepStatus.info:
        return 'ℹ️';
    }
  }

  Color _getStatusColor(DiagnosticStepStatus status) {
    switch (status) {
      case DiagnosticStepStatus.pass:
        return Theme.of(context).colorScheme.primary;
      case DiagnosticStepStatus.fail:
        return Theme.of(context).colorScheme.error;
      case DiagnosticStepStatus.warning:
        return Colors.orange;
      case DiagnosticStepStatus.info:
        return Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);
    }
  }

  int _getPassCount() {
    return _steps.where((s) => s.status == DiagnosticStepStatus.pass).length;
  }

  int _getFailCount() {
    return _steps.where((s) => s.status == DiagnosticStepStatus.fail).length;
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
                      Icons.checklist,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '단계별 진단 체크리스트',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20),
                  onPressed: _runDiagnostics,
                  tooltip: '다시 진단',
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_steps.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    '진단 결과가 없습니다',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 요약 정보
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildSummaryItem(
                          '통과',
                          _getPassCount(),
                          _steps.length,
                          DiagnosticStepStatus.pass,
                        ),
                        _buildSummaryItem(
                          '실패',
                          _getFailCount(),
                          _steps.length,
                          DiagnosticStepStatus.fail,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // 단계별 리스트
                  ..._steps.map((step) {
                    final isNewPhase = _currentPhase != step.phase;
                    if (isNewPhase) {
                      _currentPhase = step.phase;
                    }
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isNewPhase) ...[
                          const SizedBox(height: 8),
                          Text(
                            step.phase,
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        _buildStepItem(step),
                        const SizedBox(height: 8),
                      ],
                    );
                  }).toList(),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, int count, int total, DiagnosticStepStatus status) {
    return Column(
      children: [
        Text(
          '$count / $total',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _getStatusColor(status),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildStepItem(DiagnosticStep step) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getStatusColor(step.status).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getStatusColor(step.status).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _getStatusIcon(step.status),
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${step.step}. ${step.name}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(step.status),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            step.description,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '결과: ${step.details}',
            style: TextStyle(
              fontSize: 11,
              fontFamily: 'monospace',
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
          if (step.fixHint != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: 16,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      step.fixHint!,
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
