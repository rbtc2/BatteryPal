import 'package:flutter/material.dart';

/// 공통 다이얼로그들을 위한 기본 클래스
/// Phase 4에서 실제 구현 예정

/// Pro 업그레이드 다이얼로그
class ProUpgradeDialog extends StatelessWidget {
  final VoidCallback onUpgrade;
  
  const ProUpgradeDialog({
    super.key,
    required this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pro 업그레이드'),
      content: const Text('Pro 모드로 업그레이드하시겠습니까?\n\n• 무제한 배터리 부스트\n• 고급 분석 기능\n• 자동 최적화\n• 우선 지원'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            onUpgrade();
          },
          child: const Text('업그레이드'),
        ),
      ],
    );
  }
}

/// 최적화 다이얼로그
class OptimizationDialog extends StatelessWidget {
  const OptimizationDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('배터리 최적화'),
      content: const Text('Phase 5에서 실제 최적화 기능이 구현됩니다.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('확인'),
        ),
      ],
    );
  }
}
