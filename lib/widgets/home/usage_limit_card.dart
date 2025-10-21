import 'package:flutter/material.dart';
import '../common/common_widgets.dart';
import '../../utils/dialog_utils.dart';

/// 사용 제한 카드 위젯
/// 무료 사용자의 사용 제한을 표시하고 Pro 업그레이드를 유도하는 카드
class UsageLimitCard extends StatelessWidget {
  final int dailyUsage;
  final int dailyLimit;
  final VoidCallback? onUpgrade;

  const UsageLimitCard({
    super.key,
    required this.dailyUsage,
    required this.dailyLimit,
    this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      elevation: 2,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline,
            color: Colors.orange,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '무료 버전 사용 제한',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '오늘 $dailyUsage/$dailyLimit회 사용',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _handleUpgrade(context),
            child: const Text('Pro로 업그레이드'),
          ),
        ],
      ),
    );
  }

  /// 업그레이드 처리 로직
  void _handleUpgrade(BuildContext context) {
    // 사용자 정의 콜백이 있으면 사용, 없으면 기본 동작
    if (onUpgrade != null) {
      onUpgrade!();
    } else {
      // Phase 4의 다이얼로그 시스템 사용
      DialogUtils.showProUpgradeSuccessDialog(
        context,
        onUpgrade: () {
          // 기본 업그레이드 동작 (실제로는 상위에서 처리)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pro 업그레이드 기능이 곧 출시됩니다!'),
              duration: Duration(seconds: 2),
            ),
          );
        },
      );
    }
  }
}
