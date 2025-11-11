import 'package:flutter/material.dart';
import '../models/optimization_models.dart';

/// 섹션 3: 개별 실행
/// 각 항목을 지금 바로 실행할 수 있는 버튼 제공
class IndividualExecutionCard extends StatefulWidget {
  const IndividualExecutionCard({super.key});

  @override
  State<IndividualExecutionCard> createState() => _IndividualExecutionCardState();
}

class _IndividualExecutionCardState extends State<IndividualExecutionCard> {
  final Map<String, ExecutionState> _executionStates = {};
  late List<IndividualExecutionItem> _executionItems;

  @override
  void initState() {
    super.initState();
    _executionItems = _getExecutionItems();
    // 초기 상태 설정
    for (final item in _executionItems) {
      _executionStates[item.id] = ExecutionState();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('⚡', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '개별 실행',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '각 항목을 지금 바로 실행할 수 있습니다',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),

          // 실행 항목 리스트
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: _executionItems.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildExecutionCard(context, item),
              )).toList(),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildExecutionCard(BuildContext context, IndividualExecutionItem item) {
    final state = _executionStates[item.id] ?? ExecutionState();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 아이콘 + 제목
          Row(
            children: [
              Text(
                item.icon,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 현재 상태
          Text(
            item.currentStatus,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),

          const SizedBox(height: 4),

          // 마지막 실행 시간
          Text(
            '마지막 실행: ${item.lastExecuted}',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),

          const SizedBox(height: 8),

          // 예상 효과
          Row(
            children: [
              Icon(
                Icons.battery_saver,
                size: 14,
                color: Colors.green[600],
              ),
              const SizedBox(width: 4),
              Text(
                '예상 효과: ${item.effect}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[600],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 실행 버튼
          SizedBox(
            width: double.infinity,
            height: 44,
            child: _buildExecutionButton(context, item, state),
          ),
        ],
      ),
    );
  }

  Widget _buildExecutionButton(
    BuildContext context,
    IndividualExecutionItem item,
    ExecutionState state,
  ) {
    Color backgroundColor;
    String buttonText;
    Widget? icon;

    if (state.isExecuting) {
      // 실행 중
      backgroundColor = Theme.of(context).colorScheme.primary.withValues(alpha: 0.7);
      buttonText = '실행 중...';
      icon = const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    } else if (state.justCompleted && state.completionMessage != null) {
      // 완료
      backgroundColor = Colors.green[600]!;
      buttonText = state.completionMessage!;
      icon = const Icon(Icons.check_circle, size: 18, color: Colors.white);
    } else {
      // 기본 상태
      backgroundColor = Theme.of(context).colorScheme.primary;
      buttonText = '지금 실행하기';
      icon = const Icon(Icons.play_arrow, size: 18, color: Colors.white);
    }

    return ElevatedButton(
      onPressed: state.isExecuting ? null : () => _executeOptimization(item),
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon,
          const SizedBox(width: 8),
          Text(
            buttonText,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _executeOptimization(IndividualExecutionItem item) async {
    // 1. 실행 중 상태로 변경
    setState(() {
      _executionStates[item.id] = ExecutionState(
        isExecuting: true,
        justCompleted: false,
      );
    });

    // SnackBar: 실행 중
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 8),
              Text('${item.title} 실행 중...'),
            ],
          ),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    // 2. 실행 시뮬레이션 (1초)
    await Future.delayed(const Duration(seconds: 1));

    // 3. 완료 상태로 변경
    if (mounted) {
      setState(() {
        _executionStates[item.id] = ExecutionState(
          isExecuting: false,
          justCompleted: true,
          completionMessage: '✓ 완료! ${item.effect}',
        );
      });

      // SnackBar: 완료
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text('✓ ${item.title} 완료! ${item.effect}'),
            ],
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green[600],
        ),
      );
    }

    // 4. 3초 후 원래 상태로
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      setState(() {
        _executionStates[item.id] = ExecutionState(
          isExecuting: false,
          justCompleted: false,
        );
      });
    }
  }

  List<IndividualExecutionItem> _getExecutionItems() {
    return [
      IndividualExecutionItem(
        id: 'background_apps',
        title: '백그라운드 앱 종료',
        icon: '🧹',
        currentStatus: '현재: 15개 실행 중',
        lastExecuted: '1시간 전',
        effect: '+25분',
      ),
      IndividualExecutionItem(
        id: 'memory_clean',
        title: '메모리 정리',
        icon: '💾',
        currentStatus: '현재: 450MB / 4GB 사용',
        lastExecuted: '2시간 전',
        effect: '+15분',
      ),
      IndividualExecutionItem(
        id: 'services_stop',
        title: '불필요한 서비스 중지',
        icon: '⚙️',
        currentStatus: '현재: 8개 서비스 실행 중',
        lastExecuted: '45분 전',
        effect: '+18분',
      ),
      IndividualExecutionItem(
        id: 'brightness_auto',
        title: '화면 밝기 조절',
        icon: '☀️',
        currentStatus: '현재: 80% → 권장: 40%',
        lastExecuted: '실행 안 함',
        effect: '+20분',
      ),
    ];
  }
}

