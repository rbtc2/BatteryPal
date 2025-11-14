import 'package:flutter/material.dart';
import '../models/optimization_models.dart';
// 백업 파일: 더 이상 사용되지 않음
// import '../../../../../widgets/common/common_widgets.dart';

/// 백업 파일용 간단한 CustomCard 구현
class CustomCard extends StatelessWidget {
  final Widget child;
  final double? elevation;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  
  const CustomCard({
    super.key,
    required this.child,
    this.elevation,
    this.padding,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: elevation ?? 2,
      shape: borderRadius != null 
          ? RoundedRectangleBorder(borderRadius: borderRadius!)
          : null,
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}

/// 섹션 2: 자동 최적화 설정
/// 원클릭 최적화 버튼을 눌렀을 때 실행될 항목을 선택하는 토글만 제공
class AutoOptimizationCard extends StatefulWidget {
  const AutoOptimizationCard({super.key});

  @override
  State<AutoOptimizationCard> createState() => _AutoOptimizationCardState();
}

class _AutoOptimizationCardState extends State<AutoOptimizationCard> {
  late List<OptimizationItem> _autoItems;

  @override
  void initState() {
    super.initState();
    _autoItems = _getAutoOptimizationItems();
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

  void _toggleItem(OptimizationItem item) {
    setState(() {
      item.isEnabled = !item.isEnabled;
    });
    
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
    ];
  }
}

