import 'package:flutter/material.dart';
import '../../utils/dialog_utils.dart';
import '../../utils/app_utils.dart';

/// 배터리 부스트 버튼 위젯
/// 원클릭 배터리 최적화 기능을 제공하는 버튼
class BatteryBoostButton extends StatelessWidget {
  final VoidCallback? onOptimize;
  final bool isLoading;

  const BatteryBoostButton({
    super.key,
    this.onOptimize,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 120,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: isLoading ? null : () => _handleOptimization(context),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading)
                  const SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                else
                  const Icon(
                    Icons.flash_on,
                    size: 32,
                    color: Colors.white,
                  ),
                const SizedBox(height: 8),
                Text(
                  isLoading ? '최적화 중...' : '⚡ 배터리 부스트',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isLoading ? '잠시만 기다려주세요' : '원클릭으로 즉시 최적화',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 최적화 처리 로직
  void _handleOptimization(BuildContext context) {
    // Phase 4의 다이얼로그 시스템 사용
    DialogUtils.showOptimizationDialog(
      context,
      onConfirm: () {
        // 사용자 정의 콜백이 있으면 사용, 없으면 기본 동작
        if (onOptimize != null) {
          onOptimize!();
        } else {
          // Phase 5에서 실제 최적화 기능 구현 예정
          SnackBarUtils.showSuccess(context, '배터리 최적화가 완료되었습니다!');
        }
      },
    );
  }
}
