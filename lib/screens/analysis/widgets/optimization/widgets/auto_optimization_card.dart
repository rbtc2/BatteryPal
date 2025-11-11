import 'package:flutter/material.dart';
import '../models/optimization_models.dart';
import '../../../../../widgets/common/common_widgets.dart';
import '../../../../../services/settings_service.dart';
import '../../../../../services/system_settings_service.dart';
import '../../../../../services/permission_helper.dart';

/// 섹션 2: 자동 최적화 설정
/// 원클릭 최적화 버튼을 눌렀을 때 실행될 항목을 선택하는 토글만 제공
class AutoOptimizationCard extends StatefulWidget {
  const AutoOptimizationCard({super.key});

  @override
  State<AutoOptimizationCard> createState() => _AutoOptimizationCardState();
}

class _AutoOptimizationCardState extends State<AutoOptimizationCard> {
  late List<OptimizationItem> _autoItems;
  final SettingsService _settingsService = SettingsService();

  @override
  void initState() {
    super.initState();
    _autoItems = _getAutoOptimizationItems();
    _loadSettings();
  }

  /// 설정에서 화면 밝기 자동 조절 상태 로드
  void _loadSettings() {
    final autoBrightnessEnabled = _settingsService.appSettings.autoBrightnessEnabled;
    final brightnessItem = _autoItems.firstWhere(
      (item) => item.id == 'brightness_auto',
      orElse: () => _autoItems.first,
    );
    brightnessItem.isEnabled = autoBrightnessEnabled;
  }

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      elevation: 2,
      borderRadius: BorderRadius.circular(12),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Row(
            children: [
              Icon(
                Icons.settings,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                '자동 최적화 설정',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '원클릭 최적화 버튼을 눌렀을 때 실행될 항목을 선택하세요',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          
          // 항목 리스트
          Column(
            children: _autoItems.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildAutoItem(context, item),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAutoItem(BuildContext context, OptimizationItem item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // 아이콘
          Icon(
            item.icon,
            color: Colors.green[600],
            size: 20,
          ),
          
          const SizedBox(width: 12),
          
          // 제목
          Expanded(
            child: Text(
              item.title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          
          const SizedBox(width: 12),
          
          // 토글 스위치
          Switch(
            value: item.isEnabled,
            onChanged: (value) => _toggleItem(item),
            activeThumbColor: Colors.green[600],
          ),
        ],
      ),
    );
  }

  Future<void> _toggleItem(OptimizationItem item) async {
    // 화면 밝기 자동 조절 토글인 경우 권한 확인
    if (item.id == 'brightness_auto' && !item.isEnabled) {
      // 토글을 켜려고 할 때 권한 확인
      final systemSettingsService = SystemSettingsService();
      final hasPermission = await systemSettingsService.canWriteSettings();
      
      if (!hasPermission) {
        // 권한이 없으면 권한 요청 다이얼로그 표시
        // mounted 체크 후 context 사용
        if (!mounted) return;
        final granted = await PermissionHelper.requestWriteSettingsPermission(context);
        
        if (!granted) {
          // 권한이 아직 없으면 토글을 켜지 않음
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('화면 밝기 조절 권한이 필요합니다. 시스템 설정에서 권한을 허용해주세요.'),
                duration: Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          return;
        }
      }
    }
    
    setState(() {
      item.isEnabled = !item.isEnabled;
    });
    
    // 화면 밝기 자동 조절 설정 저장
    if (item.id == 'brightness_auto') {
      _settingsService.updateAutoBrightness(item.isEnabled);
    }
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            item.isEnabled 
                ? '자동 최적화에서 ${item.title} 포함' 
                : '자동 최적화에서 ${item.title} 제외',
          ),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  List<OptimizationItem> _getAutoOptimizationItems() {
    return [
      OptimizationItem(
        id: 'background_apps',
        title: '백그라운드 앱 종료',
        currentStatus: '',
        effect: '+25분',
        icon: Icons.apps,
        isEnabled: true,
        isAutomatic: true,
      ),
      OptimizationItem(
        id: 'memory_clean',
        title: '메모리 정리',
        currentStatus: '',
        effect: '+15분',
        icon: Icons.memory,
        isEnabled: true,
        isAutomatic: true,
      ),
      OptimizationItem(
        id: 'services_stop',
        title: '불필요한 서비스 중지',
        currentStatus: '',
        effect: '+20분',
        icon: Icons.settings_power,
        isEnabled: true,
        isAutomatic: true,
      ),
      OptimizationItem(
        id: 'brightness_auto',
        title: '화면 밝기 자동 조절',
        currentStatus: '',
        effect: '+20분',
        icon: Icons.brightness_6,
        isEnabled: true,
        isAutomatic: true,
      ),
    ];
  }
}

